import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import 'materials_screen.dart';

/// Unit of measurement for weighbridge operations
enum WeightUnit {
  tons('MT', 'Metric Tons', 1.0),
  quintals('Qtl', 'Quintals', 10.0);

  final String code;
  final String label;
  final double conversionFactorFromTons; // 1 Ton = 10 Quintals

  const WeightUnit(this.code, this.label, this.conversionFactorFromTons);
}

/// Tolerance profile based on IS 2386 & CPWD Specifications
enum MaterialToleranceProfile {
  aggregate20mm('Coarse Aggregate 20mm', 'AGG-20MM', 1.5, 1850.0),
  aggregate40mm('Coarse Aggregate 40mm', 'AGG-40MM', 1.5, 1720.0),
  riverbedSand('Riverbed Coarse Sand', 'SAND-COARSE', 1.5, 980.0),
  granularSubBase('Granular Sub-Base (GSB)', 'GSB-GR3', 2.0, 750.0),
  bulkCement('Bulk Bulker Cement (OPC 53)', 'CEM-OPC53', 0.5, 6400.0),
  wetMixMacadam('Wet Mix Macadam (WMM)', 'WMM-BASE', 1.5, 1250.0),
  tmtSteel('TMT Reinforcement Fe-500D', 'STEEL-TMT', 0.2, 58000.0);

  final String displayName;
  final String materialCode;
  final double tolerancePercent;
  final double defaultRatePerTon;

  const MaterialToleranceProfile(
    this.displayName,
    this.materialCode,
    this.tolerancePercent,
    this.defaultRatePerTon,
  );
}

/// Status of reconciliation between PO/DC quantity and Measured Weight
enum ReconciliationState {
  withinTolerance,
  excessSurplus,
  shortageExceeded,
}

/// Inbound Gate Pass / Weighbridge Ticket Record
class WeighbridgeTicketRecord {
  final String ticketId;
  final String gatePassId;
  final String vehicleNumber;
  final String driverName;
  final String driverPhone;
  final String transporter;
  final String supplier;
  final String poNumber;
  final String dcNumber;
  final String materialName;
  final String materialCode;
  final String destination;
  final String activityCode;
  final double grossWeightTons;
  final double tareWeightTons;
  final double netWeightTons;
  final double dcWeightTons;
  final double tolerancePercent;
  final double unitRate;
  final DateTime gateInTime;
  DateTime? gateOutTime;
  String? grnNumber;
  String status; // 'WEIGHED', 'GRN_GENERATED', 'DISCREPANCY_FLAGGED', 'QUARANTINED'
  String? resolutionNote;
  String? resolutionType;

  WeighbridgeTicketRecord({
    required this.ticketId,
    required this.gatePassId,
    required this.vehicleNumber,
    required this.driverName,
    required this.driverPhone,
    required this.transporter,
    required this.supplier,
    required this.poNumber,
    required this.dcNumber,
    required this.materialName,
    required this.materialCode,
    required this.destination,
    required this.activityCode,
    required this.grossWeightTons,
    required this.tareWeightTons,
    required this.netWeightTons,
    required this.dcWeightTons,
    required this.tolerancePercent,
    required this.unitRate,
    required this.gateInTime,
    this.gateOutTime,
    this.grnNumber,
    this.status = 'WEIGHED',
    this.resolutionNote,
    this.resolutionType,
  });

  double get varianceWeightTons => netWeightTons - dcWeightTons;
  double get variancePercent =>
      dcWeightTons > 0 ? ((netWeightTons - dcWeightTons) / dcWeightTons) * 100 : 0.0;

  ReconciliationState get reconciliationState {
    if (variancePercent < -tolerancePercent) {
      return ReconciliationState.shortageExceeded;
    } else if (variancePercent > tolerancePercent) {
      return ReconciliationState.excessSurplus;
    }
    return ReconciliationState.withinTolerance;
  }

  double get financialDiscrepancy => (netWeightTons - dcWeightTons) * unitRate;
}

class WeighbridgeTicketScreen extends StatefulWidget {
  const WeighbridgeTicketScreen({super.key});

  @override
  State<WeighbridgeTicketScreen> createState() => _WeighbridgeTicketScreenState();
}

class _WeighbridgeTicketScreenState extends State<WeighbridgeTicketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Active form controllers
  final TextEditingController _gatePassCtrl = TextEditingController();
  final TextEditingController _ticketNoCtrl = TextEditingController();
  final TextEditingController _vehicleCtrl = TextEditingController();
  final TextEditingController _driverNameCtrl = TextEditingController();
  final TextEditingController _driverPhoneCtrl = TextEditingController();
  final TextEditingController _transporterCtrl = TextEditingController();
  final TextEditingController _supplierCtrl = TextEditingController();
  final TextEditingController _dcNoCtrl = TextEditingController();
  final TextEditingController _poNoCtrl = TextEditingController();
  final TextEditingController _destinationCtrl = TextEditingController();
  final TextEditingController _activityCodeCtrl = TextEditingController();

  // Numerical controllers
  final TextEditingController _grossWeightCtrl = TextEditingController();
  final TextEditingController _tareWeightCtrl = TextEditingController();
  final TextEditingController _dcWeightCtrl = TextEditingController();
  final TextEditingController _ratePerTonCtrl = TextEditingController();
  final TextEditingController _toleranceCtrl = TextEditingController();

  // Filter & search for registry tab
  final TextEditingController _registrySearchCtrl = TextEditingController();
  String _registryFilter = 'ALL'; // ALL, PASS, SHORTAGE, GRN

  // Unit toggle: Tons or Quintals
  WeightUnit _currentUnit = WeightUnit.tons;

  // Selected Material Profile
  MaterialToleranceProfile _selectedMaterial = MaterialToleranceProfile.aggregate20mm;

  // Live scale sensor animation/mock state
  bool _isScaleStabilizing = false;
  bool _isTareZeroed = false;
  String _scaleStatus = 'STABLE'; // STABLE, CAPTURING, ZEROED

  // Discrepancy resolution state
  bool _isDiscrepancyResolved = false;
  String? _resolvedResolutionType;
  String? _resolvedNotes;

  // Mock registry records
  final List<WeighbridgeTicketRecord> _ticketHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _populateInitialTicket();
    _seedRegistryHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gatePassCtrl.dispose();
    _ticketNoCtrl.dispose();
    _vehicleCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _transporterCtrl.dispose();
    _supplierCtrl.dispose();
    _dcNoCtrl.dispose();
    _poNoCtrl.dispose();
    _destinationCtrl.dispose();
    _activityCodeCtrl.dispose();
    _grossWeightCtrl.dispose();
    _tareWeightCtrl.dispose();
    _dcWeightCtrl.dispose();
    _ratePerTonCtrl.dispose();
    _toleranceCtrl.dispose();
    _registrySearchCtrl.dispose();
    super.dispose();
  }

  void _populateInitialTicket() {
    final now = DateTime.now();
    final epochSuffix = now.millisecondsSinceEpoch.toString().substring(8);
    _gatePassCtrl.text = 'GP-IN-2026-$epochSuffix';
    _ticketNoCtrl.text = 'WB-88$epochSuffix';
    _vehicleCtrl.text = 'AS-06-BC-4129';
    _driverNameCtrl.text = 'Biren Gogoi';
    _driverPhoneCtrl.text = '+91 98640 14820';
    _transporterCtrl.text = 'Brahmaputra Heavy Freight Lines';
    _supplierCtrl.text = 'Barak Valley Quarry & Aggregates Ltd';
    _dcNoCtrl.text = 'DC-AGG-2026-9921';
    _poNoCtrl.text = 'PO-OIL-2026-PKG2-088';
    _destinationCtrl.text = 'Batching Plant 02 - Duliajan Yard';
    _activityCodeCtrl.text = 'PIP-L5-024';

    _selectedMaterial = MaterialToleranceProfile.aggregate20mm;
    _toleranceCtrl.text = _selectedMaterial.tolerancePercent.toStringAsFixed(1);
    _ratePerTonCtrl.text = _selectedMaterial.defaultRatePerTon.toStringAsFixed(0);

    // Initial weights (Clean pass: DC 32.00 MT, Gross 46.85 MT, Tare 14.70 MT -> Net 32.15 MT, +0.47%)
    _dcWeightCtrl.text = '32.00';
    _grossWeightCtrl.text = '46.85';
    _tareWeightCtrl.text = '14.70';
    _isDiscrepancyResolved = false;
    _resolvedResolutionType = null;
    _resolvedNotes = null;
  }

  void _seedRegistryHistory() {
    final now = DateTime.now();
    _ticketHistory.addAll([
      WeighbridgeTicketRecord(
        ticketId: 'WB-884102',
        gatePassId: 'GP-IN-2026-4102',
        vehicleNumber: 'AS-01-EC-9041',
        driverName: 'Suraj Sonowal',
        driverPhone: '+91 98640 55120',
        transporter: 'Kamrup Logistics Corp',
        supplier: 'Barak Valley Quarry & Aggregates Ltd',
        poNumber: 'PO-OIL-2026-PKG2-088',
        dcNumber: 'DC-AGG-2026-9918',
        materialName: 'Coarse Aggregate 20mm',
        materialCode: 'AGG-20MM',
        destination: 'Batching Plant 02 - Duliajan Yard',
        activityCode: 'PIP-L5-024',
        grossWeightTons: 47.10,
        tareWeightTons: 14.80,
        netWeightTons: 32.30,
        dcWeightTons: 32.20,
        tolerancePercent: 1.5,
        unitRate: 1850.0,
        gateInTime: now.subtract(const Duration(hours: 4, minutes: 20)),
        gateOutTime: now.subtract(const Duration(hours: 3, minutes: 45)),
        status: 'GRN_GENERATED',
        grnNumber: 'GRN-WB-2026-0814',
      ),
      WeighbridgeTicketRecord(
        ticketId: 'WB-884095',
        gatePassId: 'GP-IN-2026-4095',
        vehicleNumber: 'NL-07-AA-3312',
        driverName: 'Pranab Saikia',
        driverPhone: '+91 94350 88201',
        transporter: 'Northeast Heavy Movers',
        supplier: 'Silchar Riverbed Minerals Corp',
        poNumber: 'PO-OIL-2026-PKG2-092',
        dcNumber: 'DC-SND-2026-5541',
        materialName: 'Riverbed Coarse Sand',
        materialCode: 'SAND-COARSE',
        destination: 'Sand Stockpile Yard #3',
        activityCode: 'PIP-L5-018',
        grossWeightTons: 48.00,
        tareWeightTons: 14.60,
        netWeightTons: 33.40,
        dcWeightTons: 35.00,
        tolerancePercent: 1.5,
        unitRate: 980.0,
        gateInTime: now.subtract(const Duration(hours: 7, minutes: 15)),
        gateOutTime: now.subtract(const Duration(hours: 6, minutes: 30)),
        status: 'DISCREPANCY_FLAGGED',
        grnNumber: 'GRN-WB-2026-0812',
        resolutionType: 'DEBIT_NOTE',
        resolutionNote: 'Transit spillage detected. Debit note DN-2026-042 issued for 1.6 MT shortage.',
      ),
      WeighbridgeTicketRecord(
        ticketId: 'WB-884080',
        gatePassId: 'GP-IN-2026-4080',
        vehicleNumber: 'WB-23-D-7789',
        driverName: 'Ramen Das',
        driverPhone: '+91 97060 12890',
        transporter: 'Interstate Bulk Cargoes',
        supplier: 'Subansiri Granular Crushing Ltd',
        poNumber: 'PO-OIL-2026-PKG2-076',
        dcNumber: 'DC-GSB-2026-1102',
        materialName: 'Granular Sub-Base (GSB)',
        materialCode: 'GSB-GR3',
        destination: 'Right-of-Way Sub-grade Staging',
        activityCode: 'PIP-L5-012',
        grossWeightTons: 43.10,
        tareWeightTons: 14.30,
        netWeightTons: 28.80,
        dcWeightTons: 28.50,
        tolerancePercent: 2.0,
        unitRate: 750.0,
        gateInTime: now.subtract(const Duration(hours: 10, minutes: 0)),
        gateOutTime: now.subtract(const Duration(hours: 9, minutes: 20)),
        status: 'GRN_GENERATED',
        grnNumber: 'GRN-WB-2026-0808',
      ),
    ]);
  }

  // --- Quick Scenario Presets ---
  void _applyPreset(int index) {
    setState(() {
      _isDiscrepancyResolved = false;
      _resolvedResolutionType = null;
      _resolvedNotes = null;

      final now = DateTime.now();
      final suffix = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');

      switch (index) {
        case 0:
          // Preset 0: Coarse Aggregate 20mm (Clean PASS: +0.47%)
          _selectedMaterial = MaterialToleranceProfile.aggregate20mm;
          _vehicleCtrl.text = 'AS-06-BC-4129';
          _supplierCtrl.text = 'Barak Valley Quarry & Aggregates Ltd';
          _transporterCtrl.text = 'Brahmaputra Heavy Freight Lines';
          _dcNoCtrl.text = 'DC-AGG-2026-$suffix';
          _poNoCtrl.text = 'PO-OIL-2026-PKG2-088';
          _dcWeightCtrl.text = '32.00';
          _grossWeightCtrl.text = '46.85';
          _tareWeightCtrl.text = '14.70';
          _toleranceCtrl.text = '1.5';
          _ratePerTonCtrl.text = '1850';
          _destinationCtrl.text = 'Batching Plant 02 - Duliajan Yard';
          _activityCodeCtrl.text = 'PIP-L5-024';
          break;

        case 1:
          // Preset 1: River Sand (Severe Shortage ALERT: -4.57%)
          _selectedMaterial = MaterialToleranceProfile.riverbedSand;
          _vehicleCtrl.text = 'AS-01-EE-8832';
          _supplierCtrl.text = 'Silchar Riverbed Minerals Corp';
          _transporterCtrl.text = 'Kamrup Logistics Corp';
          _dcNoCtrl.text = 'DC-SND-2026-$suffix';
          _poNoCtrl.text = 'PO-OIL-2026-PKG2-092';
          _dcWeightCtrl.text = '35.00';
          _grossWeightCtrl.text = '48.00';
          _tareWeightCtrl.text = '14.60'; // Net = 33.40 MT (Shortage: -1.60 MT, -4.57%)
          _toleranceCtrl.text = '1.5';
          _ratePerTonCtrl.text = '980';
          _destinationCtrl.text = 'Sand Stockpile Yard #3';
          _activityCodeCtrl.text = 'PIP-L5-018';
          break;

        case 2:
          // Preset 2: Granular Sub-base (Within 2% Tolerance: +1.05%)
          _selectedMaterial = MaterialToleranceProfile.granularSubBase;
          _vehicleCtrl.text = 'NL-07-BB-5521';
          _supplierCtrl.text = 'Subansiri Granular Crushing Ltd';
          _transporterCtrl.text = 'Northeast Heavy Movers';
          _dcNoCtrl.text = 'DC-GSB-2026-$suffix';
          _poNoCtrl.text = 'PO-OIL-2026-PKG2-076';
          _dcWeightCtrl.text = '28.50';
          _grossWeightCtrl.text = '43.10';
          _tareWeightCtrl.text = '14.30'; // Net = 28.80 MT (+0.30 MT, +1.05%)
          _toleranceCtrl.text = '2.0';
          _ratePerTonCtrl.text = '750';
          _destinationCtrl.text = 'Right-of-Way Sub-grade Staging';
          _activityCodeCtrl.text = 'PIP-L5-012';
          break;

        case 3:
          // Preset 3: Crushed Stone 40mm (Exceeded Shortage: -2.00%)
          _selectedMaterial = MaterialToleranceProfile.aggregate40mm;
          _vehicleCtrl.text = 'WB-23-E-9041';
          _supplierCtrl.text = 'Upper Assam Stone Works';
          _transporterCtrl.text = 'All-India Logistics Fleet';
          _dcNoCtrl.text = 'DC-STN-2026-$suffix';
          _poNoCtrl.text = 'PO-OIL-2026-PKG2-088';
          _dcWeightCtrl.text = '30.00';
          _grossWeightCtrl.text = '43.90';
          _tareWeightCtrl.text = '14.50'; // Net = 29.40 MT (-0.60 MT, -2.00%)
          _toleranceCtrl.text = '1.5';
          _ratePerTonCtrl.text = '1720';
          _destinationCtrl.text = 'Drainage Filter Bed Sector 6';
          _activityCodeCtrl.text = 'PIP-L5-024';
          break;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded Preset: ${_selectedMaterial.displayName}'),
        backgroundColor: const Color(0xFF1E2E5C),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- Calculations ---
  double get _grossTons => double.tryParse(_grossWeightCtrl.text) ?? 0.0;
  double get _tareTons => double.tryParse(_tareWeightCtrl.text) ?? 0.0;
  double get _netTons {
    final net = _grossTons - _tareTons;
    return net > 0 ? net : 0.0;
  }

  double get _dcTons => double.tryParse(_dcWeightCtrl.text) ?? 0.0;
  double get _tolerancePercent =>
      double.tryParse(_toleranceCtrl.text) ?? _selectedMaterial.tolerancePercent;
  double get _ratePerTon =>
      double.tryParse(_ratePerTonCtrl.text) ?? _selectedMaterial.defaultRatePerTon;

  double get _varianceTons => _netTons - _dcTons;
  double get _variancePercent =>
      _dcTons > 0 ? ((_netTons - _dcTons) / _dcTons) * 100 : 0.0;

  ReconciliationState get _reconciliationState {
    if (_variancePercent < -_tolerancePercent) {
      return ReconciliationState.shortageExceeded;
    } else if (_variancePercent > _tolerancePercent) {
      return ReconciliationState.excessSurplus;
    }
    return ReconciliationState.withinTolerance;
  }

  double get _financialDiscrepancy => _varianceTons * _ratePerTon;

  // Conversion helpers
  double _toCurrentUnit(double weightInTons) {
    return weightInTons * _currentUnit.conversionFactorFromTons;
  }

  String _formatWeight(double weightInTons, {int decimals = 2}) {
    final converted = _toCurrentUnit(weightInTons);
    return '${converted.toStringAsFixed(decimals)} ${_currentUnit.code}';
  }

  // Live scale capture simulation
  void _simulateScaleReading(bool isGross) {
    setState(() {
      _isScaleStabilizing = true;
      _scaleStatus = 'CAPTURING...';
    });

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        _isScaleStabilizing = false;
        _scaleStatus = 'STABLE';
        final randomJitter = (Random().nextDouble() * 0.08) - 0.04;
        if (isGross) {
          final current = double.tryParse(_grossWeightCtrl.text) ?? 46.85;
          _grossWeightCtrl.text = (current + randomJitter).toStringAsFixed(2);
        } else {
          final current = double.tryParse(_tareWeightCtrl.text) ?? 14.70;
          _tareWeightCtrl.text = (current + randomJitter).toStringAsFixed(2);
        }
      });
      HapticFeedback.lightImpact();
    });
  }

  void _zeroTare() {
    setState(() {
      _isTareZeroed = !_isTareZeroed;
      if (_isTareZeroed) {
        _scaleStatus = 'TARE ZEROED';
      } else {
        _scaleStatus = 'STABLE';
      }
    });
    HapticFeedback.selectionClick();
  }

  // --- 1-Tap GRN Generation Handler ---
  Future<void> _handleGenerateGrn() async {
    // If shortage exceeds tolerance and not yet authorized, show alert modal
    if (_reconciliationState == ReconciliationState.shortageExceeded &&
        !_isDiscrepancyResolved) {
      _showDiscrepancyAlertModal();
      return;
    }

    final provider = context.read<AppProvider>();
    final projectId = provider.currentProjectId ?? 'PRJ-OIL-DULIAJAN-2026';
    final epoch = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final grnNumber = 'GRN-WB-2026-$epoch';

    // Build ledger payload
    final materialTx = {
      'projectId': projectId,
      'docType': 'GRN',
      'docNumber': grnNumber,
      'materialCode': _selectedMaterial.materialCode,
      'description':
          '${_selectedMaterial.displayName} (Gate Pass ${_gatePassCtrl.text}, Truck ${_vehicleCtrl.text}, WB Net: ${_netTons.toStringAsFixed(2)} MT)',
      'quantity': _netTons,
      'unit': _currentUnit == WeightUnit.tons ? 'MT' : 'Quintals',
      'destinationLocation': _destinationCtrl.text,
      'associatedActivityCode': _activityCodeCtrl.text,
      'sourceSupplier': '${_supplierCtrl.text} via ${_transporterCtrl.text}',
      'date': DateTime.now().toIso8601String().split('T')[0],
      'poNumber': _poNoCtrl.text,
      'dcNumber': _dcNoCtrl.text,
      'grossWeight': _grossTons,
      'tareWeight': _tareTons,
      'netWeight': _netTons,
      'variancePercent': _variancePercent,
      'varianceWeight': _varianceTons,
      'shortageResolution': _resolvedResolutionType,
      'resolutionNotes': _resolvedNotes,
    };

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryLight),
      ),
    );

    try {
      await provider.recordMaterialTransaction(materialTx);
    } catch (e) {
      debugPrint('[Weighbridge] Provider record error (will still register locally): $e');
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

    // Record into local history
    final record = WeighbridgeTicketRecord(
      ticketId: _ticketNoCtrl.text,
      gatePassId: _gatePassCtrl.text,
      vehicleNumber: _vehicleCtrl.text,
      driverName: _driverNameCtrl.text,
      driverPhone: _driverPhoneCtrl.text,
      transporter: _transporterCtrl.text,
      supplier: _supplierCtrl.text,
      poNumber: _poNoCtrl.text,
      dcNumber: _dcNoCtrl.text,
      materialName: _selectedMaterial.displayName,
      materialCode: _selectedMaterial.materialCode,
      destination: _destinationCtrl.text,
      activityCode: _activityCodeCtrl.text,
      grossWeightTons: _grossTons,
      tareWeightTons: _tareTons,
      netWeightTons: _netTons,
      dcWeightTons: _dcTons,
      tolerancePercent: _tolerancePercent,
      unitRate: _ratePerTon,
      gateInTime: DateTime.now().subtract(const Duration(minutes: 25)),
      gateOutTime: DateTime.now(),
      status: 'GRN_GENERATED',
      grnNumber: grnNumber,
      resolutionType: _resolvedResolutionType,
      resolutionNote: _resolvedNotes,
    );

    setState(() {
      _ticketHistory.insert(0, record);
    });

    HapticFeedback.heavyImpact();

    // Show Official GRN Success Sheet
    _showGrnReceiptBottomSheet(record);
  }

  // --- Weight Discrepancy Alert Modal ---
  void _showDiscrepancyAlertModal() {
    String selectedCause = 'Transit Spillage / Loss en route';
    String selectedResolution = 'DEBIT_NOTE';
    final notesController = TextEditingController(
      text:
          'Net weight (${_netTons.toStringAsFixed(2)} MT) is ${_varianceTons.abs().toStringAsFixed(2)} MT below DC quantity (${_dcTons.toStringAsFixed(2)} MT). Exceeds ±${_tolerancePercent.toStringAsFixed(1)}% tolerance limit.',
    );
    final pinController = TextEditingController(text: '4421');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final shortageMT = _varianceTons.abs();
            final lossAmount = shortageMT * _ratePerTon;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF111C38),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: Color(0xFFFF5252), width: 2)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modal Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5252).withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFF5252)),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFF5252),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WEIGHT DISCREPANCY ALERT',
                                style: TextStyle(
                                  color: Color(0xFFFF5252),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Tolerance Breach: ${_variancePercent.toStringAsFixed(2)}% (Max ±${_tolerancePercent.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textMuted),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Metrics Comparison Matrix
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF162347),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            'Delivery Challan (Billed)',
                            '${_dcTons.toStringAsFixed(2)} MT',
                            AppTheme.textPrimary,
                          ),
                          const Divider(color: AppTheme.border, height: 16),
                          _buildSummaryRow(
                            'Weighbridge Net Received',
                            '${_netTons.toStringAsFixed(2)} MT',
                            AppTheme.textPrimary,
                          ),
                          const Divider(color: AppTheme.border, height: 16),
                          _buildSummaryRow(
                            'Shortfall Deficit',
                            '-${shortageMT.toStringAsFixed(2)} MT (-${(_variancePercent.abs()).toStringAsFixed(2)}%)',
                            const Color(0xFFFF5252),
                            isBold: true,
                          ),
                          const Divider(color: AppTheme.border, height: 16),
                          _buildSummaryRow(
                            'Financial Loss Value',
                            '₹${lossAmount.toStringAsFixed(0)} (@ ₹${_ratePerTon.toStringAsFixed(0)}/MT)',
                            AppTheme.secondary,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Probable Root Cause Selector
                    const Text(
                      'SUSPECTED ROOT CAUSE',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCause,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceCard,
                          items: const [
                            DropdownMenuItem(
                              value: 'Transit Spillage / Loss en route',
                              child: Text(
                                'Transit Spillage / Loss en route',
                                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Moisture Evaporation Loss (IS 2386)',
                              child: Text(
                                'Moisture Evaporation Loss (IS 2386)',
                                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Quarry Weighbridge Calibration Drift',
                              child: Text(
                                'Quarry Weighbridge Calibration Drift',
                                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Truck Tailboard Leakage / Tampering',
                              child: Text(
                                'Truck Tailboard Leakage / Tampering',
                                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedCause = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Industrial Resolution Action Radio List
                    const Text(
                      'SELECT AUTHORIZED RESOLUTION',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildResolutionTile(
                      title: '1. Issue Debit Note to Supplier/Transporter',
                      subtitle:
                          'Deduct ₹${lossAmount.toStringAsFixed(0)} from RA Bill. Generate GRN for full billed MT with debit note reference.',
                      value: 'DEBIT_NOTE',
                      groupValue: selectedResolution,
                      onChanged: (v) => setModalState(() => selectedResolution = v!),
                      badge: 'RECOMMENDED',
                      badgeColor: AppTheme.primaryLight,
                    ),
                    const SizedBox(height: 8),

                    _buildResolutionTile(
                      title: '2. Accept Net Weight Only',
                      subtitle:
                          'Generate GRN for strictly ${_netTons.toStringAsFixed(2)} MT. Payment released only for physical net received.',
                      value: 'ACCEPT_NET_ONLY',
                      groupValue: selectedResolution,
                      onChanged: (v) => setModalState(() => selectedResolution = v!),
                      badge: 'STRICT BOQ',
                      badgeColor: AppTheme.tertiary,
                    ),
                    const SizedBox(height: 8),

                    _buildResolutionTile(
                      title: '3. Site Engineer Discretionary Override',
                      subtitle:
                          'Authorize full receipt under moisture/settlement tolerance. Requires Engineer security PIN sign-off.',
                      value: 'SUPERVISOR_OVERRIDE',
                      groupValue: selectedResolution,
                      onChanged: (v) => setModalState(() => selectedResolution = v!),
                      badge: 'PIN REQUIRED',
                      badgeColor: AppTheme.secondary,
                    ),
                    const SizedBox(height: 8),

                    _buildResolutionTile(
                      title: '4. Reject Consignment & Gate Out',
                      subtitle:
                          'Refuse unloading. Truck must exit premises with Return Gate Pass.',
                      value: 'REJECT_GATE_OUT',
                      groupValue: selectedResolution,
                      onChanged: (v) => setModalState(() => selectedResolution = v!),
                      badge: 'GATE REJECT',
                      badgeColor: const Color(0xFFFF5252),
                    ),
                    const SizedBox(height: 14),

                    // Justification notes
                    const Text(
                      'OFFICIAL AUDIT REMARKS / JUSTIFICATION',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Enter justification for audit log...',
                      ),
                    ),

                    if (selectedResolution == 'SUPERVISOR_OVERRIDE') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.lock_outline, color: AppTheme.secondary, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Engineer Security PIN:',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: pinController,
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'PIN',
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Confirm Action Button
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(modalCtx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedResolution == 'REJECT_GATE_OUT'
                                  ? const Color(0xFFFF5252)
                                  : AppTheme.primary,
                            ),
                            icon: Icon(
                              selectedResolution == 'REJECT_GATE_OUT'
                                  ? Icons.block_rounded
                                  : Icons.verified_user_rounded,
                              size: 18,
                            ),
                            label: Text(
                              selectedResolution == 'REJECT_GATE_OUT'
                                  ? 'Reject & Gate Out'
                                  : 'Authorize & Proceed GRN',
                            ),
                            onPressed: () {
                              Navigator.pop(modalCtx);
                              if (selectedResolution == 'REJECT_GATE_OUT') {
                                _handleGateReject(notesController.text);
                              } else {
                                setState(() {
                                  _isDiscrepancyResolved = true;
                                  _resolvedResolutionType = selectedResolution;
                                  _resolvedNotes =
                                      '[$selectedResolution] $selectedCause: ${notesController.text}';
                                });
                                _handleGenerateGrn();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleGateReject(String remarks) {
    setState(() {
      _ticketHistory.insert(
        0,
        WeighbridgeTicketRecord(
          ticketId: _ticketNoCtrl.text,
          gatePassId: _gatePassCtrl.text,
          vehicleNumber: _vehicleCtrl.text,
          driverName: _driverNameCtrl.text,
          driverPhone: _driverPhoneCtrl.text,
          transporter: _transporterCtrl.text,
          supplier: _supplierCtrl.text,
          poNumber: _poNoCtrl.text,
          dcNumber: _dcNoCtrl.text,
          materialName: _selectedMaterial.displayName,
          materialCode: _selectedMaterial.materialCode,
          destination: _destinationCtrl.text,
          activityCode: _activityCodeCtrl.text,
          grossWeightTons: _grossTons,
          tareWeightTons: _tareTons,
          netWeightTons: _netTons,
          dcWeightTons: _dcTons,
          tolerancePercent: _tolerancePercent,
          unitRate: _ratePerTon,
          gateInTime: DateTime.now().subtract(const Duration(minutes: 30)),
          gateOutTime: DateTime.now(),
          status: 'QUARANTINED',
          resolutionType: 'REJECTED_GATE_OUT',
          resolutionNote: remarks,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gate Pass Rejected. Return slip logged to Gate Control.'),
        backgroundColor: Color(0xFFFF5252),
      ),
    );
  }

  // --- Official GRN Receipt Bottom Sheet ---
  void _showGrnReceiptBottomSheet(WeighbridgeTicketRecord record) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF111C38),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppTheme.tertiary, width: 2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Header
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withAlpha(40),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.tertiary, width: 2),
                ),
                child: const Icon(Icons.check_rounded, color: AppTheme.tertiary, size: 32),
              ),
              const SizedBox(height: 12),
              const Text(
                'GOODS RECEIPT NOTE (GRN) ISSUED',
                style: TextStyle(
                  color: AppTheme.tertiary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Transaction committed to materials_ledger and realDb',
                style: TextStyle(color: AppTheme.textSecondary.withAlpha(200), fontSize: 12),
              ),
              const SizedBox(height: 18),

              // Digital Inward Slip Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF162347),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GRN DOCUMENT #',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              record.grnNumber ?? 'GRN-PENDING',
                              style: const TextStyle(
                                color: AppTheme.primaryLight,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.tertiary.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.tertiary.withAlpha(100)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_rounded, color: AppTheme.tertiary, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'WEIGHED & VERIFIED',
                                style: TextStyle(
                                  color: AppTheme.tertiary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.border, height: 20),

                    _buildSummaryRow('Material', record.materialName, AppTheme.textPrimary),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Vehicle No.', record.vehicleNumber, AppTheme.textPrimary),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Supplier / Quarry', record.supplier, AppTheme.textSecondary),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Challan Ref', record.dcNumber, AppTheme.textSecondary),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Net Accepted Qty',
                      '${record.netWeightTons.toStringAsFixed(2)} MT (${(record.netWeightTons * 10).toStringAsFixed(1)} Qtl)',
                      AppTheme.primaryLight,
                      isBold: true,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'DC Variance',
                      '${record.variancePercent >= 0 ? "+" : ""}${record.variancePercent.toStringAsFixed(2)}%',
                      record.reconciliationState == ReconciliationState.withinTolerance
                          ? AppTheme.tertiary
                          : AppTheme.secondary,
                    ),
                    if (record.resolutionType != null) ...[
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'Resolution',
                        record.resolutionType ?? '',
                        const Color(0xFFFFB95F),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Timestamp',
                      dateFormat.format(record.gateOutTime ?? DateTime.now()),
                      AppTheme.textMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.inventory_2_rounded, size: 16),
                      label: const Text('View Ledger'),
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MaterialsScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                      label: const Text('Next Vehicle'),
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        setState(() {
                          _populateInitialTicket();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper widget for summary rows
  static Widget _buildSummaryRow(
    String label,
    String value,
    Color valueColor, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget for resolution radio tiles
  Widget _buildResolutionTile({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    required String badge,
    required Color badgeColor,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? badgeColor.withAlpha(25) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? badgeColor : AppTheme.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? badgeColor : AppTheme.textMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: badgeColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: badgeColor.withAlpha(120)),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textMuted.withAlpha(220),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weighbridge & Challan Verification',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Nirmaan OS Inbound Logistics Engine',
              style: TextStyle(
                color: AppTheme.primaryLight,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Unit Switcher Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildUnitToggleChip(WeightUnit.tons),
                _buildUnitToggleChip(WeightUnit.quintals),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Reset / New Ticket',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: () {
              setState(() {
                _populateInitialTicket();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Initialized New Weighbridge Gate Pass'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'View Stores Ledger',
            icon: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryLight),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MaterialsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.scale_rounded, size: 18), text: 'Gate & Scale'),
            Tab(icon: Icon(Icons.compare_arrows_rounded, size: 18), text: 'Reconciliation'),
            Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: 'Ticket Registry'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScaleEntryTab(),
          _buildReconciliationTab(),
          _buildRegistryTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildUnitToggleChip(WeightUnit unit) {
    final isSelected = _currentUnit == unit;
    return GestureDetector(
      onTap: () {
        if (_currentUnit != unit) {
          setState(() {
            _currentUnit = unit;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          unit.code,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: GATE & SCALE (Interactive Scale & Pass Details)
  // ===========================================================================
  Widget _buildScaleEntryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scenario Quick Picker Bar
          _buildScenarioPresetsBar(),
          const SizedBox(height: 16),

          // High-Tech Digital Scale Display Indicator
          _buildDigitalScaleDisplay(),
          const SizedBox(height: 16),

          // Inbound Gross & Tare Weight Capture Cards
          _buildWeightCaptureSection(),
          const SizedBox(height: 16),

          // Net Material Weight Hero Summary Card
          _buildNetMaterialHeroCard(),
          const SizedBox(height: 16),

          // Inbound Gate Pass & Logistics Form
          _buildGatePassDetailsSection(),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildScenarioPresetsBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TEST SCENARIO PRESETS',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '1-Tap Load',
              style: TextStyle(
                color: AppTheme.primaryLight.withAlpha(200),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPresetChip(
                label: 'Aggregate 20mm (Pass +0.47%)',
                color: AppTheme.tertiary,
                onTap: () => _applyPreset(0),
              ),
              const SizedBox(width: 8),
              _buildPresetChip(
                label: 'River Sand (Shortage -4.57%)',
                color: const Color(0xFFFF5252),
                onTap: () => _applyPreset(1),
              ),
              const SizedBox(width: 8),
              _buildPresetChip(
                label: 'GSB Sub-Base (Pass +1.05%)',
                color: AppTheme.primaryLight,
                onTap: () => _applyPreset(2),
              ),
              const SizedBox(width: 8),
              _buildPresetChip(
                label: 'Stone 40mm (Shortage -2.00%)',
                color: AppTheme.secondary,
                onTap: () => _applyPreset(3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      onPressed: onTap,
      backgroundColor: AppTheme.surfaceCard,
      side: BorderSide(color: color.withAlpha(120)),
      avatar: CircleAvatar(backgroundColor: color, radius: 4),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDigitalScaleDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF070D1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF26396E), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _isScaleStabilizing ? AppTheme.secondary : AppTheme.tertiary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isScaleStabilizing ? AppTheme.secondary : AppTheme.tertiary)
                              .withAlpha(150),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'WEIGHBRIDGE PLATFORM #01',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withAlpha(200),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _scaleStatus,
                  style: TextStyle(
                    color: _scaleStatus == 'STABLE'
                        ? AppTheme.tertiary
                        : (_scaleStatus.contains('CAPTURING')
                            ? AppTheme.secondary
                            : AppTheme.primaryLight),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Digital 7-Segment style readout
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF030712),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E2E5C)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LIVE PLATFORM SENSOR',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 9,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isScaleStabilizing
                          ? '----.--'
                          : _formatWeight(_grossTons > 0 ? _grossTons : 0.0),
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 32,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF162347),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          onPressed: _zeroTare,
                          child: Text(
                            _isTareZeroed ? 'UNZERO' : 'ZERO TARE',
                            style: const TextStyle(color: AppTheme.secondary, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'COM3: 9600-8-N-1 (OK)',
                      style: TextStyle(
                        color: AppTheme.tertiary.withAlpha(200),
                        fontSize: 9,
                        fontFamily: 'monospace',
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

  Widget _buildWeightCaptureSection() {
    return Row(
      children: [
        // Gross Weight Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GROSS WEIGHT',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    InkWell(
                      onTap: () => _simulateScaleReading(true),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(40),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.sensors_rounded,
                          color: AppTheme.primaryLight,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _grossWeightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    suffixText: _currentUnit.code,
                    suffixStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 6),
                Text(
                  'Truck + Loaded Material',
                  style: TextStyle(color: AppTheme.textMuted.withAlpha(200), fontSize: 10),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Tare Weight Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TARE WEIGHT',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    InkWell(
                      onTap: () => _simulateScaleReading(false),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withAlpha(40),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.sensors_rounded,
                          color: AppTheme.secondary,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tareWeightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    suffixText: _currentUnit.code,
                    suffixStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 6),
                Text(
                  'Unladen Empty Vehicle',
                  style: TextStyle(color: AppTheme.textMuted.withAlpha(200), fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetMaterialHeroCard() {
    final netMT = _netTons;
    final netQtl = netMT * 10.0;
    final netKg = netMT * 1000.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C2444), Color(0xFF162347)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight.withAlpha(100), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calculate_rounded, color: AppTheme.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'NET MATERIAL DELIVERED',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Gross - Tare',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _currentUnit == WeightUnit.tons
                    ? netMT.toStringAsFixed(2)
                    : netQtl.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _currentUnit.code,
                style: const TextStyle(
                  color: AppTheme.secondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${netMT.toStringAsFixed(2)} MT',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${netQtl.toStringAsFixed(1)} Quintals',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${NumberFormat('#,##0').format(netKg)} kg',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGatePassDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.badge_outlined, color: AppTheme.primaryLight, size: 18),
              SizedBox(width: 8),
              Text(
                'INBOUND GATE PASS & LOGISTICS',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Gate Pass & Ticket ID
          Row(
            children: [
              Expanded(child: _buildTextFormField('Gate Pass ID', _gatePassCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextFormField('Ticket Number', _ticketNoCtrl)),
            ],
          ),
          const SizedBox(height: 12),

          // Vehicle Number & Driver Name
          Row(
            children: [
              Expanded(
                child: _buildTextFormField('Vehicle Reg. No.', _vehicleCtrl, isUppercase: true),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildTextFormField('Driver Name', _driverNameCtrl)),
            ],
          ),
          const SizedBox(height: 12),

          // Driver Mobile & Transporter
          Row(
            children: [
              Expanded(child: _buildTextFormField('Driver Mobile', _driverPhoneCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextFormField('Transporter Fleet', _transporterCtrl)),
            ],
          ),
          const SizedBox(height: 12),

          // Material Specification Dropdown
          const Text(
            'Material Category',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<MaterialToleranceProfile>(
                value: _selectedMaterial,
                isExpanded: true,
                dropdownColor: AppTheme.surfaceCard,
                items: MaterialToleranceProfile.values.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(
                      '${item.displayName} (±${item.tolerancePercent}%)',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedMaterial = val;
                      _toleranceCtrl.text = val.tolerancePercent.toStringAsFixed(1);
                      _ratePerTonCtrl.text = val.defaultRatePerTon.toStringAsFixed(0);
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Supplier / Quarry Source
          _buildTextFormField('Supplier / Quarry Source', _supplierCtrl),
          const SizedBox(height: 12),

          // Destination & Associated Activity
          Row(
            children: [
              Expanded(
                child: _buildTextFormField('Destination Yard', _destinationCtrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextFormField('Activity Code', _activityCodeCtrl),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: RECONCILIATION (PO/DC vs Weighed + Tolerance Check)
  // ===========================================================================
  Widget _buildReconciliationTab() {
    final state = _reconciliationState;
    final isShortage = state == ReconciliationState.shortageExceeded;
    final isPassed = state == ReconciliationState.withinTolerance;

    final variancePct = _variancePercent;
    final finAmount = _financialDiscrepancy.abs();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Reconciliation Status Banner
          _buildReconciliationStatusBanner(state, variancePct),
          const SizedBox(height: 16),

          // Side-by-Side Comparison Card: DC vs Weighed
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DELIVERY CHALLAN RECONCILIATION',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'IS 2386 & CPWD Spec',
                      style: TextStyle(color: AppTheme.primaryLight, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    // DC Billed Quantity Box
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1A35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DC / PO Billed Qty',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _dcWeightCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                suffixText: _currentUnit.code,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              onChanged: (val) => setState(() {}),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Challan Ref: ${_dcNoCtrl.text}',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Inbound Measured Net Weight Box
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1A35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isPassed
                                ? AppTheme.tertiary.withAlpha(120)
                                : (isShortage
                                    ? const Color(0xFFFF5252).withAlpha(120)
                                    : AppTheme.secondary.withAlpha(120)),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Weighbridge Net Qty',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatWeight(_netTons),
                              style: TextStyle(
                                color: isPassed
                                    ? AppTheme.tertiary
                                    : (isShortage ? const Color(0xFFFF5252) : AppTheme.secondary),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Platform #01 Sensor',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Variance Meter Bar
                _buildVarianceMeter(variancePct, _tolerancePercent),
                const SizedBox(height: 16),

                // Financial Impact Breakdown
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh.withAlpha(80),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Financial Discrepancy',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${NumberFormat('#,##0').format(finAmount)}',
                            style: TextStyle(
                              color: isPassed
                                  ? AppTheme.tertiary
                                  : (isShortage ? const Color(0xFFFF5252) : AppTheme.secondary),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Unit Material Rate',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${_ratePerTon.toStringAsFixed(0)} / MT',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tolerance Configuration & PO References
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppTheme.primaryLight, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'TOLERANCE RULES & RECONCILIATION PARAMETERS',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextFormField(
                        'Allowed Tolerance (± %)',
                        _toleranceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextFormField(
                        'Billing Unit Rate (₹/MT)',
                        _ratePerTonCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextFormField('PO Number Ref.', _poNoCtrl),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextFormField('Challan (DC) Ref.', _dcNoCtrl),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Callout if Discrepancy Exists
          if (isShortage) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF5252).withAlpha(120)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFFF5252), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Shortage Exceeds Tolerance Threshold',
                          style: TextStyle(
                            color: Color(0xFFFF5252),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isDiscrepancyResolved
                              ? 'Authorized Resolution: $_resolvedResolutionType'
                              : 'Requires supervisor sign-off or debit note prior to GRN entry.',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5252),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: _showDiscrepancyAlertModal,
                    child: Text(_isDiscrepancyResolved ? 'Edit Resolution' : 'Review Alert'),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildReconciliationStatusBanner(ReconciliationState state, double variancePct) {
    Color bannerColor;
    IconData bannerIcon;
    String title;
    String subtitle;

    switch (state) {
      case ReconciliationState.withinTolerance:
        bannerColor = AppTheme.tertiary;
        bannerIcon = Icons.check_circle_rounded;
        title = 'RECONCILIATION PASSED (WITHIN ±${_tolerancePercent.toStringAsFixed(1)}%)';
        subtitle =
            'Measured variance of ${variancePct >= 0 ? "+" : ""}${variancePct.toStringAsFixed(2)}% is within standard civil tolerance. Ready for instant GRN.';
        break;
      case ReconciliationState.excessSurplus:
        bannerColor = AppTheme.secondary;
        bannerIcon = Icons.info_outline_rounded;
        title = 'SURPLUS DELIVERED (+${variancePct.toStringAsFixed(2)}%)';
        subtitle =
            'Supplier delivered +${_varianceTons.toStringAsFixed(2)} MT extra. Verify moisture absorption or adjust receipt to DC quantity.';
        break;
      case ReconciliationState.shortageExceeded:
        bannerColor = const Color(0xFFFF5252);
        bannerIcon = Icons.warning_amber_rounded;
        title = 'CRITICAL SHORTAGE DETECTED (${variancePct.toStringAsFixed(2)}%)';
        subtitle =
            'Deficit of ${_varianceTons.abs().toStringAsFixed(2)} MT exceeds the ±${_tolerancePercent.toStringAsFixed(1)}% contractual threshold. Action required.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withAlpha(25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bannerColor.withAlpha(150), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bannerColor.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(bannerIcon, color: bannerColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: bannerColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVarianceMeter(double variancePct, double tolerancePct) {
    // Normalizing -5% to +5% range for the meter slider
    const maxRange = 5.0;
    final clampedPct = variancePct.clamp(-maxRange, maxRange);
    final normalized = (clampedPct + maxRange) / (maxRange * 2); // 0.0 to 1.0

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tolerance Variance Deviation',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
            Text(
              '${variancePct >= 0 ? "+" : ""}${variancePct.toStringAsFixed(2)}%',
              style: TextStyle(
                color: _reconciliationState == ReconciliationState.withinTolerance
                    ? AppTheme.tertiary
                    : (_reconciliationState == ReconciliationState.shortageExceeded
                        ? const Color(0xFFFF5252)
                        : AppTheme.secondary),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Visual Meter Track
        Stack(
          children: [
            // Background bar
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF0B1326),
                borderRadius: BorderRadius.circular(5),
              ),
            ),

            // Permissible Green Zone (e.g. -1.5% to +1.5%)
            FractionallySizedBox(
              alignment: Alignment.center,
              widthFactor: (tolerancePct * 2) / (maxRange * 2),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withAlpha(90),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),

            // Marker Needle / Dot
            Align(
              alignment: Alignment((normalized * 2) - 1, 0),
              child: Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(top: 0),
                decoration: BoxDecoration(
                  color: _reconciliationState == ReconciliationState.withinTolerance
                      ? AppTheme.tertiary
                      : (_reconciliationState == ReconciliationState.shortageExceeded
                          ? const Color(0xFFFF5252)
                          : AppTheme.secondary),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(120),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '-${tolerancePct.toStringAsFixed(1)}% Limit',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
            const Text(
              'Exact (0.0%)',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
            Text(
              '+${tolerancePct.toStringAsFixed(1)}% Limit',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 3: REGISTRY (History & Search of Gate Passes)
  // ===========================================================================
  Widget _buildRegistryTab() {
    final query = _registrySearchCtrl.text.toLowerCase().trim();
    final filtered = _ticketHistory.where((item) {
      if (_registryFilter == 'PASS' &&
          item.reconciliationState != ReconciliationState.withinTolerance) {
        return false;
      }
      if (_registryFilter == 'SHORTAGE' &&
          item.reconciliationState != ReconciliationState.shortageExceeded) {
        return false;
      }
      if (_registryFilter == 'GRN' && item.grnNumber == null) {
        return false;
      }

      if (query.isNotEmpty) {
        final passId = item.gatePassId.toLowerCase();
        final vehicle = item.vehicleNumber.toLowerCase();
        final ticket = item.ticketId.toLowerCase();
        final mat = item.materialName.toLowerCase();
        if (!passId.contains(query) &&
            !vehicle.contains(query) &&
            !ticket.contains(query) &&
            !mat.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Search & Filter header
        Container(
          padding: const EdgeInsets.all(14),
          color: AppTheme.surface,
          child: Column(
            children: [
              TextField(
                controller: _registrySearchCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by Vehicle No, Gate Pass, or Material...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                          onPressed: () => setState(() => _registrySearchCtrl.clear()),
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.surfaceCard,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All Tickets (${_ticketHistory.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('PASS', 'Within Tolerance'),
                    const SizedBox(width: 8),
                    _buildFilterChip('SHORTAGE', 'Shortage Alerts'),
                    const SizedBox(width: 8),
                    _buildFilterChip('GRN', 'GRN Issued'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Registry List
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No weighbridge tickets match your criteria',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, index) {
                    final item = filtered[index];
                    return _buildRegistryTicketCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _registryFilter == key;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.surfaceCard,
      onSelected: (val) {
        if (val) setState(() => _registryFilter = key);
      },
    );
  }

  Widget _buildRegistryTicketCard(WeighbridgeTicketRecord item) {
    final dateFormat = DateFormat('dd MMM, HH:mm');
    final isShortage = item.reconciliationState == ReconciliationState.shortageExceeded;
    final isPassed = item.reconciliationState == ReconciliationState.withinTolerance;

    return Card(
      color: AppTheme.surfaceCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isShortage ? const Color(0xFFFF5252).withAlpha(120) : AppTheme.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1A35),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        item.vehicleNumber,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.gatePassId,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPassed
                        ? AppTheme.tertiary.withAlpha(30)
                        : (isShortage
                            ? const Color(0xFFFF5252).withAlpha(30)
                            : AppTheme.secondary.withAlpha(30)),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isPassed
                          ? AppTheme.tertiary.withAlpha(100)
                          : (isShortage
                              ? const Color(0xFFFF5252).withAlpha(100)
                              : AppTheme.secondary.withAlpha(100)),
                    ),
                  ),
                  child: Text(
                    isPassed
                        ? 'PASSED (+${item.variancePercent.toStringAsFixed(1)}%)'
                        : (isShortage
                            ? 'SHORTAGE (${item.variancePercent.toStringAsFixed(1)}%)'
                            : 'SURPLUS (+${item.variancePercent.toStringAsFixed(1)}%)'),
                    style: TextStyle(
                      color: isPassed
                          ? AppTheme.tertiary
                          : (isShortage ? const Color(0xFFFF5252) : AppTheme.secondary),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              item.materialName,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Supplier: ${item.supplier}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DC Weight',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    Text('${item.dcWeightTons.toStringAsFixed(2)} MT',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gross Scale',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    Text('${item.grossWeightTons.toStringAsFixed(2)} MT',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tare Scale',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    Text('${item.tareWeightTons.toStringAsFixed(2)} MT',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Net Weighed',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    Text(
                      '${item.netWeightTons.toStringAsFixed(2)} MT',
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: AppTheme.border, height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_rounded, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      item.grnNumber ?? 'GRN Pending',
                      style: TextStyle(
                        color: item.grnNumber != null
                            ? AppTheme.tertiary
                            : AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  dateFormat.format(item.gateInTime),
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM 1-TAP ACTION BAR
  // ===========================================================================
  Widget _buildBottomActionBar() {
    final state = _reconciliationState;
    final isShortage = state == ReconciliationState.shortageExceeded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quick Status Pill
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NET WEIGHED: ${_formatWeight(_netTons)}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Variance: ${_variancePercent >= 0 ? "+" : ""}${_variancePercent.toStringAsFixed(2)}% (${_reconciliationState == ReconciliationState.withinTolerance ? "PASS" : (_reconciliationState == ReconciliationState.shortageExceeded ? "ALERT" : "SURPLUS")})',
                    style: TextStyle(
                      color: _reconciliationState == ReconciliationState.withinTolerance
                          ? AppTheme.tertiary
                          : (_reconciliationState == ReconciliationState.shortageExceeded
                              ? const Color(0xFFFF5252)
                              : AppTheme.secondary),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // 1-Tap GRN Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isShortage && !_isDiscrepancyResolved
                    ? const Color(0xFFFF5252)
                    : AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              icon: Icon(
                isShortage && !_isDiscrepancyResolved
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
              ),
              label: Text(
                isShortage && !_isDiscrepancyResolved ? 'Review Shortage' : 'Generate GRN',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              onPressed: _handleGenerateGrn,
            ),
          ],
        ),
      ),
    );
  }

  // Reusable text input
  Widget _buildTextFormField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool isUppercase = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization:
              isUppercase ? TextCapitalization.characters : TextCapitalization.none,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}
