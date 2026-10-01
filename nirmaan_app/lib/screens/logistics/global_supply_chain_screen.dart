import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/taxonomy/archetype_controller.dart';
import '../../core/taxonomy/project_archetype.dart';

class SupplyChainPackage {
  final String poNumber;
  final String description;
  final String vendor;
  final String countryOfOrigin;
  final String currentStage;
  final int stageIndex; // 0 to 4
  final String eta;
  final String vesselName;
  final String locationGeo;
  final int bufferDays;
  final String certificate;
  final Color statusColor;

  const SupplyChainPackage({
    required this.poNumber,
    required this.description,
    required this.vendor,
    required this.countryOfOrigin,
    required this.currentStage,
    required this.stageIndex,
    required this.eta,
    required this.vesselName,
    required this.locationGeo,
    required this.bufferDays,
    required this.certificate,
    required this.statusColor,
  });
}

class GlobalSupplyChainScreen extends StatefulWidget {
  const GlobalSupplyChainScreen({super.key});

  @override
  State<GlobalSupplyChainScreen> createState() => _GlobalSupplyChainScreenState();
}

class _GlobalSupplyChainScreenState extends State<GlobalSupplyChainScreen> {
  final List<String> _stages = [
    'Mill Rolling',
    'Factory FAT',
    'Sea Freight',
    'Port Customs',
    'Site Ingestion',
  ];

  final List<SupplyChainPackage> _packages = const [
    SupplyChainPackage(
      poNumber: 'PO-OIL-2026-X70-842',
      description: 'API 5L X70 PSL2 Submerged Arc Welded Pipe (142 km)',
      vendor: 'JFE Steel Corporation / Welspun Corp',
      countryOfOrigin: 'Japan / India',
      currentStage: 'Site Staging & QR Barcode Ingestion',
      stageIndex: 4,
      eta: 'DELIVERED ON SITE',
      vesselName: 'M/V Asian Glory',
      locationGeo: 'Assam Central Yard (KM 142)',
      bufferDays: 14,
      certificate: 'EN 10204 3.2 TPI Certified',
      statusColor: Color(0xFF10B981),
    ),
    SupplyChainPackage(
      poNumber: 'PO-OIL-2026-BOG-019',
      description: 'Cryogenic Boil-Off Gas (BOG) Reciprocating Compressor',
      vendor: 'Baker Hughes / Nuovo Pignone',
      countryOfOrigin: 'Florence, Italy',
      currentStage: 'Maritime Freight (Indian Ocean Transit)',
      stageIndex: 2,
      eta: '12 October 2026 (Port of Kolkata)',
      vesselName: 'CMA CGM Palais Royal',
      locationGeo: 'Lat 08°14\'N, Lon 77°20\'E (Speed: 18.4 kts)',
      bufferDays: 6,
      certificate: 'DNV GL Maritime Class 1',
      statusColor: Color(0xFF38BDF8),
    ),
    SupplyChainPackage(
      poNumber: 'PO-OIL-2026-VLV-104',
      description: '36" Class 900 API 6D Metal-Seated Ball Valves',
      vendor: 'Cameron / SLB Valves',
      countryOfOrigin: 'Littlehampton, UK',
      currentStage: 'Factory Acceptance Testing (FAT) Hydro Pressure',
      stageIndex: 1,
      eta: '28 October 2026',
      vesselName: 'Awaiting Port Loading (Felixstowe)',
      locationGeo: 'Factory Testing Bay #3',
      bufferDays: 2,
      certificate: 'API 6D / ISO 15848-1 Fugitive Emission',
      statusColor: Color(0xFFF59E0B),
    ),
    SupplyChainPackage(
      poNumber: 'PO-OIL-2026-TRF-003',
      description: '220kV / 33kV 100 MVA Power Transformer Unit 2',
      vendor: 'Siemens Energy AG',
      countryOfOrigin: 'Nuremberg, Germany',
      currentStage: 'Port Customs Clearance & Over-Dimensional Cargo (ODC) Permit',
      stageIndex: 3,
      eta: '06 October 2026 (Green Corridor Converted)',
      vesselName: 'Discharged at Haldia Dock Complex',
      locationGeo: 'Kolkata Customs CFS Bay 4',
      bufferDays: -3, // Delay alert
      certificate: 'IEC 60076 Type Tested',
      statusColor: Color(0xFFEF4444),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final arch = ArchetypeController.instance.current;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Global Logistics & Equipment Twin',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Mill-to-Site Critical Path Telemetry • ${arch.shortName}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // KPI Summary Row
            _buildLogisticsKpiSummary(),
            const SizedBox(height: 16),

            // Live Maritime Tracking Card
            _buildLiveMaritimeCard(),
            const SizedBox(height: 16),

            // Critical Packages List
            const Text(
              'Tracked Critical Procurement Packages',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._packages.map((pkg) => _buildPackageCard(pkg, arch)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogisticsKpiSummary() {
    return Row(
      children: [
        _buildKpiCard('Total POs', '42 Packages', '₹ 2,140 Cr', const Color(0xFF38BDF8)),
        const SizedBox(width: 8),
        _buildKpiCard('On High Seas', '4 Vessels', 'In Transit', const Color(0xFFF59E0B)),
        const SizedBox(width: 8),
        _buildKpiCard('Site Staged', '86.4%', 'QC Approved', const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildKpiCard(String title, String val, String subtitle, Color color) {
    return Expanded(
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
            Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            const SizedBox(height: 4),
            Text(
              val,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMaritimeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C2442), Color(0xFF111C38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0284C7).withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.directions_boat_rounded, color: Color(0xFF38BDF8), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Live AIS Vessel Telemetry',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AIS LIVE',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Vessel: CMA CGM Palais Royal (IMO: 9839179)\nCarrying: Cryogenic BOG Compressor Unit 01\nCurrent: Bay of Bengal Approaching Kolkata Port\nSpeed: 18.4 Knots | ETA: 12 Oct 2026 14:00 IST',
            style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 11, height: 1.4, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(SupplyChainPackage pkg, ProjectArchetype arch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Text(
                pkg.poNumber,
                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: pkg.bufferDays >= 0 ? const Color(0xFF10B981).withAlpha(20) : const Color(0xFFEF4444).withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  pkg.bufferDays >= 0 ? '+${pkg.bufferDays}d Float' : '${pkg.bufferDays}d DELAYED',
                  style: TextStyle(
                    color: pkg.bufferDays >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            pkg.description,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${pkg.vendor} • Origin: ${pkg.countryOfOrigin}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 10),

          // 5-Stage Stepper
          _buildStageStepper(pkg.stageIndex),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppTheme.textMuted, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    pkg.locationGeo,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  pkg.certificate,
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageStepper(int currentStage) {
    return Row(
      children: List.generate(_stages.length, (index) {
        final isDone = index <= currentStage;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3,
                      color: index == 0
                          ? Colors.transparent
                          : (index <= currentStage ? const Color(0xFF10B981) : AppTheme.border),
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isDone ? const Color(0xFF10B981) : AppTheme.surfaceCard,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDone ? const Color(0xFF10B981) : AppTheme.border,
                        width: 1.5,
                      ),
                    ),
                    child: isDone
                        ? const Center(
                            child: Icon(Icons.check, size: 9, color: Color(0xFF0B1326)),
                          )
                        : null,
                  ),
                  Expanded(
                    child: Container(
                      height: 3,
                      color: index == _stages.length - 1
                          ? Colors.transparent
                          : (index < currentStage ? const Color(0xFF10B981) : AppTheme.border),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _stages[index],
                style: TextStyle(
                  color: isDone ? AppTheme.textPrimary : AppTheme.textMuted,
                  fontSize: 8.5,
                  fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }
}
