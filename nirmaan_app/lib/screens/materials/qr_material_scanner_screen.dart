import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import 'materials_screen.dart';

/// Industrial material tag model for the QR / Barcode scanner simulation.
class MaterialTagData {
  final String code;
  final String name;
  final String heatNumber;
  final String mtcStatus;
  final String mtcCertNo;
  final String mtcStandard;
  final double defaultQuantity;
  final String unit;
  final String totalWeight;
  final String grade;
  final String dimensions;
  final String manufacturer;
  final String poNumber;
  final String storageLocation;
  final String qaStatus;
  final String chemicalAnalysis;
  final String mechanicalProps;
  final String defaultGrnSource;
  final String defaultGrnDest;
  final String defaultGrnAct;
  final String defaultGrnSupervisor;
  final String defaultGinSource;
  final String defaultGinDest;
  final String defaultGinAct;
  final String defaultGinSupervisor;

  const MaterialTagData({
    required this.code,
    required this.name,
    required this.heatNumber,
    required this.mtcStatus,
    required this.mtcCertNo,
    required this.mtcStandard,
    required this.defaultQuantity,
    required this.unit,
    required this.totalWeight,
    required this.grade,
    required this.dimensions,
    required this.manufacturer,
    required this.poNumber,
    required this.storageLocation,
    required this.qaStatus,
    required this.chemicalAnalysis,
    required this.mechanicalProps,
    required this.defaultGrnSource,
    required this.defaultGrnDest,
    required this.defaultGrnAct,
    required this.defaultGrnSupervisor,
    required this.defaultGinSource,
    required this.defaultGinDest,
    required this.defaultGinAct,
    required this.defaultGinSupervisor,
  });
}

class QrMaterialScannerScreen extends StatefulWidget {
  const QrMaterialScannerScreen({super.key});

  @override
  State<QrMaterialScannerScreen> createState() => _QrMaterialScannerScreenState();
}

class _QrMaterialScannerScreenState extends State<QrMaterialScannerScreen>
    with TickerProviderStateMixin {
  // Preset materials library with industrial metadata
  static const List<MaterialTagData> _materialPresets = [
    MaterialTagData(
      code: 'PIPE-CS-API5L-X65',
      name: 'Seamless Carbon Steel Line Pipe',
      heatNumber: 'HT-88421',
      mtcStatus: 'MTC Verified ✓',
      mtcCertNo: 'MTC-2026-X65-0914',
      mtcStandard: 'EN 10204 Type 3.1',
      defaultQuantity: 48.0,
      unit: 'Meters',
      totalWeight: '4.82 Metric Tons',
      grade: 'API 5L Grade X65 PSL-2 / ISO 3183',
      dimensions: 'OD 406.4mm (16") × WT 14.3mm × 12m Joints',
      manufacturer: 'Tata Steel Tubing Division, Kalinganagar',
      poNumber: 'PO-2026-NIR-0842',
      storageLocation: 'Central Yard Bay C-14 / Rack 08',
      qaStatus: 'PASSED QA/QC L3 (100% NDT & Hydro 15.2 MPa)',
      chemicalAnalysis: 'C: 0.08% | Mn: 1.45% | Si: 0.28% | CEV: 0.38',
      mechanicalProps: 'Yield: 495 MPa | Tensile: 620 MPa | Elongation: 26%',
      defaultGrnSource: 'Tata Steel Kalinganagar (Supplier)',
      defaultGrnDest: 'Central Stores Bay C-14',
      defaultGrnAct: 'ACT-PIPELINE-LAYING',
      defaultGrnSupervisor: 'A. K. Sharma (Stores In-Charge)',
      defaultGinSource: 'Central Stores Bay C-14',
      defaultGinDest: 'Field Gang A (Chainage 42+100)',
      defaultGinAct: 'ACT-PIPE-WELDING-04',
      defaultGinSupervisor: 'R. K. Verma (Gang A Foreman)',
    ),
    MaterialTagData(
      code: 'REBAR-TMT-FE550D-32MM',
      name: 'High-Ductility TMT Rebar Bundles',
      heatNumber: 'HT-91042',
      mtcStatus: 'MTC Verified ✓',
      mtcCertNo: 'MTC-2026-TMT-550D-441',
      mtcStandard: 'IS 1786:2008 Fe 550D',
      defaultQuantity: 12.5,
      unit: 'Tons',
      totalWeight: '12.50 Metric Tons',
      grade: 'Fe 550D High Ductility Earthquake Resistant',
      dimensions: 'Dia 32 mm × Length 12.0m Bundles (16 Bars/Bundle)',
      manufacturer: 'Jindal Steel & Power Ltd, Angul Works',
      poNumber: 'PO-2026-NIR-0799',
      storageLocation: 'Rebar Yard Bay B-02 / Bundle Rack 3',
      qaStatus: 'PASSED QA/QC (Bend / Rebend & Chemical Validated)',
      chemicalAnalysis: 'C: 0.22% | S: 0.035% | P: 0.038% | CEV: 0.41',
      mechanicalProps: 'Yield: 565 MPa | UTS/YS: 1.14 | Total Elongation: 16%',
      defaultGrnSource: 'JSPL Angul Works (Supplier)',
      defaultGrnDest: 'Rebar Yard Bay B-02',
      defaultGrnAct: 'ACT-FOUNDATION-RAFT-02',
      defaultGrnSupervisor: 'P. K. Mishra (Yard Supervisor)',
      defaultGinSource: 'Rebar Yard Bay B-02',
      defaultGinDest: 'Field Gang A (Pier P4 Foundation)',
      defaultGinAct: 'ACT-REBAR-CAGE-TYING',
      defaultGinSupervisor: 'R. K. Verma (Gang A Foreman)',
    ),
    MaterialTagData(
      code: 'VALVE-BALL-CL600-12IN',
      name: 'Trunnion Mounted Ball Valve Class 600',
      heatNumber: 'HT-74319',
      mtcStatus: 'MTC Verified ✓',
      mtcCertNo: 'MTC-2026-VLV-743',
      mtcStandard: 'API 6D / ASME B16.34',
      defaultQuantity: 4.0,
      unit: 'Units',
      totalWeight: '1.84 Metric Tons',
      grade: 'ASTM A216 WCB Body / SS316 Trim / Devlon V',
      dimensions: '12" NB Full Bore Flanged RTJ Ends',
      manufacturer: 'L&T Valves Limited, Coimbatore Plant',
      poNumber: 'PO-2026-NIR-0912',
      storageLocation: 'Central Stores Precision Room Shelf 04',
      qaStatus: 'PASSED (Fire Safe API 6FA & Hydro Tested 153 bar)',
      chemicalAnalysis: 'Body: WCB | Ball: F316 | Stem: 17-4PH Stainless',
      mechanicalProps: 'Shell Test: 153 bar | Seat Test: 112 bar | Zero Leakage',
      defaultGrnSource: 'L&T Valves Coimbatore (Supplier)',
      defaultGrnDest: 'Central Stores Precision Room',
      defaultGrnAct: 'ACT-VALVE-STATION-01',
      defaultGrnSupervisor: 'A. K. Sharma (Stores In-Charge)',
      defaultGinSource: 'Central Stores Precision Room',
      defaultGinDest: 'Field Gang A (Valve Station 01)',
      defaultGinAct: 'ACT-VALVE-ERECTION',
      defaultGinSupervisor: 'R. K. Verma (Gang A Foreman)',
    ),
    MaterialTagData(
      code: 'CEMENT-OPC-53-GRADE',
      name: 'Ordinary Portland Cement 53 Grade',
      heatNumber: 'HT-66210',
      mtcStatus: 'MTC Verified ✓',
      mtcCertNo: 'MTC-2026-OPC53-882',
      mtcStandard: 'IS 269:2015 Class 53',
      defaultQuantity: 350.0,
      unit: 'Bags',
      totalWeight: '17.50 Metric Tons',
      grade: 'OPC 53 Grade (High Early Strength)',
      dimensions: '50 kg Tamper-Proof HDPE Laminated Bags',
      manufacturer: 'UltraTech Cement Kotputli Works',
      poNumber: 'PO-2026-NIR-0870',
      storageLocation: 'Cement Godown Silo Shed #2',
      qaStatus: 'PASSED (28-Day Strength 58.4 MPa / Soundness 1.5mm)',
      chemicalAnalysis: 'Loss on Ignition: 1.8% | Insoluble Residue: 1.2%',
      mechanicalProps: 'Initial Setting: 145 min | Final: 215 min | Blaine: 340',
      defaultGrnSource: 'UltraTech Cement (Supplier)',
      defaultGrnDest: 'Cement Godown Shed #2',
      defaultGrnAct: 'ACT-CONCRETE-BATCHING',
      defaultGrnSupervisor: 'A. K. Sharma (Stores In-Charge)',
      defaultGinSource: 'Cement Godown Shed #2',
      defaultGinDest: 'Field Gang A (Batching Plant 01)',
      defaultGinAct: 'ACT-CONCRETE-BATCHING-MIX',
      defaultGinSupervisor: 'R. K. Verma (Gang A Foreman)',
    ),
  ];

  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isTorchOn = false;
  bool _isMacroLens = false;
  double _zoomLevel = 1.0;
  String _scanMode = 'QR Code';
  bool _isScanning = false;
  bool _isTargetLocked = true; // Auto-locks by default to instantly show validation card
  int _currentPresetIndex = 0;
  late double _quantityValue;
  bool _isSubmitting = false;
  bool _isDetailsExpanded = false;

  MaterialTagData get _currentMaterial => _materialPresets[_currentPresetIndex];

  @override
  void initState() {
    super.initState();
    _quantityValue = _currentMaterial.defaultQuantity;

    // Laser vertical oscillation animation
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    // Pulse animation when target is locked
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerSimulatedScan({int? targetPresetIndex}) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (targetPresetIndex != null) {
        _currentPresetIndex = targetPresetIndex;
        _quantityValue = _currentMaterial.defaultQuantity;
      }
      _isScanning = true;
      _isTargetLocked = false;
    });

    // Simulate laser scanning tag detection after 1.6s
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _isScanning = false;
        _isTargetLocked = true;
      });
    });
  }

  void _switchPreset(int index) {
    if (index == _currentPresetIndex) return;
    _triggerSimulatedScan(targetPresetIndex: index);
  }

  Future<void> _handleExecuteTransaction({required String type}) async {
    if (_isSubmitting) return;
    HapticFeedback.heavyImpact();

    setState(() => _isSubmitting = true);

    final provider = context.read<AppProvider>();
    final isGrn = type == 'GRN';
    final randomSuffix = 1000 + Random().nextInt(8999);
    final docNumber = '${isGrn ? 'GRN' : 'GIN'}-2026-$randomSuffix';
    final timestamp = DateTime.now().toIso8601String();
    final today = timestamp.split('T')[0];

    final Map<String, dynamic> transactionData = {
      'docType': type,
      'code': docNumber,
      'materialCode': _currentMaterial.code,
      'description': '${_currentMaterial.code} (${_currentMaterial.name})',
      'heatNumber': _currentMaterial.heatNumber,
      'mtcNumber': _currentMaterial.mtcCertNo,
      'quantity': _quantityValue,
      'unit': _currentMaterial.unit,
      'source': isGrn ? _currentMaterial.defaultGrnSource : _currentMaterial.defaultGinSource,
      'destination': isGrn ? _currentMaterial.defaultGrnDest : _currentMaterial.defaultGinDest,
      'activityCode': isGrn ? _currentMaterial.defaultGrnAct : _currentMaterial.defaultGinAct,
      'supervisor': isGrn ? _currentMaterial.defaultGrnSupervisor : _currentMaterial.defaultGinSupervisor,
      'date': today,
      'timestamp': timestamp,
      'qaStatus': 'VERIFIED_MTC_PASS',
      'verifiedBy': 'Nirmaan Optical AI Scanner',
    };

    try {
      await provider.recordMaterialTransaction(transactionData);
    } catch (_) {
      // In offline mode or if API is unreachable, local state in provider is updated
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    _showTransactionSuccessDialog(
      type: type,
      docNumber: docNumber,
      timestamp: timestamp,
      data: transactionData,
    );
  }

  void _showTransactionSuccessDialog({
    required String type,
    required String docNumber,
    required String timestamp,
    required Map<String, dynamic> data,
  }) {
    final isGrn = type == 'GRN';
    final primaryColor = isGrn ? AppTheme.tertiary : AppTheme.secondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111C38),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0xFF38BDF8), width: 1.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon Ring
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withAlpha(40),
                  border: Border.all(color: primaryColor, width: 2),
                ),
                child: Icon(
                  isGrn ? Icons.file_download_done_rounded : Icons.outbox_rounded,
                  color: primaryColor,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isGrn ? 'MATERIAL RECEIVED (GRN)' : 'MATERIAL ISSUED (GIN)',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ledger Entry: $docNumber',
                style: TextStyle(
                  color: primaryColor,
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              // Transaction Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF162347),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Material Code', _currentMaterial.code, isBold: true),
                    const Divider(color: AppTheme.border, height: 16),
                    _buildSummaryRow('Quantity', '$_quantityValue ${_currentMaterial.unit}'),
                    const Divider(color: AppTheme.border, height: 16),
                    _buildSummaryRow('Heat Number', _currentMaterial.heatNumber),
                    const Divider(color: AppTheme.border, height: 16),
                    _buildSummaryRow(
                      isGrn ? 'Originating Source' : 'Issuing Location',
                      data['source'] as String,
                    ),
                    const Divider(color: AppTheme.border, height: 16),
                    _buildSummaryRow(
                      isGrn ? 'Storage Destination' : 'Issued Target',
                      data['destination'] as String,
                    ),
                    const Divider(color: AppTheme.border, height: 16),
                    _buildSummaryRow('Mill Certificate', 'Verified ✓ (EN 10204 3.1)'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: const Text('Scan Next Tag', style: TextStyle(fontSize: 13)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _triggerSimulatedScan();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.inventory_2_rounded, size: 18),
                      label: const Text('Stores Ledger', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MaterialsScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isBold ? AppTheme.primaryLight : AppTheme.textPrimary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Material QR / Tag Scanner',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Live Laser Optical QA Engine',
              style: TextStyle(
                color: AppTheme.primaryLight,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Flashlight Toggle
          IconButton(
            tooltip: _isTorchOn ? 'Turn Torch Off' : 'Turn Torch On',
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? AppTheme.secondary : AppTheme.textSecondary,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          // Tag Selector / Presets
          IconButton(
            tooltip: 'Select Material Tag',
            icon: const Icon(Icons.dataset_outlined, color: AppTheme.textSecondary),
            onPressed: _showPresetSelectionModal,
          ),
          // Link to Stores Ledger
          IconButton(
            tooltip: 'View Stores Ledger',
            icon: const Icon(Icons.inventory_2_rounded, color: AppTheme.primaryLight),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MaterialsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // Background Camera Simulation & Laser Reticle
          Positioned.fill(
            child: _buildCameraViewport(),
          ),

          // Torch Light Simulation Glow Overlay
          if (_isTorchOn)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [
                        Colors.amber.withAlpha(45),
                        Colors.yellow.withAlpha(20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Top Camera Sensor HUD
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: _buildCameraStatusHud(),
          ),

          // Bottom Slide-Up Instant Material Validation Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildValidationCardOverlay(),
          ),
        ],
      ),
    );
  }

  // Camera viewport HUD with animated laser targeting
  Widget _buildCameraViewport() {
    return Container(
      color: const Color(0xFF070D1A),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle camera grid matrix
          Positioned.fill(
            child: CustomPaint(
              painter: CameraGridPainter(),
            ),
          ),

          // Simulated Material Tag Plate in Center
          _buildMaterialTagPlate(),

          // Optical Reticle & Animated Laser Line
          Positioned(
            width: 290,
            height: 290,
            child: AnimatedBuilder(
              animation: _laserAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ViewfinderReticlePainter(
                    laserProgress: _laserAnimation.value,
                    isLocked: _isTargetLocked,
                    isScanning: _isScanning,
                  ),
                );
              },
            ),
          ),

          // Floating Scan Status Badge
          Positioned(
            top: 70,
            child: _buildScanStatusChip(),
          ),

          // Scanner Mode Selector
          Positioned(
            top: 110,
            child: _buildScanModeChips(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraStatusHud() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111C38).withAlpha(220),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border.withAlpha(120)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isTargetLocked ? AppTheme.tertiary : Colors.redAccent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isTargetLocked ? 'TAG LOCKED (ECC200)' : 'SEARCHING TAG...',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildHudIndicator('ISO 400'),
              const SizedBox(width: 8),
              _buildHudIndicator(_isMacroLens ? 'MACRO' : '1080P/60'),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _zoomLevel = _zoomLevel == 1.0
                        ? 2.0
                        : (_zoomLevel == 2.0 ? 4.0 : 1.0);
                    _isMacroLens = _zoomLevel > 2.0;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(50),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.primary, width: 0.8),
                  ),
                  child: Text(
                    '${_zoomLevel.toInt()}X',
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHudIndicator(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildScanStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _isTargetLocked
            ? AppTheme.tertiary.withAlpha(40)
            : AppTheme.primary.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isTargetLocked ? AppTheme.tertiary : AppTheme.primaryLight,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isTargetLocked ? Icons.verified_rounded : Icons.sync_rounded,
            size: 14,
            color: _isTargetLocked ? AppTheme.tertiary : AppTheme.primaryLight,
          ),
          const SizedBox(width: 6),
          Text(
            _isTargetLocked
                ? 'Target Acquired: ${_currentMaterial.code}'
                : 'Align Material QR Code within reticle',
            style: TextStyle(
              color: _isTargetLocked ? AppTheme.tertiary : AppTheme.primaryLight,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanModeChips() {
    final modes = ['QR Code', 'DataMatrix', 'Barcode 128', 'RFID EPC'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF111C38).withAlpha(190),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modes.map((mode) {
          final isSelected = _scanMode == mode;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _scanMode = mode);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                mode,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Simulated metal heat identification tag with realistic 2D matrix
  Widget _buildMaterialTagPlate() {
    return ScaleTransition(
      scale: _isTargetLocked ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 230,
        height: 230,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF18223D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isTargetLocked
                ? AppTheme.tertiary.withAlpha(200)
                : AppTheme.primaryLight.withAlpha(80),
            width: _isTargetLocked ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isTargetLocked
                  ? AppTheme.tertiary.withAlpha(40)
                  : Colors.black.withAlpha(120),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Metal Tag Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.precision_manufacturing_rounded, size: 14, color: AppTheme.textSecondary),
                    SizedBox(width: 4),
                    Text(
                      'TATA STEEL MILL TAG',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiary.withAlpha(35),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.tertiary, width: 0.5),
                  ),
                  child: const Text(
                    'QC PASS',
                    style: TextStyle(
                      color: AppTheme.tertiary,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // High-Tech Industrial QR / 2D Matrix Mockup
            Expanded(
              child: Center(
                child: Container(
                  width: 130,
                  height: 130,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CustomPaint(
                    painter: IndustrialQrMatrixPainter(
                      codeSeed: _currentMaterial.code.hashCode,
                    ),
                  ),
                ),
              ),
            ),

            // Tag Details Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F182F),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border, width: 0.6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HEAT NUMBER',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 7, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _currentMaterial.heatNumber,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'GRADE SPEC',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 7, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _currentMaterial.code.split('-').length > 2
                            ? _currentMaterial.code.split('-').sublist(2).join('-')
                            : 'API 5L X65',
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 9,
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
      ),
    );
  }

  // Instant Material Validation Card Overlay
  Widget _buildValidationCardOverlay() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.58,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle & Re-scan bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Material Code Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _currentMaterial.code,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: _currentMaterial.code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Material Code copied to clipboard'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.copy_rounded,
                              size: 15,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _currentMaterial.name,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Rescan / Change Material Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 14, color: AppTheme.primaryLight),
                  label: const Text('Re-scan', style: TextStyle(fontSize: 11, color: AppTheme.primaryLight)),
                  onPressed: () => _triggerSimulatedScan(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Instant Material Validation 4-Block Matrix
            Row(
              children: [
                // Heat Number Card
                Expanded(
                  child: _buildValidationBlock(
                    label: 'Heat Number',
                    value: _currentMaterial.heatNumber,
                    subtext: 'Melt Melt ID',
                    icon: Icons.local_fire_department_rounded,
                    accentColor: AppTheme.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                // Mill Test Certificate Card
                Expanded(
                  child: _buildValidationBlock(
                    label: 'Mill Test Cert',
                    value: _currentMaterial.mtcStatus,
                    subtext: _currentMaterial.mtcCertNo,
                    icon: Icons.verified_user_rounded,
                    accentColor: AppTheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                // Batch Quantity Card with Stepper
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Batch Quantity',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _currentMaterial.unit,
                              style: const TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_quantityValue % 1 == 0 ? _quantityValue.toInt() : _quantityValue} ${_currentMaterial.unit}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Row(
                              children: [
                                _buildQuantityButton(
                                  icon: Icons.remove,
                                  onTap: () {
                                    if (_quantityValue > 1) {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _quantityValue -= (_currentMaterial.unit == 'Tons' ? 0.5 : 1.0);
                                        if (_quantityValue < 1) _quantityValue = 1;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(width: 4),
                                _buildQuantityButton(
                                  icon: Icons.add,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _quantityValue += (_currentMaterial.unit == 'Tons' ? 0.5 : 1.0);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Weight: ${_currentMaterial.totalWeight}',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // QA/QC Inspection Clearance
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'QA/QC Status',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                            Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.tertiary),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'PASSED L3',
                          style: TextStyle(
                            color: AppTheme.tertiary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'NDT & Hydro 100% Ok',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Expandable Technical Specs Accordion
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                initiallyExpanded: _isDetailsExpanded,
                onExpansionChanged: (val) => setState(() => _isDetailsExpanded = val),
                title: Row(
                  children: const [
                    Icon(Icons.analytics_outlined, size: 16, color: AppTheme.primaryLight),
                    SizedBox(width: 6),
                    Text(
                      'Mill Metallurgy & Traceability Specs',
                      style: TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F182F),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSpecLine('Standard & Grade', _currentMaterial.grade),
                        _buildSpecLine('Dimensions', _currentMaterial.dimensions),
                        _buildSpecLine('Manufacturer', _currentMaterial.manufacturer),
                        _buildSpecLine('PO Reference', _currentMaterial.poNumber),
                        _buildSpecLine('Assigned Bay', _currentMaterial.storageLocation),
                        _buildSpecLine('Chemical Comp', _currentMaterial.chemicalAnalysis),
                        _buildSpecLine('Mechanical Tests', _currentMaterial.mechanicalProps),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // One-Tap Actions: 'Receive into Central Stores (GRN)' or 'Issue to Field Gang A (GIN)'
            Row(
              children: [
                // GRN Action Button
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () => _handleExecuteTransaction(type: 'GRN'),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.download_rounded, size: 18),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Receive into Central Stores (GRN)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                // GIN Action Button
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB45309), // Industrial Amber
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () => _handleExecuteTransaction(type: 'GIN'),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.upload_rounded, size: 18),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Issue to Field Gang A (GIN)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationBlock({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
              ),
              Icon(icon, size: 13, color: accentColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2E5C),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.border, width: 0.8),
        ),
        child: Icon(icon, size: 12, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildSpecLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showPresetSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Text(
                  'Select Material Tag to Scan',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: AppTheme.border, height: 1),
              ...List.generate(_materialPresets.length, (idx) {
                final item = _materialPresets[idx];
                final isSelected = idx == _currentPresetIndex;
                return ListTile(
                  dense: true,
                  selected: isSelected,
                  selectedTileColor: AppTheme.primary.withAlpha(20),
                  leading: Icon(
                    Icons.qr_code_2_rounded,
                    color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
                  ),
                  title: Text(
                    item.code,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryLight : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  subtitle: Text(
                    '${item.name} • Heat: ${item.heatNumber}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryLight, size: 20)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _switchPreset(idx);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for the camera grid HUD overlay
class CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF162347).withAlpha(50)
      ..strokeWidth = 0.8;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the high-precision laser viewfinder targeting brackets
class ViewfinderReticlePainter extends CustomPainter {
  final double laserProgress;
  final bool isLocked;
  final bool isScanning;

  ViewfinderReticlePainter({
    required this.laserProgress,
    required this.isLocked,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cornerColor = isLocked ? const Color(0xFF4EDEA3) : const Color(0xFF38BDF8);
    final paint = Paint()
      ..color = cornerColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 32.0;

    // Top-Left corner
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // Top-Right corner
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-Left corner
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Bottom-Right corner
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);

    // Center Crosshairs
    final crossPaint = Paint()
      ..color = cornerColor.withAlpha(120)
      ..strokeWidth = 1.0;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const chLength = 10.0;
    const chGap = 8.0;

    canvas.drawLine(Offset(cx - chLength - chGap, cy), Offset(cx - chGap, cy), crossPaint);
    canvas.drawLine(Offset(cx + chGap, cy), Offset(cx + chLength + chGap, cy), crossPaint);
    canvas.drawLine(Offset(cx, cy - chLength - chGap), Offset(cx, cy - chGap), crossPaint);
    canvas.drawLine(Offset(cx, cy + chGap), Offset(cx, cy + chLength + chGap), crossPaint);

    // Animated Laser Beam Line
    final laserY = size.height * laserProgress;

    // Laser glow tail
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          cornerColor.withAlpha(0),
          cornerColor.withAlpha(60),
          cornerColor.withAlpha(0),
        ],
      ).createShader(Rect.fromLTWH(0, laserY - 14, size.width, 28));
    canvas.drawRect(Rect.fromLTWH(0, laserY - 14, size.width, 28), glowPaint);

    // Sharp Laser core line
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          cornerColor.withAlpha(20),
          cornerColor,
          Colors.white,
          cornerColor,
          cornerColor.withAlpha(20),
        ],
      ).createShader(Rect.fromLTWH(0, laserY, size.width, 2))
      ..strokeWidth = 2.2;

    canvas.drawLine(Offset(4, laserY), Offset(size.width - 4, laserY), linePaint);
  }

  @override
  bool shouldRepaint(covariant ViewfinderReticlePainter oldDelegate) {
    return oldDelegate.laserProgress != laserProgress ||
        oldDelegate.isLocked != isLocked ||
        oldDelegate.isScanning != isScanning;
  }
}

/// Custom painter to generate high-tech 2D DataMatrix / QR pixel pattern for material tags
class IndustrialQrMatrixPainter extends CustomPainter {
  final int codeSeed;

  IndustrialQrMatrixPainter({required this.codeSeed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0B1326)
      ..style = PaintingStyle.fill;

    const gridSize = 19;
    final cellSize = size.width / gridSize;
    final rand = Random(codeSeed);

    // Standard 3 Finder Patterns (Top-Left, Top-Right, Bottom-Left)
    _drawFinderPattern(canvas, 0, 0, cellSize, paint);
    _drawFinderPattern(canvas, (gridSize - 7) * cellSize, 0, cellSize, paint);
    _drawFinderPattern(canvas, 0, (gridSize - 7) * cellSize, cellSize, paint);

    // Fill pseudo-random matrix blocks deterministically from codeSeed
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        // Skip finder areas
        final inTL = r < 7 && c < 7;
        final inTR = r < 7 && c >= gridSize - 7;
        final inBL = r >= gridSize - 7 && c < 7;
        if (inTL || inTR || inBL) continue;

        // Timing patterns
        if (r == 6 || c == 6) {
          if ((r + c) % 2 == 0) {
            canvas.drawRect(Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize), paint);
          }
          continue;
        }

        // Pseudo-random data module
        if (rand.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(c * cellSize, r * cellSize, cellSize - 0.3, cellSize - 0.3), paint);
        }
      }
    }
  }

  void _drawFinderPattern(Canvas canvas, double x, double y, double cellSize, Paint paint) {
    // Outer 7x7 square
    canvas.drawRect(Rect.fromLTWH(x, y, 7 * cellSize, 7 * cellSize), paint);
    // Inner white 5x5 square
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(x + cellSize, y + cellSize, 5 * cellSize, 5 * cellSize), whitePaint);
    // Center 3x3 black dot
    canvas.drawRect(Rect.fromLTWH(x + 2 * cellSize, y + 2 * cellSize, 3 * cellSize, 3 * cellSize), paint);
  }

  @override
  bool shouldRepaint(covariant IndustrialQrMatrixPainter oldDelegate) {
    return oldDelegate.codeSeed != codeSeed;
  }
}
