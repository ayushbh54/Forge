import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/taxonomy/archetype_controller.dart';
import '../../core/taxonomy/project_archetype.dart';

class IfcElement {
  final String guid;
  final String name;
  final String ifcClass;
  final String wbsActivity;
  final String status;
  final Color statusColor;
  final String material;
  final String volumeOrLength;

  const IfcElement({
    required this.guid,
    required this.name,
    required this.ifcClass,
    required this.wbsActivity,
    required this.status,
    required this.statusColor,
    required this.material,
    required this.volumeOrLength,
  });
}

class Bim4dViewerScreen extends StatefulWidget {
  const Bim4dViewerScreen({super.key});

  @override
  State<Bim4dViewerScreen> createState() => _Bim4dViewerScreenState();
}

class _Bim4dViewerScreenState extends State<Bim4dViewerScreen> {
  double _timelineSlider = 0.75; // 75% project timeline
  IfcElement? _selectedElement;

  final List<IfcElement> _elements = const [
    IfcElement(
      guid: 'IFC-GUID-3mK9x8aH2kL0pQ1rT',
      name: 'Cryogenic 9% Ni Tank Shell TK-04',
      ifcClass: 'IfcTank',
      wbsActivity: 'ACT-041 (Tank Erection)',
      status: 'VERIFIED COMPLETE',
      statusColor: Color(0xFF10B981),
      material: 'ASTM A553 Type 1 (9% Nickel Steel)',
      volumeOrLength: '180,000 m³ Capacity',
    ),
    IfcElement(
      guid: 'IFC-GUID-7bN2w9jP4xM1kL3sV',
      name: 'Main Boil-Off Gas (BOG) Compressor Skids',
      ifcClass: 'IfcCompressor',
      wbsActivity: 'ACT-052 (Compressor Train)',
      status: 'IN PROGRESS (85%)',
      statusColor: Color(0xFFF59E0B),
      material: 'Forged Duplex Stainless Steel UNS S31803',
      volumeOrLength: '3 × 12 MW Centrifugal',
    ),
    IfcElement(
      guid: 'IFC-GUID-1cR8v4dF7hJ2mN9kP',
      name: '24" High-Pressure Cryogenic Export Spool #CS-042',
      ifcClass: 'IfcPipeSegment',
      wbsActivity: 'ACT-064 (Jetty Cryo Line)',
      status: 'VERIFIED COMPLETE',
      statusColor: Color(0xFF10B981),
      material: 'ASTM A312 TP316L (-162°C)',
      volumeOrLength: '142.5 Meters',
    ),
    IfcElement(
      guid: 'IFC-GUID-9xL4m2kP8vD1bN6hQ',
      name: 'High-Voltage 220kV GIS Switchgear Bay B-02',
      ifcClass: 'IfcSwitchingDevice',
      wbsActivity: 'ACT-078 (GIS Energization)',
      status: 'CRITICAL PATH DELAY (+3d)',
      statusColor: Color(0xFFEF4444),
      material: 'SF6 Gas Insulated Aluminum Enclosure',
      volumeOrLength: '8 Feeders / 40kA',
    ),
    IfcElement(
      guid: 'IFC-GUID-5kM1q8bN4xF2mP9hT',
      name: 'Marine Jetty Loading Arm 16" Swivel Joint',
      ifcClass: 'IfcMechanicalFastener',
      wbsActivity: 'ACT-092 (Berth Commissioning)',
      status: 'UNSTARTED FUTURE',
      statusColor: Color(0xFF94A3B8),
      material: 'Inconel 625 Overlay',
      volumeOrLength: '4 × Loading Arms',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedElement = _elements.first;
  }

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
              'Open-BIM 4D/5D Digital Twin',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'IFC.js WebGL Engine • ${arch.shortName}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(20),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
            ),
            child: const Center(
              child: Text(
                '0 CLASHES',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 3D Canvas Mockup & Interactive Shading View
          _build3dCanvasArea(arch),

          // 4D Time Scrubbing Controller
          _buildTimelineScrubber(),

          // IFC Component Detail & Inspection Card
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_selectedElement != null) _buildElementDetailCard(_selectedElement!),
                const SizedBox(height: 16),
                _buildElementsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3dCanvasArea(ProjectArchetype arch) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF070D1E),
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Stack(
        children: [
          // 3D Grid Overlay lines
          Positioned.fill(
            child: CustomPaint(
              painter: _IsometricGridPainter(),
            ),
          ),
          // Central 3D Model Isometric Simulation
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: arch.accentColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: arch.accentColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: arch.accentColor.withAlpha(40),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.view_in_ar_rounded,
                    color: arch.accentColor,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withAlpha(200),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    'IFC 4D Mesh: ${_selectedElement?.name ?? "Model Active"}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating Camera View Tools
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surface.withAlpha(220),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: const [
                  Icon(Icons.threed_rotation_rounded, color: Color(0xFF38BDF8), size: 16),
                  SizedBox(width: 4),
                  Text(
                    'ORBIT 360°',
                    style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          // Shading Color Legend
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surface.withAlpha(220),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _LegendDot(color: Color(0xFF10B981), label: 'Done'),
                  SizedBox(width: 8),
                  _LegendDot(color: Color(0xFFF59E0B), label: 'Active'),
                  SizedBox(width: 8),
                  _LegendDot(color: Color(0xFFEF4444), label: 'Delay'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineScrubber() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '4D Construction Timeline Scrubbing',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Month ${(_timelineSlider * 24).toInt()} of 24 (75% Baseline)',
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF0284C7),
              inactiveTrackColor: AppTheme.surfaceCard,
              thumbColor: const Color(0xFF38BDF8),
              trackHeight: 4,
            ),
            child: Slider(
              value: _timelineSlider,
              onChanged: (val) => setState(() => _timelineSlider = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementDetailCard(IfcElement el) {
    return Container(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  el.ifcClass,
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: el.statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: el.statusColor.withAlpha(80)),
                ),
                child: Text(
                  el.status,
                  style: TextStyle(color: el.statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            el.name,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'IFC GUID: ${el.guid}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 10),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildProp('P6 Task', el.wbsActivity),
              _buildProp('Material', el.material),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildProp('Capacity / Size', el.volumeOrLength),
              _buildProp('Truth Engine', '99.4% Verified'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProp(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildElementsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'IFC Structural Components Tree',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._elements.map((el) {
          final isSelected = el.guid == _selectedElement?.guid;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary.withAlpha(20) : AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? AppTheme.primaryLight : AppTheme.border),
            ),
            child: ListTile(
              dense: true,
              leading: Icon(Icons.token_rounded, color: el.statusColor, size: 20),
              title: Text(
                el.name,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryLight : AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${el.ifcClass} • ${el.wbsActivity}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
              ),
              trailing: Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? AppTheme.primaryLight : AppTheme.textMuted,
                size: 16,
              ),
              onTap: () => setState(() => _selectedElement = el),
            ),
          );
        }),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5)),
      ],
    );
  }
}

class _IsometricGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2E5C).withAlpha(60)
      ..strokeWidth = 0.8;

    const step = 24.0;
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
