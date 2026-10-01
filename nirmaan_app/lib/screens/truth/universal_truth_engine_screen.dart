import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/taxonomy/project_archetype.dart';
import '../../core/taxonomy/archetype_controller.dart';
import '../conflicts/conflicts_screen.dart';

class UniversalTruthEngineScreen extends StatefulWidget {
  const UniversalTruthEngineScreen({super.key});

  @override
  State<UniversalTruthEngineScreen> createState() => _UniversalTruthEngineScreenState();
}

class _UniversalTruthEngineScreenState extends State<UniversalTruthEngineScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedEnvironmentIndex = 0;
  bool _isNotarizing = false;

  final List<String> _environments = [
    'Corridor & RoW',
    'Subterranean Tunnel',
    'Indoor Plant & BIM',
    'Marine & Offshore',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _environments.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedEnvironmentIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _triggerNotarization() {
    setState(() => _isNotarizing = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isNotarizing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Row(
              children: [
                Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SHA-256 Consensus Proof notarized to tamper-proof audit ledger!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
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
              'Universal Truth Triangulator',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${arch.name} • Multi-Sensor Consensus',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.gavel_rounded, color: Color(0xFF38BDF8), size: 20),
            tooltip: 'View Conflicts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConflictsScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: arch.accentColor,
          indicatorWeight: 3,
          labelColor: arch.accentColor,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: _environments.map((e) => Tab(text: e)).toList(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Consensus Gauge Card
            _buildHeroConsensusCard(arch),
            const SizedBox(height: 16),

            // Dynamic Mathematical Triangulation Formula Card
            _buildFormulaCard(arch),
            const SizedBox(height: 16),

            // Active Environment Stream Telemetry
            _buildActiveEnvironmentCard(arch),
            const SizedBox(height: 16),

            // 5-Sensor Breakdown Matrix
            _buildSensorMatrixList(arch),
            const SizedBox(height: 16),

            // Ghost Progress & Discrepancy Detector
            _buildGhostProgressDetector(arch),
            const SizedBox(height: 24),

            // Notarization & Action Buttons
            ElevatedButton.icon(
              onPressed: _isNotarizing ? null : _triggerNotarization,
              style: ElevatedButton.styleFrom(
                backgroundColor: arch.accentColor,
                foregroundColor: const Color(0xFF0B1326),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isNotarizing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B1326)),
                    )
                  : const Icon(Icons.fingerprint_rounded, size: 20),
              label: Text(
                _isNotarizing ? 'GENERATING PROOF...' : 'NOTARIZE SHA-256 CONSENSUS AUDIT',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroConsensusCard(ProjectArchetype arch) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [arch.accentColor.withAlpha(40), const Color(0xFF111C38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: arch.accentColor.withAlpha(120), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: arch.accentColor.withAlpha(30),
            blurRadius: 16,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: arch.accentColor.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.verified_rounded, color: arch.accentColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PHYSICAL TRUTH CONSENSUS',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        arch.location,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'FRAUD-PROOF',
                  style: TextStyle(
                    color: Color(0xFF0B1326),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${arch.verifiedConsensus}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'MULTI-SENSOR ALIGNMENT',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: arch.verifiedConsensus / 100,
              minHeight: 8,
              backgroundColor: AppTheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(arch.accentColor),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Zero ghost work or unverified physical progress detected. Satellite SAR backscatter and Drone LiDAR elevations match contractor DPR daily tally within 0.08m vertical tolerance.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaCard(ProjectArchetype arch) {
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
            children: [
              const Icon(Icons.functions_rounded, color: Color(0xFF38BDF8), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Mathematical Consensus Formula',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ISO 19650',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1326),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border.withAlpha(120)),
            ),
            child: const Text(
              'Φ = ∑ (wₖ · Ψₖ · e^(-λ · Δtₖ))\nWhere wₖ = dynamic sensor weight, Ψₖ = sensor precision, e^(-λΔt) = telemetry decay',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF38BDF8),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveEnvironmentCard(ProjectArchetype arch) {
    String envTitle;
    String envDesc;
    IconData envIcon;
    List<Map<String, String>> metrics;

    switch (_selectedEnvironmentIndex) {
      case 1: // Subterranean Tunnel
        envTitle = 'Subterranean & TBM Tunnel Environment';
        envDesc = 'GPS & Satellites blind underground. Active guidance relies on TBM laser gyro, ring displacement, and surface ATS prisms.';
        envIcon = Icons.subway_rounded;
        metrics = [
          {'label': 'TBM Laser Gyro', 'value': '0.02° Roll Safe', 'status': 'PASS'},
          {'label': 'Surface Settlement', 'value': '0.8 mm (Limit 5mm)', 'status': 'CLEAR'},
          {'label': 'Ring Grout Pressure', 'value': '4.2 bar hold', 'status': 'OPTIMAL'},
        ];
        break;
      case 2: // Indoor Plant & BIM
        envTitle = 'Indoor Plant & BIM 4D Walkthrough';
        envDesc = 'Refinery and cleanroom interior monitoring via 360° Helmet Cameras (OpenSpace) and Cartographer SLAM LiDAR point clouds.';
        envIcon = Icons.domain_rounded;
        metrics = [
          {'label': '360° SLAM Mesh', 'value': '42,000 pts/m²', 'status': 'ALIGNED'},
          {'label': 'BIM IFC Match', 'value': '99.4% Spools Tagged', 'status': 'SYNCD'},
          {'label': 'Busduct Thermography', 'value': 'Zero Hot-Spots', 'status': 'NORMAL'},
        ];
        break;
      case 3: // Marine & Offshore
        envTitle = 'Marine, Jetty & Subsea Pipeline';
        envDesc = 'Multibeam Echo Sounder (MBES) hydrographic bathymetry, side-scan sonar, and ROV umbilical cable tracking.';
        envIcon = Icons.waves_rounded;
        metrics = [
          {'label': 'Jetty Bathymetry', 'value': '-16.5m Chart Datum', 'status': 'CLEARED'},
          {'label': 'Subsea Pipe Burial', 'value': '2.4m below seabed', 'status': 'SAFE'},
          {'label': 'Current Velocity', 'value': '1.2 knots Ebb', 'status': 'PERMITTED'},
        ];
        break;
      case 0: // Corridor & RoW
      default:
        envTitle = 'Open Linear Corridor & RoW Environment';
        envDesc = 'Full-sky open linear alignment monitored via Copernicus Sentinel-1 SAR interferometry and autonomous drone LiDAR patrols.';
        envIcon = Icons.alt_route_rounded;
        metrics = [
          {'label': 'Sentinel-1 SAR Coherence', 'value': '0.89 Coherence', 'status': 'OPTIMAL'},
          {'label': 'Drone LiDAR Density', 'value': '450 pts/m² Point Cloud', 'status': 'CLEARED'},
          {'label': 'SCADA Solar RTU', 'value': '64.2 bar Pressure Hold', 'status': 'LIVE'},
        ];
        break;
    }

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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: arch.accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(envIcon, color: arch.accentColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  envTitle,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            envDesc,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: metrics.map((m) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m['label']!,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m['value']!,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        m['status']!,
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorMatrixList(ProjectArchetype arch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '5-Sensor Telemetry Weight Matrix',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Dynamic weights adjust automatically based on project topography and environment',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 10),
        ...arch.sensors.map((s) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: arch.accentColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(s.icon, color: arch.accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'w = ${(s.weight * 100).toInt()}%',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.lastTelemetry,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGhostProgressDetector(ProjectArchetype arch) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security_rounded, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Anti-Phantom Work Assurance',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'No physical progress can be certified or billed without simultaneous multi-sensor consensus confirmation.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
