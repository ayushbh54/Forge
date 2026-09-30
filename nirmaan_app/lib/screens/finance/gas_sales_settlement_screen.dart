import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// DOMAIN MODELS & ENUMS
// ============================================================================

enum ConsumerId {
  bvfclNamrup,
  bcplLepetkata,
  apgclLakwa,
  cgdNetworks,
}

enum ImbalanceBand {
  withinTolerance, // ±5.0%
  overdrawalTier1, // +5.0% to +10.0%
  overdrawalTier2, // > +10.0% Unauthorized Overrun
  underdrawalTier1, // -5.0% to -10.0%
  underdrawalTier2, // < -10.0% Severe Underdrawal
}

enum TopStatus {
  compliantSurplus,
  atRisk,
  deficitPenalty,
}

/// Model representing a Gas Sales Agreement (GSA) & Custody Delivery Contract
class GasConsumerContract {
  final ConsumerId id;
  final String shortCode;
  final String name;
  final String fullName;
  final String sector;
  final String contractRef;
  final String deliveryPoint;
  final String pipelineZone;
  final double dcqMmscmd; // Daily Contracted Quantity (MMSCMD)
  final double gcvKcalScm; // Gross Calorific Value (Kcal/SCM)
  final double zFactor; // AGA-8 Compressibility factor
  final double baseGasPriceUsdMmbtu; // Administered or formula price $/MMBTU
  final double exchangeRateInrPerUsd; // e.g. 86.50 INR/$
  final double transmissionTariffInrMmbtu; // PNGRB transmission tariff ₹/MMBTU
  final double mtoPercentage; // Minimum Take Obligation % (nominal 90.0%)
  final int contractYearDays; // 365
  final int approvedMaintenanceDays; // Allowed turnaround days
  final int forceMajeureDays; // Force majeure relief days
  final int ytdDaysElapsed; // Elapsed contractual days (e.g. 310)

  // Dynamic values that can be modified or simulated
  double ytdActualOfftakeMmscmd; // Cumulative offtake up to today
  double nominatedMmscmd; // Consumer nomination D-1
  double scheduledMmscmd; // Transporter scheduled confirmation
  double actualOfftakeMmscmd; // Custody metered offtake for Gas Day
  double pastYearMakeUpGasCreditsMmbtu; // Available MUG from prior contract year

  List<double> hourlyOfftakeMmscmd; // 24-hr hourly custody offtake

  GasConsumerContract({
    required this.id,
    required this.shortCode,
    required this.name,
    required this.fullName,
    required this.sector,
    required this.contractRef,
    required this.deliveryPoint,
    required this.pipelineZone,
    required this.dcqMmscmd,
    required this.gcvKcalScm,
    required this.zFactor,
    required this.baseGasPriceUsdMmbtu,
    this.exchangeRateInrPerUsd = 86.50,
    required this.transmissionTariffInrMmbtu,
    this.mtoPercentage = 90.0,
    this.contractYearDays = 365,
    this.approvedMaintenanceDays = 15,
    this.forceMajeureDays = 0,
    this.ytdDaysElapsed = 310,
    required this.ytdActualOfftakeMmscmd,
    required this.nominatedMmscmd,
    required this.scheduledMmscmd,
    required this.actualOfftakeMmscmd,
    required this.pastYearMakeUpGasCreditsMmbtu,
    required this.hourlyOfftakeMmscmd,
  });

  /// Energy Conversion Factor: MMBTU per MMSCMD = 1,000,000 * GCV / 252,000
  double get mmbtuPerMmscmd => 1000000.0 * (gcvKcalScm / 252000.0);

  // Daily Quantities in MMBTU
  double get dcqMmbtu => dcqMmscmd * mmbtuPerMmscmd;
  double get nominatedMmbtu => nominatedMmscmd * mmbtuPerMmscmd;
  double get scheduledMmbtu => scheduledMmscmd * mmbtuPerMmscmd;
  double get actualOfftakeMmbtu => actualOfftakeMmscmd * mmbtuPerMmscmd;

  // Imbalance Quantities
  double get imbalanceMmscmd => actualOfftakeMmscmd - scheduledMmscmd;
  double get imbalanceMmbtu => imbalanceMmscmd * mmbtuPerMmscmd;
  double get imbalancePct => scheduledMmscmd > 0.0
      ? ((actualOfftakeMmscmd - scheduledMmscmd) / scheduledMmscmd) * 100.0
      : 0.0;

  ImbalanceBand get imbalanceBand {
    final pct = imbalancePct;
    if (pct >= -5.0 && pct <= 5.0) {
      return ImbalanceBand.withinTolerance;
    } else if (pct > 5.0 && pct <= 10.0) {
      return ImbalanceBand.overdrawalTier1;
    } else if (pct > 10.0) {
      return ImbalanceBand.overdrawalTier2;
    } else if (pct < -5.0 && pct >= -10.0) {
      return ImbalanceBand.underdrawalTier1;
    } else {
      return ImbalanceBand.underdrawalTier2;
    }
  }

  // Take-or-Pay (ToP) Obligations
  double get acqMmscmd => dcqMmscmd * contractYearDays;
  double get acqMmbtu => acqMmscmd * mmbtuPerMmscmd;

  int get effectiveContractDays {
    final eff = contractYearDays - approvedMaintenanceDays - forceMajeureDays;
    return eff.clamp(1, contractYearDays);
  }

  double get adjustedMtoMmscmd =>
      dcqMmscmd * effectiveContractDays * (mtoPercentage / 100.0);
  double get adjustedMtoMmbtu => adjustedMtoMmscmd * mmbtuPerMmscmd;

  double get proratedMtoToDateMmscmd =>
      adjustedMtoMmscmd * (ytdDaysElapsed / contractYearDays);
  double get proratedMtoToDateMmbtu =>
      proratedMtoToDateMmscmd * mmbtuPerMmscmd;

  double get projectedAnnualOfftakeMmscmd => ytdDaysElapsed > 0
      ? (ytdActualOfftakeMmscmd / ytdDaysElapsed) * contractYearDays
      : 0.0;
  double get projectedAnnualOfftakeMmbtu =>
      projectedAnnualOfftakeMmscmd * mmbtuPerMmscmd;

  double get topDeficitMmscmd =>
      math.max(0.0, adjustedMtoMmscmd - projectedAnnualOfftakeMmscmd);
  double get topDeficitMmbtu => topDeficitMmscmd * mmbtuPerMmscmd;

  double get gasPriceInrMmbtu => baseGasPriceUsdMmbtu * exchangeRateInrPerUsd;

  double get topFinancialLiabilityInr => topDeficitMmbtu * gasPriceInrMmbtu;
  double get topFinancialLiabilityCrores =>
      topFinancialLiabilityInr / 10000000.0;

  TopStatus get topStatus {
    if (topDeficitMmscmd > 0.01) {
      return TopStatus.deficitPenalty;
    } else if (projectedAnnualOfftakeMmscmd < adjustedMtoMmscmd * 1.03) {
      return TopStatus.atRisk;
    } else {
      return TopStatus.compliantSurplus;
    }
  }

  // Transmission Tariff Calculations (Two-Part Tariff per PNGRB)
  double get transmissionCapacityChargeInr =>
      scheduledMmbtu * transmissionTariffInrMmbtu * 0.80; // 80% Capacity Reservation
  double get transmissionCommodityChargeInr =>
      actualOfftakeMmbtu * transmissionTariffInrMmbtu * 0.20; // 20% Commodity Offtake
  double get totalTransmissionTariffInr =>
      transmissionCapacityChargeInr + transmissionCommodityChargeInr;

  // Imbalance Settlement & Penalty Mechanics
  double get imbalanceUnitPenaltyMultiplier {
    switch (imbalanceBand) {
      case ImbalanceBand.withinTolerance:
        return 1.00; // Normal rate
      case ImbalanceBand.overdrawalTier1:
        return 1.10; // 110% of base gas price
      case ImbalanceBand.overdrawalTier2:
        return 1.50; // 150% of base gas price
      case ImbalanceBand.underdrawalTier1:
        return 0.90; // Transporter buys back at 90% (10% penalty)
      case ImbalanceBand.underdrawalTier2:
        return 0.70; // Transporter buys back at 70% (30% penalty)
    }
  }

  double get systemOverrunFeeInr {
    if (imbalanceBand == ImbalanceBand.overdrawalTier2) {
      // PNGRB Unauthorized System Overrun Charge: ₹125/MMBTU on excess above 10%
      final excessMmbtu =
          (actualOfftakeMmscmd - (scheduledMmscmd * 1.10)) * mmbtuPerMmscmd;
      return math.max(0.0, excessMmbtu * 125.0);
    }
    return 0.0;
  }

  double get imbalanceAdjustmentInr {
    final diffMmbtu = imbalanceMmbtu;
    if (diffMmbtu >= 0) {
      // Consumer over-lifted gas: owes commodity price * multiplier + pipeline tariff + overrun fee
      return (diffMmbtu * gasPriceInrMmbtu * imbalanceUnitPenaltyMultiplier) +
          (diffMmbtu * transmissionTariffInrMmbtu) +
          systemOverrunFeeInr;
    } else {
      // Consumer under-lifted gas: credit adjustment from transporter at haircut rate
      return diffMmbtu * gasPriceInrMmbtu * imbalanceUnitPenaltyMultiplier;
    }
  }

  // Daily Commercial Settlement
  double get scheduledGasCommodityInr => scheduledMmbtu * gasPriceInrMmbtu;
  double get gstOnTransmissionInr => totalTransmissionTariffInr * 0.18; // 18% GST

  double get netDailySettlementInr =>
      scheduledGasCommodityInr +
      totalTransmissionTariffInr +
      imbalanceAdjustmentInr +
      gstOnTransmissionInr;

  double get netDailySettlementCrores => netDailySettlementInr / 10000000.0;

  GasConsumerContract copyWith({
    double? nominatedMmscmd,
    double? scheduledMmscmd,
    double? actualOfftakeMmscmd,
    double? ytdActualOfftakeMmscmd,
    int? approvedMaintenanceDays,
    double? baseGasPriceUsdMmbtu,
    double? transmissionTariffInrMmbtu,
  }) {
    return GasConsumerContract(
      id: id,
      shortCode: shortCode,
      name: name,
      fullName: fullName,
      sector: sector,
      contractRef: contractRef,
      deliveryPoint: deliveryPoint,
      pipelineZone: pipelineZone,
      dcqMmscmd: dcqMmscmd,
      gcvKcalScm: gcvKcalScm,
      zFactor: zFactor,
      baseGasPriceUsdMmbtu: baseGasPriceUsdMmbtu ?? this.baseGasPriceUsdMmbtu,
      exchangeRateInrPerUsd: exchangeRateInrPerUsd,
      transmissionTariffInrMmbtu:
          transmissionTariffInrMmbtu ?? this.transmissionTariffInrMmbtu,
      mtoPercentage: mtoPercentage,
      contractYearDays: contractYearDays,
      approvedMaintenanceDays:
          approvedMaintenanceDays ?? this.approvedMaintenanceDays,
      forceMajeureDays: forceMajeureDays,
      ytdDaysElapsed: ytdDaysElapsed,
      ytdActualOfftakeMmscmd:
          ytdActualOfftakeMmscmd ?? this.ytdActualOfftakeMmscmd,
      nominatedMmscmd: nominatedMmscmd ?? this.nominatedMmscmd,
      scheduledMmscmd: scheduledMmscmd ?? this.scheduledMmscmd,
      actualOfftakeMmscmd: actualOfftakeMmscmd ?? this.actualOfftakeMmscmd,
      pastYearMakeUpGasCreditsMmbtu: pastYearMakeUpGasCreditsMmbtu,
      hourlyOfftakeMmscmd: hourlyOfftakeMmscmd,
    );
  }
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class GasSalesSettlementScreen extends StatefulWidget {
  const GasSalesSettlementScreen({super.key});

  @override
  State<GasSalesSettlementScreen> createState() =>
      _GasSalesSettlementScreenState();
}

class _GasSalesSettlementScreenState extends State<GasSalesSettlementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ConsumerId? _selectedFilterConsumerId; // null = all consumers
  DateTime _selectedGasDay = DateTime(2026, 9, 30);
  final NumberFormat _currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');

  // Baseline Initialized Consumers per prompt requirements
  late List<GasConsumerContract> _contracts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeContracts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeContracts() {
    _contracts = [
      // 1. BVFCL Namrup Fertilizer (1.20 MMSCMD)
      GasConsumerContract(
        id: ConsumerId.bvfclNamrup,
        shortCode: 'BVFCL',
        name: 'BVFCL Namrup Fertilizer',
        fullName: 'Brahmaputra Valley Fertilizer Corporation Limited',
        sector: 'Priority Core Fertilizer (Urea Feedstock)',
        contractRef: 'GSA/OIL-BVFCL/2023/REV-4',
        deliveryPoint: 'Namrup Metering & Regulating Station (MRS-01)',
        pipelineZone: 'Zone 1 (48 km Duliajan-Namrup Grid)',
        dcqMmscmd: 1.20,
        gcvKcalScm: 9820.0,
        zFactor: 0.9972,
        baseGasPriceUsdMmbtu: 6.50, // Domestic APM Gas Price
        exchangeRateInrPerUsd: 86.50,
        transmissionTariffInrMmbtu: 34.50, // PNGRB Zone-1 Approved Tariff
        mtoPercentage: 90.0,
        contractYearDays: 365,
        approvedMaintenanceDays: 14,
        forceMajeureDays: 0,
        ytdDaysElapsed: 310,
        ytdActualOfftakeMmscmd: 364.50, // On track: Projected 429 > MTO 394
        nominatedMmscmd: 1.18,
        scheduledMmscmd: 1.18,
        actualOfftakeMmscmd: 1.15, // -2.54% variance (Within tolerance)
        pastYearMakeUpGasCreditsMmbtu: 42500.0,
        hourlyOfftakeMmscmd: const [
          0.048, 0.048, 0.047, 0.048, 0.048, 0.049,
          0.048, 0.047, 0.048, 0.048, 0.047, 0.048,
          0.048, 0.048, 0.047, 0.048, 0.048, 0.048,
          0.048, 0.047, 0.048, 0.048, 0.048, 0.047,
        ],
      ),

      // 2. BCPL Lepetkata Petrochemicals (1.00 MMSCMD)
      GasConsumerContract(
        id: ConsumerId.bcplLepetkata,
        shortCode: 'BCPL',
        name: 'BCPL Lepetkata Petrochemicals',
        fullName: 'Brahmaputra Cracker and Polymer Limited',
        sector: 'Petrochemical Dual-Feed Cracker & Polymer Plant',
        contractRef: 'GSA/OIL-BCPL/2021/LT-02',
        deliveryPoint: 'Lepetkata Custody Transfer Terminal (CTF-BCPL)',
        pipelineZone: 'Zone 1 (62 km Duliajan-Lepetkata Trunk)',
        dcqMmscmd: 1.00,
        gcvKcalScm: 9850.0,
        zFactor: 0.9968,
        baseGasPriceUsdMmbtu: 7.25, // Non-APM Formula Index
        exchangeRateInrPerUsd: 86.50,
        transmissionTariffInrMmbtu: 34.50,
        mtoPercentage: 90.0,
        contractYearDays: 365,
        approvedMaintenanceDays: 15,
        forceMajeureDays: 0,
        ytdDaysElapsed: 310,
        ytdActualOfftakeMmscmd: 338.40, // Compliant
        nominatedMmscmd: 1.05,
        scheduledMmscmd: 1.00,
        actualOfftakeMmscmd: 1.09, // +9.00% (Tier 1 Overdrawal penalty band)
        pastYearMakeUpGasCreditsMmbtu: 18200.0,
        hourlyOfftakeMmscmd: const [
          0.044, 0.044, 0.045, 0.045, 0.046, 0.046,
          0.046, 0.047, 0.046, 0.046, 0.045, 0.045,
          0.045, 0.046, 0.046, 0.046, 0.045, 0.045,
          0.045, 0.045, 0.046, 0.045, 0.045, 0.044,
        ],
      ),

      // 3. APGCL Lakwa Power Plant (0.80 MMSCMD)
      GasConsumerContract(
        id: ConsumerId.apgclLakwa,
        shortCode: 'APGCL',
        name: 'APGCL Lakwa Power Plant',
        fullName: 'Assam Power Generation Corporation Limited',
        sector: 'Base-Load Combined Cycle Power Generation (120 MW)',
        contractRef: 'GSA/OIL-APGCL/2022/PWR-09',
        deliveryPoint: 'Lakwa Gas Receiving Station (GRS-APGCL)',
        pipelineZone: 'Zone 1 (84 km Moran-Lakwa Feeder)',
        dcqMmscmd: 0.80,
        gcvKcalScm: 9780.0,
        zFactor: 0.9975,
        baseGasPriceUsdMmbtu: 6.50, // APM Gas
        exchangeRateInrPerUsd: 86.50,
        transmissionTariffInrMmbtu: 34.50,
        mtoPercentage: 90.0,
        contractYearDays: 365,
        approvedMaintenanceDays: 20, // Extended gas turbine overhaul
        forceMajeureDays: 0,
        ytdDaysElapsed: 310,
        ytdActualOfftakeMmscmd: 208.50, // Shortfall! Projected 245.5 vs MTO 248.4 -> ToP Deficit!
        nominatedMmscmd: 0.70,
        scheduledMmscmd: 0.70,
        actualOfftakeMmscmd: 0.61, // -12.86% (Tier 2 Severe Underdrawal penalty)
        pastYearMakeUpGasCreditsMmbtu: 64000.0,
        hourlyOfftakeMmscmd: const [
          0.026, 0.026, 0.025, 0.025, 0.025, 0.026,
          0.026, 0.025, 0.025, 0.025, 0.025, 0.026,
          0.025, 0.025, 0.026, 0.025, 0.025, 0.025,
          0.025, 0.026, 0.025, 0.025, 0.025, 0.025,
        ],
      ),

      // 4. City Gas Networks (0.45 MMSCMD)
      GasConsumerContract(
        id: ConsumerId.cgdNetworks,
        shortCode: 'CGD-PBGL',
        name: 'City Gas Networks',
        fullName: 'Purba Bharati Gas Limited (AGCL / OIL / GAIL JV)',
        sector: 'City Gas Distribution (Priority CNG Transport & PNG Domestic)',
        contractRef: 'GSA/OIL-PBGL-CGD/2024/URB-12',
        deliveryPoint: 'Duliajan CGD Mother Station City Gate (CGS-01)',
        pipelineZone: 'Zone 1 (22 km Local Distribution Ring)',
        dcqMmscmd: 0.45,
        gcvKcalScm: 9810.0,
        zFactor: 0.9970,
        baseGasPriceUsdMmbtu: 6.50, // 100% Domestic APM Allocation
        exchangeRateInrPerUsd: 86.50,
        transmissionTariffInrMmbtu: 34.50,
        mtoPercentage: 90.0,
        contractYearDays: 365,
        approvedMaintenanceDays: 10,
        forceMajeureDays: 0,
        ytdDaysElapsed: 310,
        ytdActualOfftakeMmscmd: 154.20, // Healthy: Projected 181.5 > MTO 143.8
        nominatedMmscmd: 0.44,
        scheduledMmscmd: 0.44,
        actualOfftakeMmscmd: 0.45, // +2.27% (Within tolerance)
        pastYearMakeUpGasCreditsMmbtu: 9500.0,
        hourlyOfftakeMmscmd: const [
          0.017, 0.017, 0.016, 0.016, 0.018, 0.020,
          0.021, 0.021, 0.020, 0.019, 0.019, 0.019,
          0.019, 0.019, 0.020, 0.020, 0.021, 0.022,
          0.021, 0.020, 0.019, 0.018, 0.018, 0.017,
        ],
      ),
    ];
  }

  // Aggregated System Properties
  List<GasConsumerContract> get _filteredContracts {
    if (_selectedFilterConsumerId == null) {
      return _contracts;
    }
    return _contracts
        .where((c) => c.id == _selectedFilterConsumerId)
        .toList();
  }

  double get _totalDcqMmscmd =>
      _contracts.fold(0.0, (acc, c) => acc + c.dcqMmscmd);
  double get _totalNominatedMmscmd =>
      _contracts.fold(0.0, (acc, c) => acc + c.nominatedMmscmd);
  double get _totalScheduledMmscmd =>
      _contracts.fold(0.0, (acc, c) => acc + c.scheduledMmscmd);
  double get _totalActualOfftakeMmscmd =>
      _contracts.fold(0.0, (acc, c) => acc + c.actualOfftakeMmscmd);
  double get _totalActualOfftakeMmbtu =>
      _contracts.fold(0.0, (acc, c) => acc + c.actualOfftakeMmbtu);
  double get _systemImbalanceMmscmd =>
      _totalActualOfftakeMmscmd - _totalScheduledMmscmd;
  double get _systemImbalancePct => _totalScheduledMmscmd > 0
      ? (_systemImbalanceMmscmd / _totalScheduledMmscmd) * 100.0
      : 0.0;

  double get _totalTopDeficitCrores =>
      _contracts.fold(0.0, (acc, c) => acc + c.topFinancialLiabilityCrores);
  double get _totalDailySettlementCrores =>
      _contracts.fold(0.0, (acc, c) => acc + c.netDailySettlementCrores);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterAndDateBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCommercialSummaryTab(),
                _buildDailyAllocationTab(),
                _buildTakeOrPayEngineTab(),
                _buildTariffAndImbalanceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Gas Sales Agreement & Settlement',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'PNGRB Pipeline Tariff Regulations & Custody Allocation',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: AppTheme.primaryLight),
          tooltip: 'Simulate Offtake & Imbalance',
          onPressed: _showOfftakeSimulationModal,
        ),
        IconButton(
          icon: const Icon(Icons.receipt_long_rounded, color: AppTheme.secondary),
          tooltip: 'Custody Settlement Voucher',
          onPressed: _showCustodySettlementInvoiceModal,
        ),
        IconButton(
          icon: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
          tooltip: 'PNGRB Regulations Dossier',
          onPressed: _showPngrbRegulationsModal,
        ),
      ],
    );
  }

  Widget _buildFilterAndDateBar() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Column(
        children: [
          // Gas Day & Regulatory Badge Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.primary.withAlpha(120)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.gavel_rounded, color: AppTheme.primaryLight, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'PNGRB TARIFF ORDER 2024',
                      style: TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, color: AppTheme.textMuted, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'GAS DAY: ${DateFormat('dd MMM yyyy').format(_selectedGasDay)} (06:00-06:00)',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _pickGasDay,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: const [
                      Icon(Icons.calendar_today_rounded, color: AppTheme.secondary, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Change Day',
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Offtaker Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildConsumerChip(null, 'All Consumers (4)'),
                const SizedBox(width: 6),
                _buildConsumerChip(ConsumerId.bvfclNamrup, 'BVFCL Namrup (1.2M)'),
                const SizedBox(width: 6),
                _buildConsumerChip(ConsumerId.bcplLepetkata, 'BCPL Lepetkata (1.0M)'),
                const SizedBox(width: 6),
                _buildConsumerChip(ConsumerId.apgclLakwa, 'APGCL Lakwa (0.8M)'),
                const SizedBox(width: 6),
                _buildConsumerChip(ConsumerId.cgdNetworks, 'City Gas PBGL (0.45M)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumerChip(ConsumerId? id, String label) {
    final isSelected = _selectedFilterConsumerId == id;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilterConsumerId = id;
        });
      },
      backgroundColor: AppTheme.surfaceCard,
      selectedColor: AppTheme.primary.withAlpha(60),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryLight : AppTheme.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 2.5,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        tabs: const [
          Tab(text: 'Commercial Summary'),
          Tab(text: 'Daily Allocation (DCQ)'),
          Tab(text: 'Take-or-Pay (ToP)'),
          Tab(text: 'Tariff & Imbalance'),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: COMMERCIAL SUMMARY
  // ============================================================================

  Widget _buildCommercialSummaryTab() {
    final filtered = _filteredContracts;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 4 KPI Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricKpiCard(
                title: 'TOTAL DAILY OFFTAKE',
                value: '${_totalActualOfftakeMmscmd.toStringAsFixed(2)} MMSCMD',
                subtitle: '${_currencyFormat.format(_totalActualOfftakeMmbtu)} MMBTU',
                badgeText: '${((_totalActualOfftakeMmscmd / _totalDcqMmscmd) * 100).toStringAsFixed(1)}% DCQ',
                badgeColor: AppTheme.primary,
                icon: Icons.local_gas_station_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricKpiCard(
                title: 'TOTAL SCHEDULED',
                value: '${_totalScheduledMmscmd.toStringAsFixed(2)} MMSCMD',
                subtitle: 'Nom: ${_totalNominatedMmscmd.toStringAsFixed(2)} | Cap: ${_totalDcqMmscmd.toStringAsFixed(2)} M',
                badgeText: '96.2% Allocated',
                badgeColor: AppTheme.tertiary,
                icon: Icons.event_available_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricKpiCard(
                title: 'SYSTEM IMBALANCE',
                value: '${_systemImbalanceMmscmd >= 0 ? '+' : ''}${_systemImbalanceMmscmd.toStringAsFixed(3)} MMSCMD',
                subtitle: '${_systemImbalancePct >= 0 ? '+' : ''}${_systemImbalancePct.toStringAsFixed(2)}% vs Scheduled',
                badgeText: _systemImbalancePct.abs() <= 5.0 ? 'SAFE PACK' : 'PENAL CORRIDOR',
                badgeColor: _systemImbalancePct.abs() <= 5.0 ? AppTheme.tertiary : AppTheme.secondary,
                icon: Icons.compare_arrows_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricKpiCard(
                title: 'TOP LIABILITY EXPOSURE',
                value: '₹ ${_totalTopDeficitCrores.toStringAsFixed(2)} Cr',
                subtitle: 'Lakwa Power deficit risk',
                badgeText: _totalTopDeficitCrores > 0 ? 'DEFICIT ALERT' : 'COMPLIANT',
                badgeColor: _totalTopDeficitCrores > 0 ? const Color(0xFFEF4444) : AppTheme.tertiary,
                icon: Icons.warning_amber_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Pipeline Operational Status Banner
        _buildPipelineLinepackBanner(),
        const SizedBox(height: 16),

        // Section Title: Offtaker Allocation Summary
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'GSA CONSUMER PERFORMANCE MATRIX',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${filtered.length} of 4 Registered Offtakers',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Cards for each consumer
        ...filtered.map(_buildConsumerSummaryCard),

        const SizedBox(height: 16),

        // System Gas Balance Chart
        _buildSystemBalanceChartCard(),
      ],
    );
  }

  Widget _buildMetricKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.textMuted, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineLinepackBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(35),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.speed_rounded,
              color: AppTheme.primaryLight,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'OIL DULIAJAN 18" TRUNK LINEPACK: 4.82 MMSCM',
                      style: TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiary.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NORMAL PACK (64.2 BAR)',
                        style: TextStyle(
                          color: AppTheme.tertiary,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Transporter pressure gradient: Inlet 68.4 barg at Duliajan CGGS → Terminal 44.8 barg at Lakwa GRS. No emergency flaring triggered.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumerSummaryCard(GasConsumerContract contract) {
    Color statusColor;
    String statusTitle;
    switch (contract.imbalanceBand) {
      case ImbalanceBand.withinTolerance:
        statusColor = AppTheme.tertiary;
        statusTitle = 'BALANCED (±5%)';
        break;
      case ImbalanceBand.overdrawalTier1:
        statusColor = AppTheme.secondary;
        statusTitle = 'TIER-1 OVERDRAWAL (+9.0%)';
        break;
      case ImbalanceBand.overdrawalTier2:
        statusColor = const Color(0xFFEF4444);
        statusTitle = 'TIER-2 UNAUTHORIZED OVERRUN';
        break;
      case ImbalanceBand.underdrawalTier1:
        statusColor = AppTheme.secondary;
        statusTitle = 'TIER-1 UNDERDRAWAL';
        break;
      case ImbalanceBand.underdrawalTier2:
        statusColor = const Color(0xFFEF4444);
        statusTitle = 'TIER-2 UNDERDRAWAL (-12.9%)';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh.withAlpha(80),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contract.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${contract.sector} • ${contract.contractRef}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 9.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withAlpha(100)),
                  ),
                  child: Text(
                    statusTitle,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Metrics Grid
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSubMetric(
                      label: 'DCQ (CONTRACTED)',
                      value: '${contract.dcqMmscmd.toStringAsFixed(2)} MMSCMD',
                      subvalue: '${contract.dcqMmbtu.toStringAsFixed(0)} MMBTU',
                    ),
                    _buildSubMetric(
                      label: 'SCHEDULED',
                      value: '${contract.scheduledMmscmd.toStringAsFixed(2)} MMSCMD',
                      subvalue: 'Nom: ${contract.nominatedMmscmd.toStringAsFixed(2)} MMSCMD',
                    ),
                    _buildSubMetric(
                      label: 'ACTUAL OFFTAKE',
                      value: '${contract.actualOfftakeMmscmd.toStringAsFixed(2)} MMSCMD',
                      subvalue: '${contract.imbalancePct >= 0 ? '+' : ''}${contract.imbalancePct.toStringAsFixed(1)}% Var',
                      highlightColor: statusColor,
                    ),
                    _buildSubMetric(
                      label: 'DAILY SETTLED',
                      value: '₹ ${contract.netDailySettlementCrores.toStringAsFixed(2)} Cr',
                      subvalue: 'Tariff: ₹${contract.transmissionTariffInrMmbtu.toStringAsFixed(1)}/U',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: AppTheme.border, height: 1),
                const SizedBox(height: 10),
                // Footer Line with Delivery Terminal and ToP Status
                Row(
                  children: [
                    const Icon(Icons.place_rounded, color: AppTheme.textMuted, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        contract.deliveryPoint,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      contract.topStatus == TopStatus.deficitPenalty
                          ? 'TOP DEFICIT: ₹${contract.topFinancialLiabilityCrores.toStringAsFixed(2)} Cr'
                          : 'MTO 90% COMPLIANT',
                      style: TextStyle(
                        color: contract.topStatus == TopStatus.deficitPenalty
                            ? const Color(0xFFEF4444)
                            : AppTheme.tertiary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetric({
    required String label,
    required String value,
    required String subvalue,
    Color? highlightColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: highlightColor ?? AppTheme.textPrimary,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          subvalue,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildSystemBalanceChartCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppTheme.primaryLight, size: 16),
              const SizedBox(width: 8),
              const Text(
                'OFFTAKE VS DCQ ALLOCATION COMPARISON',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              _buildLegendDot(AppTheme.primaryLight, 'Actual Offtake'),
              const SizedBox(width: 8),
              _buildLegendDot(AppTheme.textMuted, 'DCQ Target'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1.5,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _contracts.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _contracts[index].shortCode,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 8.5,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.border.withAlpha(80),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _contracts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final c = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: c.actualOfftakeMmscmd,
                        color: AppTheme.primaryLight,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                      BarChartRodData(
                        toY: c.dcqMmscmd,
                        color: AppTheme.textMuted.withAlpha(120),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 2: DAILY ALLOCATION (DCQ & METERED OFFTAKE)
  // ============================================================================

  Widget _buildDailyAllocationTab() {
    final filtered = _filteredContracts;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Allocation Protocol Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: const [
              Icon(Icons.rule_rounded, color: AppTheme.secondary, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'PNGRB Allocation Norms: Daily nomination cutoff 10:00 hrs (D-1), schedule confirmation 14:00 hrs. Offtake custody verified by Emerson S600+ flow computers & Daniel 4-Path UFM.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Allocation Cards
        ...filtered.map(_buildAllocationDetailCard),
      ],
    );
  }

  Widget _buildAllocationDetailCard(GasConsumerContract contract) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh.withAlpha(90),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.factory_rounded, color: AppTheme.primaryLight, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contract.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Delivery: ${contract.deliveryPoint}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showEditContractOfftakeModal(contract),
                  icon: const Icon(Icons.edit_rounded, size: 12),
                  label: const Text('Simulate Offtake'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary.withAlpha(50),
                    foregroundColor: AppTheme.primaryLight,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Detailed 4-Way Quantities Matrix
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border.withAlpha(120)),
                  ),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.6),
                      1: FlexColumnWidth(1.2),
                      2: FlexColumnWidth(1.4),
                      3: FlexColumnWidth(1.2),
                    },
                    children: [
                      // Header Row
                      TableRow(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.8)),
                        ),
                        children: [
                          _buildTableCell('ALLOCATION STAGE', isHeader: true),
                          _buildTableCell('MMSCMD', isHeader: true, alignRight: true),
                          _buildTableCell('MMBTU / DAY', isHeader: true, alignRight: true),
                          _buildTableCell('ENERGY GCV', isHeader: true, alignRight: true),
                        ],
                      ),
                      // DCQ
                      TableRow(
                        children: [
                          _buildTableCell('Daily Contracted (DCQ)'),
                          _buildTableCell(contract.dcqMmscmd.toStringAsFixed(2), alignRight: true),
                          _buildTableCell(_currencyFormat.format(contract.dcqMmbtu), alignRight: true),
                          _buildTableCell('${contract.gcvKcalScm.toInt()} kcal', alignRight: true),
                        ],
                      ),
                      // Nominated
                      TableRow(
                        children: [
                          _buildTableCell('Nominated by Buyer (D-1)'),
                          _buildTableCell(contract.nominatedMmscmd.toStringAsFixed(2), alignRight: true),
                          _buildTableCell(_currencyFormat.format(contract.nominatedMmbtu), alignRight: true),
                          _buildTableCell('Z = ${contract.zFactor.toStringAsFixed(4)}', alignRight: true),
                        ],
                      ),
                      // Scheduled
                      TableRow(
                        children: [
                          _buildTableCell('Scheduled by Transporter'),
                          _buildTableCell(contract.scheduledMmscmd.toStringAsFixed(2), alignRight: true),
                          _buildTableCell(_currencyFormat.format(contract.scheduledMmbtu), alignRight: true),
                          _buildTableCell('Confirmed', alignRight: true),
                        ],
                      ),
                      // Actual Metered
                      TableRow(
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(15),
                        ),
                        children: [
                          _buildTableCell('Actual Metered Offtake', isBold: true),
                          _buildTableCell(contract.actualOfftakeMmscmd.toStringAsFixed(2), isBold: true, alignRight: true),
                          _buildTableCell(_currencyFormat.format(contract.actualOfftakeMmbtu), isBold: true, alignRight: true),
                          _buildTableCell('Fiscal Skid', isBold: true, alignRight: true),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Offtake Variance & Imbalance Bar
                Row(
                  children: [
                    Text(
                      'Net Allocation Variance: ${contract.imbalanceMmscmd >= 0 ? '+' : ''}${contract.imbalanceMmscmd.toStringAsFixed(3)} MMSCMD (${contract.imbalancePct >= 0 ? '+' : ''}${contract.imbalancePct.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        color: contract.imbalanceBand == ImbalanceBand.withinTolerance
                            ? AppTheme.tertiary
                            : contract.imbalanceBand == ImbalanceBand.overdrawalTier1 ||
                                    contract.imbalanceBand == ImbalanceBand.underdrawalTier1
                                ? AppTheme.secondary
                                : const Color(0xFFEF4444),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Tolerance: ±5.0%',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (contract.actualOfftakeMmscmd / (contract.dcqMmscmd * 1.2)).clamp(0.0, 1.0),
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    contract.imbalanceBand == ImbalanceBand.withinTolerance
                        ? AppTheme.tertiary
                        : contract.imbalanceBand == ImbalanceBand.overdrawalTier1 ||
                                contract.imbalanceBand == ImbalanceBand.underdrawalTier1
                            ? AppTheme.secondary
                            : const Color(0xFFEF4444),
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 12),

                // Hourly Flow Profile Sparkline
                const Text(
                  '24-HOUR CUSTODY OFFTAKE PROFILE (HOURLY INTEGRATION)',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minY: 0.0,
                      lineBarsData: [
                        LineChartBarData(
                          spots: contract.hourlyOfftakeMmscmd
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                              .toList(),
                          isCurved: true,
                          color: AppTheme.primaryLight,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.primaryLight.withAlpha(35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    bool alignRight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          color: isHeader
              ? AppTheme.textMuted
              : isBold
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
          fontSize: isHeader ? 8.5 : 10.5,
          fontWeight: isHeader || isBold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 3: TAKE-OR-PAY (ToP) ENGINE
  // ============================================================================

  Widget _buildTakeOrPayEngineTab() {
    final filtered = _filteredContracts;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ToP Regulatory Concept Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: AppTheme.secondary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'TAKE-OR-PAY (ToP) CONTRACTUAL ENGINE — GSA CLAUSE 11',
                      style: TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Per standard PNGRB / Indian GSA contracts, buyers are obligated to lift a Minimum Take Obligation (MTO = 90.0% of ACQ, adjusted for approved turnaround & Force Majeure). If actual offtake falls short of MTO at contract year-end, buyer pays for the deficit gas. Buyer retains Make-up Gas (MUG) lifting rights for up to 24 months.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Cumulative ToP Summary Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _totalTopDeficitCrores > 0
                ? const Color(0xFFEF4444).withAlpha(20)
                : AppTheme.tertiary.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _totalTopDeficitCrores > 0
                  ? const Color(0xFFEF4444).withAlpha(120)
                  : AppTheme.tertiary.withAlpha(120),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _totalTopDeficitCrores > 0
                    ? Icons.warning_rounded
                    : Icons.check_circle_rounded,
                color: _totalTopDeficitCrores > 0
                    ? const Color(0xFFEF4444)
                    : AppTheme.tertiary,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _totalTopDeficitCrores > 0
                          ? 'POTENTIAL TOP FINANCIAL LIABILITY: ₹ ${_totalTopDeficitCrores.toStringAsFixed(2)} CRORES'
                          : 'ALL CONTRACTS IN TOP COMPLIANCE (ZERO LIABILITY)',
                      style: TextStyle(
                        color: _totalTopDeficitCrores > 0
                            ? const Color(0xFFEF4444)
                            : AppTheme.tertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _totalTopDeficitCrores > 0
                          ? 'APGCL Lakwa Power Plant projected annual shortfall of 13.8 MMSCMD requires formal Cl. 11.2 Cure Notice or Dispatch Re-nomination.'
                          : 'Total projected annualized take exceeds MTO 90% across all 4 contracted consumer networks.',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Consumer ToP Cards
        ...filtered.map(_buildTakeOrPayConsumerCard),
      ],
    );
  }

  Widget _buildTakeOrPayConsumerCard(GasConsumerContract contract) {
    final progressFraction = contract.adjustedMtoMmscmd > 0
        ? (contract.projectedAnnualOfftakeMmscmd / contract.adjustedMtoMmscmd).clamp(0.0, 1.5)
        : 0.0;

    final isDeficit = contract.topStatus == TopStatus.deficitPenalty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDeficit ? const Color(0xFFEF4444).withAlpha(150) : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDeficit
                  ? const Color(0xFFEF4444).withAlpha(25)
                  : AppTheme.surfaceContainerHigh.withAlpha(80),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contract.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Base Gas Price: \$${contract.baseGasPriceUsdMmbtu.toStringAsFixed(2)}/MMBTU (₹${contract.gasPriceInrMmbtu.toStringAsFixed(1)}) • Exch: ₹${contract.exchangeRateInrPerUsd}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDeficit
                        ? const Color(0xFFEF4444).withAlpha(30)
                        : AppTheme.tertiary.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDeficit
                          ? const Color(0xFFEF4444).withAlpha(120)
                          : AppTheme.tertiary.withAlpha(120),
                    ),
                  ),
                  child: Text(
                    isDeficit ? 'TOP SHORTFALL' : 'TOP SECURE',
                    style: TextStyle(
                      color: isDeficit ? const Color(0xFFEF4444) : AppTheme.tertiary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 4 Financial / Contractual Parameters
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSubMetric(
                      label: 'ANNUAL CONTRACT (ACQ)',
                      value: '${contract.acqMmscmd.toStringAsFixed(1)} MMSCM',
                      subvalue: '${(contract.acqMmbtu / 1000000).toStringAsFixed(2)} M-MMBTU',
                    ),
                    _buildSubMetric(
                      label: 'MTO THRESHOLD (90%)',
                      value: '${contract.adjustedMtoMmscmd.toStringAsFixed(1)} MMSCM',
                      subvalue: 'Adj for ${contract.approvedMaintenanceDays}d Maint',
                    ),
                    _buildSubMetric(
                      label: 'YTD DRAWN (DAY 310)',
                      value: '${contract.ytdActualOfftakeMmscmd.toStringAsFixed(1)} MMSCM',
                      subvalue: 'Target: ${contract.proratedMtoToDateMmscmd.toStringAsFixed(1)} MMSCM',
                    ),
                    _buildSubMetric(
                      label: 'PROJECTED ANNUAL',
                      value: '${contract.projectedAnnualOfftakeMmscmd.toStringAsFixed(1)} MMSCM',
                      subvalue: '${(progressFraction * 100).toStringAsFixed(1)}% of MTO',
                      highlightColor: isDeficit ? const Color(0xFFEF4444) : AppTheme.tertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Progress Bar vs MTO 90%
                Row(
                  children: [
                    Text(
                      'MTO Obligation Fulfillment: ${(progressFraction * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isDeficit ? const Color(0xFFEF4444) : AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'MTO Target: 100.0%',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progressFraction.clamp(0.0, 1.0),
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDeficit ? const Color(0xFFEF4444) : AppTheme.tertiary,
                  ),
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 14),

                // Take-or-Pay Financial Calculation Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Take-or-Pay Deficit Quantity:',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                          Text(
                            '${contract.topDeficitMmscmd.toStringAsFixed(2)} MMSCM (${_currencyFormat.format(contract.topDeficitMmbtu)} MMBTU)',
                            style: TextStyle(
                              color: isDeficit ? const Color(0xFFEF4444) : AppTheme.textPrimary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Applicable Base Gas Settlement Price:',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                          Text(
                            '₹ ${contract.gasPriceInrMmbtu.toStringAsFixed(2)} / MMBTU (\$${contract.baseGasPriceUsdMmbtu.toStringAsFixed(2)})',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Divider(color: AppTheme.border, height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estimated ToP Financial Liability:',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹ ${contract.topFinancialLiabilityCrores.toStringAsFixed(2)} CRORES',
                            style: TextStyle(
                              color: isDeficit ? const Color(0xFFEF4444) : AppTheme.tertiary,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Make-Up Gas (MUG) Credit Status
                Row(
                  children: [
                    const Icon(Icons.recycling_rounded, color: AppTheme.primaryLight, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Accrued Make-up Gas Credits: ${_currencyFormat.format(contract.pastYearMakeUpGasCreditsMmbtu)} MMBTU (Expires in 24 months per GSA Cl. 11.4)',
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 4: TRANSMISSION TARIFF & IMBALANCE SETTLEMENT
  // ============================================================================

  Widget _buildTariffAndImbalanceTab() {
    final filtered = _filteredContracts;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // PNGRB Transmission Tariff Regulations Overview
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryLight, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'PNGRB PIPELINE TARIFF & IMBALANCE CASH-OUT REGULATIONS',
                      style: TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Settlement governed by PNGRB (Determination of Natural Gas Pipeline Tariff) Regulations. Approved Zone-1 Tariff: ₹34.50/MMBTU, Zone-2: ₹58.20/MMBTU. Split into 80% Capacity Reservation & 20% Commodity Offtake Charge. Statutory 18% GST applicable on transmission services.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Penalty Matrix Card (5 Tiers)
        _buildPenaltyMatrixCard(),
        const SizedBox(height: 16),

        // Daily Financial Billing Ledger
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'DAILY COMMERCIAL CUSTODY RECONCILIATION',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Total: ₹ ${_totalDailySettlementCrores.toStringAsFixed(2)} Cr',
              style: const TextStyle(
                color: AppTheme.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Cards for each contract settlement
        ...filtered.map(_buildSettlementInvoiceCard),
      ],
    );
  }

  Widget _buildPenaltyMatrixCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PNGRB IMBALANCE SETTLEMENT BANDS & PENALTY MULTIPLIERS',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _buildBandRow(
            bandName: 'Band 0: Balanced Corridor (±5.0%)',
            actionDesc: 'Neutral Settlement at 100% Base Gas Price + 100% Transmission Tariff',
            statusColor: AppTheme.tertiary,
            rateTag: '1.00x Base (Zero Penalty)',
          ),
          const SizedBox(height: 6),
          _buildBandRow(
            bandName: 'Tier 1 Overdrawal (+5.0% to +10.0%)',
            actionDesc: 'Gas charged at 110% Base Price + 100% Transmission Tariff',
            statusColor: AppTheme.secondary,
            rateTag: '1.10x Base Gas Price',
          ),
          const SizedBox(height: 6),
          _buildBandRow(
            bandName: 'Tier 2 Unauthorized Overrun (> +10.0%)',
            actionDesc: 'Gas charged at 150% Base Price + ₹125/MMBTU System Overrun Fee',
            statusColor: const Color(0xFFEF4444),
            rateTag: '1.50x + ₹125/U Overrun',
          ),
          const SizedBox(height: 6),
          _buildBandRow(
            bandName: 'Tier 1 Underdrawal (-5.0% to -10.0%)',
            actionDesc: 'Transporter buyback haircut at 90% Base Price (10% forfeiture)',
            statusColor: AppTheme.secondary,
            rateTag: '0.90x Haircut Credit',
          ),
          const SizedBox(height: 6),
          _buildBandRow(
            bandName: 'Tier 2 Severe Underdrawal (< -10.0%)',
            actionDesc: 'Transporter buyback haircut at 70% Base Price (30% linepack penalty)',
            statusColor: const Color(0xFFEF4444),
            rateTag: '0.70x Haircut Credit',
          ),
        ],
      ),
    );
  }

  Widget _buildBandRow({
    required String bandName,
    required String actionDesc,
    required Color statusColor,
    required String rateTag,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bandName,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  actionDesc,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              rateTag,
              style: TextStyle(
                color: statusColor,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementInvoiceCard(GasConsumerContract contract) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh.withAlpha(80),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contract.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Delivery: ${contract.deliveryPoint} (${contract.pipelineZone})',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹ ${contract.netDailySettlementCrores.toStringAsFixed(2)} Cr',
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildInvoiceItemRow(
                  '1. Base Scheduled Commodity Value (${contract.scheduledMmbtu.toStringAsFixed(0)} MMBTU @ ₹${contract.gasPriceInrMmbtu.toStringAsFixed(1)})',
                  contract.scheduledGasCommodityInr,
                ),
                const SizedBox(height: 4),
                _buildInvoiceItemRow(
                  '2. Transmission Capacity Charge (80% on Scheduled @ ₹${contract.transmissionTariffInrMmbtu.toStringAsFixed(1)})',
                  contract.transmissionCapacityChargeInr,
                ),
                const SizedBox(height: 4),
                _buildInvoiceItemRow(
                  '3. Transmission Commodity Charge (20% on Offtake @ ₹${contract.transmissionTariffInrMmbtu.toStringAsFixed(1)})',
                  contract.transmissionCommodityChargeInr,
                ),
                const SizedBox(height: 4),
                _buildInvoiceItemRow(
                  '4. Gas Imbalance Cash-out / Penalty (${contract.imbalanceMmbtu.toStringAsFixed(0)} MMBTU @ ${contract.imbalanceUnitPenaltyMultiplier}x rate)',
                  contract.imbalanceAdjustmentInr,
                  isHighlight: contract.imbalanceAdjustmentInr != 0,
                  highlightColor: contract.imbalanceAdjustmentInr > 0
                      ? AppTheme.secondary
                      : AppTheme.tertiary,
                ),
                const SizedBox(height: 4),
                _buildInvoiceItemRow(
                  '5. GST on Transmission Services (18% on ₹${(contract.totalTransmissionTariffInr / 100000).toStringAsFixed(2)} Lakhs)',
                  contract.gstOnTransmissionInr,
                ),
                const Divider(color: AppTheme.border, height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL PAYABLE FOR GAS DAY:',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹ ${_currencyFormat.format(contract.netDailySettlementInr)}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItemRow(
    String label,
    double valueInr, {
    bool isHighlight = false,
    Color? highlightColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isHighlight ? highlightColor : AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          '₹ ${_currencyFormat.format(valueInr)}',
          style: TextStyle(
            color: isHighlight ? highlightColor : AppTheme.textPrimary,
            fontSize: 10.5,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // INTERACTIVE MODALS & DIALOGS
  // ============================================================================

  void _pickGasDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedGasDay,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme,
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedGasDay = picked;
      });
    }
  }

  void _showOfftakeSimulationModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Simulate Meter Offtake & Imbalance',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Text(
                    'Slide actual metered offtake values to inspect live PNGRB tariff penal reactions.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 14),
                  ..._contracts.map((c) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              c.shortCode,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${c.actualOfftakeMmscmd.toStringAsFixed(2)} MMSCMD (${c.imbalancePct >= 0 ? '+' : ''}${c.imbalancePct.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                color: c.imbalanceBand == ImbalanceBand.withinTolerance
                                    ? AppTheme.tertiary
                                    : c.imbalanceBand == ImbalanceBand.overdrawalTier1 ||
                                            c.imbalanceBand == ImbalanceBand.underdrawalTier1
                                        ? AppTheme.secondary
                                        : const Color(0xFFEF4444),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: c.actualOfftakeMmscmd,
                          min: (c.dcqMmscmd * 0.5).clamp(0.1, 2.0),
                          max: (c.dcqMmscmd * 1.5).clamp(0.2, 3.0),
                          divisions: 40,
                          activeColor: AppTheme.primaryLight,
                          inactiveColor: AppTheme.border,
                          onChanged: (val) {
                            setModalState(() {
                              final idx = _contracts.indexWhere((item) => item.id == c.id);
                              if (idx != -1) {
                                _contracts[idx] = _contracts[idx].copyWith(
                                  actualOfftakeMmscmd: val,
                                );
                              }
                            });
                            setState(() {});
                          },
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply Simulation & Close'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditContractOfftakeModal(GasConsumerContract contract) {
    double tempOfftake = contract.actualOfftakeMmscmd;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(
                'Adjust Offtake: ${contract.shortCode}',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contract DCQ: ${contract.dcqMmscmd.toStringAsFixed(2)} MMSCMD\nScheduled: ${contract.scheduledMmscmd.toStringAsFixed(2)} MMSCMD',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Actual Metered Offtake: ${tempOfftake.toStringAsFixed(2)} MMSCMD',
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: tempOfftake,
                    min: 0.20,
                    max: 2.00,
                    divisions: 36,
                    activeColor: AppTheme.primaryLight,
                    inactiveColor: AppTheme.border,
                    onChanged: (val) {
                      setDialogState(() {
                        tempOfftake = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      final idx = _contracts.indexWhere((c) => c.id == contract.id);
                      if (idx != -1) {
                        _contracts[idx] = _contracts[idx].copyWith(actualOfftakeMmscmd: tempOfftake);
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save Offtake'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCustodySettlementInvoiceModal() {
    final invoiceNo = 'OIL/GSA/INV/2026-09/042';
    final tokenPayload = '$invoiceNo|${_selectedGasDay.toIso8601String()}|$_totalDailySettlementCrores';
    final hashToken = sha256.convert(utf8.encode(tokenPayload)).toString().substring(0, 24).toUpperCase();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: const [
              Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 20),
              SizedBox(width: 8),
              Text(
                'Tripartite Custody Tax Invoice',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('INVOICE REF: $invoiceNo',
                            style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text('DATE: ${DateFormat('dd-MMM-yyyy').format(_selectedGasDay)} | GAS DAY: 06:00-06:00',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                        Text('DISPATCHER: Oil India Limited (Central Gas Gathering Station Duliajan)',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('SETTLED CONSUMER LEDGER (INCL 18% GST ON TARIFF):',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ..._contracts.map((c) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.5),
                        child: Row(
                          children: [
                            Expanded(child: Text(c.name, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5))),
                            Text('₹ ${_currencyFormat.format(c.netDailySettlementInr)}',
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )),
                  const Divider(color: AppTheme.border, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('NET INVOICE TOTAL:',
                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('₹ ${_totalDailySettlementCrores.toStringAsFixed(2)} Cr',
                          style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w900, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh.withAlpha(50),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SHA-256 CUSTODY AUDIT TOKEN:',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 8.5, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        SelectableText(
                          hashToken,
                          style: const TextStyle(
                            color: AppTheme.tertiary,
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Signed by Transporter Dispatcher, Offtaker Shipper & Independent TPIA Metering Auditor.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Custody Settlement Voucher & Audit Hash exported to PDF Dossier.'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 14),
              label: const Text('Export Voucher'),
            ),
          ],
        );
      },
    );
  }

  void _showPngrbRegulationsModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'PNGRB Pipeline Tariff Framework',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
          ),
          content: const SingleChildScrollView(
            child: Text(
              '1. Regulations: PNGRB (Determination of Natural Gas Pipeline Tariff) Regulations, 2008 and PNGRB (Access Code for Common Carrier or Contract Carrier Natural Gas Pipelines) Regulations.\n\n'
              '2. Unified Pipeline Tariff System: Levelized transmission charges across national pipeline grid. Zone 1 (≤300 km) set at ₹34.50/MMBTU; Zone 2 (>300 km) at ₹58.20/MMBTU.\n\n'
              '3. Capacity Reservation: Two-part tariff structure where 80% is fixed capacity reservation based on scheduled flow, and 20% variable commodity flow charge.\n\n'
              '4. Take-or-Pay (ToP): Commercial safeguard setting Minimum Take Obligation at 90.0% of ACQ less turnaround days. Make-up gas credits recoverable within 24 months.\n\n'
              '5. Imbalance Bands: Tolerance of ±5.0% without penalty. Overdrawal >10% triggers 1.5x gas price penalty and ₹125/MMBTU overrun fee.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.4),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Understood'),
            ),
          ],
        );
      },
    );
  }
}
