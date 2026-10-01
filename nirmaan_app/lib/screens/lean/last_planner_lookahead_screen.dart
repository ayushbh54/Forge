import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/taxonomy/archetype_controller.dart';
import '../../core/taxonomy/project_archetype.dart';

class LeanTaskConstraint {
  final String name;
  final String code;
  bool isCleared;
  final String details;
  final IconData icon;

  LeanTaskConstraint({
    required this.name,
    required this.code,
    required this.isCleared,
    required this.details,
    required this.icon,
  });
}

class LeanLookaheadTask {
  final String id;
  final String title;
  final String wbsCode;
  final String trade;
  final String chainageOrLocation;
  final int weekNumber; // 1, 2, or 3
  final double plannedQuantity;
  final String unit;
  final List<LeanTaskConstraint> constraints;

  LeanLookaheadTask({
    required this.id,
    required this.title,
    required this.wbsCode,
    required this.trade,
    required this.chainageOrLocation,
    required this.weekNumber,
    required this.plannedQuantity,
    required this.unit,
    required this.constraints,
  });

  bool get isReadyForDailyWorkPlan => constraints.every((c) => c.isCleared);
  int get clearedCount => constraints.where((c) => c.isCleared).length;
}

class LastPlannerLookaheadScreen extends StatefulWidget {
  const LastPlannerLookaheadScreen({super.key});

  @override
  State<LastPlannerLookaheadScreen> createState() => _LastPlannerLookaheadScreenState();
}

class _LastPlannerLookaheadScreenState extends State<LastPlannerLookaheadScreen> {
  int _selectedWeek = 1;

  late List<LeanLookaheadTask> _tasks;

  @override
  void initState() {
    super.initState();
    _initTasks();
  }

  void _initTasks() {
    _tasks = [
      LeanLookaheadTask(
        id: 'LPS-101',
        title: 'Pipe Stringing & Pre-Bend Welding',
        wbsCode: 'WBS 1.4.2.1',
        trade: 'Mechanical Piping',
        chainageOrLocation: 'KM 142.8 - KM 144.2',
        weekNumber: 1,
        plannedQuantity: 1.4,
        unit: 'KM',
        constraints: [
          LeanTaskConstraint(name: 'Drawings (AFC)', code: 'DWG', isCleared: true, details: 'AFC Rev 4 approved by EIL', icon: Icons.architecture_rounded),
          LeanTaskConstraint(name: 'Materials (Heat QC)', code: 'MAT', isCleared: true, details: '142 API 5L X70 pipes cleared in yard', icon: Icons.inventory_2_rounded),
          LeanTaskConstraint(name: 'Equipment (Sideboom)', code: 'EQP', isCleared: true, details: 'Komatsu D355C load test certified', icon: Icons.precision_manufacturing_rounded),
          LeanTaskConstraint(name: 'Manpower (Welders)', code: 'MAN', isCleared: true, details: '18 6G welders biometric geofenced', icon: Icons.groups_rounded),
          LeanTaskConstraint(name: 'Predecessors (Trench)', code: 'PRE', isCleared: true, details: 'Trench bed dewatered & sand padded', icon: Icons.alt_route_rounded),
          LeanTaskConstraint(name: 'Safety (PTW Hot Work)', code: 'SAF', isCleared: true, details: 'Permit #PTW-8422 active (0% LEL)', icon: Icons.health_and_safety_rounded),
        ],
      ),
      LeanLookaheadTask(
        id: 'LPS-102',
        title: 'Mainline Automatic Ultrasonic Testing (AUT)',
        wbsCode: 'WBS 1.4.3.0',
        trade: 'NDT Quality QA/QC',
        chainageOrLocation: 'Joint #1380 to #1420',
        weekNumber: 1,
        plannedQuantity: 40,
        unit: 'Joints',
        constraints: [
          LeanTaskConstraint(name: 'Drawings (AFC)', code: 'DWG', isCleared: true, details: 'WPS-OIL-09 certified', icon: Icons.architecture_rounded),
          LeanTaskConstraint(name: 'Materials (Couplant)', code: 'MAT', isCleared: true, details: 'High-temp acoustic gel available', icon: Icons.inventory_2_rounded),
          LeanTaskConstraint(name: 'Equipment (AUT Rig)', code: 'EQP', isCleared: true, details: 'Olympus PipeWizard calibration valid', icon: Icons.precision_manufacturing_rounded),
          LeanTaskConstraint(name: 'Manpower (Level III)', code: 'MAN', isCleared: true, details: 'ASNT Level III inspector on site', icon: Icons.groups_rounded),
          LeanTaskConstraint(name: 'Predecessors (Root Weld)', code: 'PRE', isCleared: true, details: 'Capping pass cooled to 100°C', icon: Icons.alt_route_rounded),
          LeanTaskConstraint(name: 'Safety (PTW)', code: 'SAF', isCleared: true, details: 'General permit active', icon: Icons.health_and_safety_rounded),
        ],
      ),
      LeanLookaheadTask(
        id: 'LPS-201',
        title: 'Field Joint Coating (Heat Shrink Sleeves)',
        wbsCode: 'WBS 1.4.4.2',
        trade: 'Corrosion Protection',
        chainageOrLocation: 'KM 144.0 - KM 146.5',
        weekNumber: 2,
        plannedQuantity: 2.5,
        unit: 'KM',
        constraints: [
          LeanTaskConstraint(name: 'Drawings (AFC)', code: 'DWG', isCleared: true, details: 'NACE SP0169 spec sheet signed', icon: Icons.architecture_rounded),
          LeanTaskConstraint(name: 'Materials (Canusa HSS)', code: 'MAT', isCleared: true, details: 'Sleeves in central warehouse', icon: Icons.inventory_2_rounded),
          LeanTaskConstraint(name: 'Equipment (Induction Coil)', code: 'EQP', isCleared: false, details: 'Induction heater generator awaiting diesel delivery', icon: Icons.precision_manufacturing_rounded),
          LeanTaskConstraint(name: 'Manpower (Coaters)', code: 'MAN', isCleared: true, details: 'Certified applicators scheduled', icon: Icons.groups_rounded),
          LeanTaskConstraint(name: 'Predecessors (AUT NDT)', code: 'PRE', isCleared: true, details: 'Welds cleared without repairs', icon: Icons.alt_route_rounded),
          LeanTaskConstraint(name: 'Safety (PPE Check)', code: 'SAF', isCleared: true, details: 'Thermal glove inspection scheduled', icon: Icons.health_and_safety_rounded),
        ],
      ),
      LeanLookaheadTask(
        id: 'LPS-202',
        title: 'HDD River Crossing Pilot Hole Drilling',
        wbsCode: 'WBS 1.5.1.0',
        trade: 'Trenchless Drilling',
        chainageOrLocation: 'Brahmaputra Bank (CH 146+200)',
        weekNumber: 2,
        plannedQuantity: 620,
        unit: 'Meters',
        constraints: [
          LeanTaskConstraint(name: 'Drawings (AFC)', code: 'DWG', isCleared: true, details: 'Bore profile Rev 3 approved', icon: Icons.architecture_rounded),
          LeanTaskConstraint(name: 'Materials (Bentonite)', code: 'MAT', isCleared: true, details: '35 metric tons drilling mud on pad', icon: Icons.inventory_2_rounded),
          LeanTaskConstraint(name: 'Equipment (250t Rig)', code: 'EQP', isCleared: true, details: 'American Augers DD-220 rigged up', icon: Icons.precision_manufacturing_rounded),
          LeanTaskConstraint(name: 'Manpower (Drill Crew)', code: 'MAN', isCleared: false, details: 'Specialized mud engineer arriving tomorrow', icon: Icons.groups_rounded),
          LeanTaskConstraint(name: 'Predecessors (Entry Pit)', code: 'PRE', isCleared: true, details: 'Containment bund concrete cast', icon: Icons.alt_route_rounded),
          LeanTaskConstraint(name: 'Safety (Pollution Spill)', code: 'SAF', isCleared: true, details: 'Silt curtain in river placed', icon: Icons.health_and_safety_rounded),
        ],
      ),
      LeanLookaheadTask(
        id: 'LPS-301',
        title: 'Hydrostatic Pressure Test & Section Dewatering',
        wbsCode: 'WBS 1.6.0.0',
        trade: 'Commissioning',
        chainageOrLocation: 'Section-04 (KM 120 - KM 150)',
        weekNumber: 3,
        plannedQuantity: 30.0,
        unit: 'KM',
        constraints: [
          LeanTaskConstraint(name: 'Drawings (P&ID)', code: 'DWG', isCleared: true, details: 'Hydrotest manifold diagram verified', icon: Icons.architecture_rounded),
          LeanTaskConstraint(name: 'Materials (Test Water)', code: 'MAT', isCleared: false, details: 'Water extraction NOC pending from state PCB', icon: Icons.inventory_2_rounded),
          LeanTaskConstraint(name: 'Equipment (Pumps)', code: 'EQP', isCleared: false, details: '150 bar triplex injection pump in transit from Mumbai', icon: Icons.precision_manufacturing_rounded),
          LeanTaskConstraint(name: 'Manpower (Engineers)', code: 'MAN', isCleared: true, details: 'Commissioning team assigned', icon: Icons.groups_rounded),
          LeanTaskConstraint(name: 'Predecessors (Tie-ins)', code: 'PRE', isCleared: false, details: 'Golden weld #1480 still pending', icon: Icons.alt_route_rounded),
          LeanTaskConstraint(name: 'Safety (Barricades)', code: 'SAF', isCleared: true, details: 'Danger zone warning sirens tested', icon: Icons.health_and_safety_rounded),
        ],
      ),
    ];
  }

  void _toggleConstraint(LeanLookaheadTask task, LeanTaskConstraint constraint) {
    setState(() {
      constraint.isCleared = !constraint.isCleared;
    });
  }

  @override
  Widget build(BuildContext context) {
    final arch = ArchetypeController.instance.current;
    final filteredTasks = _tasks.where((t) => t.weekNumber == _selectedWeek).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lean Last Planner (LPS)',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '3-Week Lookahead & 6-Constraint Gate • ${arch.shortName}',
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
            // PPC Performance Overview Card
            _buildPpcOverviewCard(arch),
            const SizedBox(height: 16),

            // Week Horizon Switcher
            _buildWeekSwitcher(),
            const SizedBox(height: 16),

            // 6-Gate Constraint Legend
            _buildGateLegend(),
            const SizedBox(height: 16),

            // Tasks List
            ...filteredTasks.map((task) => _buildTaskCard(task, arch)),
            if (filteredTasks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No activities scheduled in this lookahead window.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPpcOverviewCard(ProjectArchetype arch) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.show_chart_rounded, color: Color(0xFF10B981), size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'PERCENT PLAN COMPLETE (PPC)',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
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
                  color: const Color(0xFF10B981).withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
                ),
                child: const Text(
                  'HIGH RELIABILITY',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: const [
              Text(
                '94.2%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Weekly Commitments Delivered',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Lean Construction Rule: A task cannot enter the Daily Work Plan unless all 6 constraints (Drawings, Materials, Equipment, Manpower, Predecessors, Safety) are 100% cleared.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSwitcher() {
    return Row(
      children: [
        _buildWeekButton(1, 'Week 1 (Commitments)'),
        const SizedBox(width: 8),
        _buildWeekButton(2, 'Week 2 (Lookahead)'),
        const SizedBox(width: 8),
        _buildWeekButton(3, 'Week 3 (Forecast)'),
      ],
    );
  }

  Widget _buildWeekButton(int week, String label) {
    final isSelected = _selectedWeek == week;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedWeek = week),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primaryLight : AppTheme.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGateLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text('6-Constraint Clearance Gate:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5, fontWeight: FontWeight.bold)),
          Text('🟢 Cleared  🔴 Blocked', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(LeanLookaheadTask task, ProjectArchetype arch) {
    final isReady = task.isReadyForDailyWorkPlan;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReady ? const Color(0xFF10B981).withAlpha(120) : AppTheme.border,
          width: isReady ? 1.5 : 1,
        ),
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
                  task.wbsCode,
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isReady ? const Color(0xFF10B981) : const Color(0xFFEF4444).withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isReady ? 'READY TO EXECUTE' : '${task.clearedCount}/6 CLEARED',
                  style: TextStyle(
                    color: isReady ? const Color(0xFF0B1326) : const Color(0xFFEF4444),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${task.trade} • ${task.chainageOrLocation} • Scope: ${task.plannedQuantity} ${task.unit}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 8),
          const Text(
            'Tap constraint to toggle field readiness status:',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
          ),
          const SizedBox(height: 6),
          // 6 Constraint Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: task.constraints.map((c) {
              return InkWell(
                onTap: () => _toggleConstraint(task, c),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.isCleared ? const Color(0xFF10B981).withAlpha(20) : const Color(0xFFEF4444).withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: c.isCleared ? const Color(0xFF10B981).withAlpha(80) : const Color(0xFFEF4444).withAlpha(80),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        c.isCleared ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: c.isCleared ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        c.name,
                        style: TextStyle(
                          color: c.isCleared ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
}
