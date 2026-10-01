import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/taxonomy/archetype_controller.dart';
import '../../core/taxonomy/project_archetype.dart';

class FidicClaimEvent {
  final String id;
  final String title;
  final String fidicClause;
  final String criticalPathTask;
  final int daysRequested;
  final double financialExposureMitigated;
  final int daysLeftInNoticeWindow;
  final String weatherProof;
  final String status;
  final Color statusColor;

  const FidicClaimEvent({
    required this.id,
    required this.title,
    required this.fidicClause,
    required this.criticalPathTask,
    required this.daysRequested,
    required this.financialExposureMitigated,
    required this.daysLeftInNoticeWindow,
    required this.weatherProof,
    required this.status,
    required this.statusColor,
  });
}

class FidicClaimShieldScreen extends StatefulWidget {
  const FidicClaimShieldScreen({super.key});

  @override
  State<FidicClaimShieldScreen> createState() => _FidicClaimShieldScreenState();
}

class _FidicClaimShieldScreenState extends State<FidicClaimShieldScreen> {
  final List<FidicClaimEvent> _events = const [
    FidicClaimEvent(
      id: 'CLM-2026-084',
      title: 'Unprecedented Monsoon Flooding along RoW KM 142.8',
      fidicClause: 'FIDIC Cl. 8.4(b) / 20.1 (Exceptionally Adverse Climatic Conditions)',
      criticalPathTask: 'ACT-042 (Stringing, Welding & Trench Lowering)',
      daysRequested: 14,
      financialExposureMitigated: 24500000.0, // ₹ 2.45 Cr
      daysLeftInNoticeWindow: 12,
      weatherProof: 'IMD AWS Station 148mm/24h (1-in-10 Year Return Event)',
      status: 'NOTICE SERVED',
      statusColor: Color(0xFF10B981),
    ),
    FidicClaimEvent(
      id: 'CLM-2026-085',
      title: 'Delayed Access to Brahmaputra River Crossing Pad B',
      fidicClause: 'FIDIC Cl. 2.1 (Right of Access to the Site)',
      criticalPathTask: 'ACT-058 (HDD Pull-Back 36" Pipe)',
      daysRequested: 21,
      financialExposureMitigated: 41000000.0, // ₹ 4.10 Cr
      daysLeftInNoticeWindow: 19,
      weatherProof: 'District Revenue Forest Dept Clearance Delay Logged',
      status: 'UNDER ADJUDICATION',
      statusColor: Color(0xFFF59E0B),
    ),
    FidicClaimEvent(
      id: 'CLM-2026-086',
      title: 'Subsurface Boulder Strata Variance in HDD Pilot Bore',
      fidicClause: 'FIDIC Cl. 4.12 (Unforeseeable Physical Conditions)',
      criticalPathTask: 'ACT-062 (Mud Motor Reaming Phase 2)',
      daysRequested: 8,
      financialExposureMitigated: 18500000.0, // ₹ 1.85 Cr
      daysLeftInNoticeWindow: 4, // Critical countdown
      weatherProof: 'Geotechnical Soil Core Log Boring Rig vs Contract DPR',
      status: 'DRAFTING CLAIM',
      statusColor: Color(0xFFEF4444),
    ),
  ];

  void _showNoticeModal(FidicClaimEvent ev) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(ev.id, style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: ev.statusColor.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                    child: Text(ev.status, style: TextStyle(color: ev.statusColor, fontSize: 9.5, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(ev.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Governing Provision: ${ev.fidicClause}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF0B1326), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FORMAL NOTICE EXCERPT:', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '"Pursuant to Clause 8.4 and Clause 20.1 of the General Conditions of Contract, Contractor hereby gives formal notice of a Delay Event affecting critical path task ${ev.criticalPathTask}. Attached are Copernicus SAR radar inundation maps and IMD rainfall telemetry."',
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11, fontStyle: FontStyle.italic, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.primary,
                        content: Text('Notice PDF for ${ev.id} exported with SHA-256 timestamp.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('DOWNLOAD NOTARIZED COURT-READY PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
              'FIDIC & NEC4 Dispute Shield',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Automated EoT Claim Defense • ${arch.shortName}',
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
            // Hero Financial Protection Card
            _buildExposureMitigatedCard(),
            const SizedBox(height: 16),

            // Time-Bar Warning Banner
            _buildTimeBarWarningBanner(),
            const SizedBox(height: 16),

            // Claims List
            const Text(
              'Active Contractual Delay & EoT Claims',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._events.map((ev) => _buildClaimCard(ev)),
          ],
        ),
      ),
    );
  }

  Widget _buildExposureMitigatedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2B48), Color(0xFF111C38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0284C7).withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'LIQUIDATED DAMAGES MITIGATED',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(4)),
                child: const Text('PROTECTED', style: TextStyle(color: Color(0xFF0B1326), fontSize: 9.5, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '₹ 8.40 Cr',
            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            '43 Days Total Extension of Time (EoT) justified with contemporaneous satellite radar & IMD weather telemetry.',
            style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 11, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBarWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF4444).withAlpha(80)),
      ),
      child: Row(
        children: const [
          Icon(Icons.timer_rounded, color: Color(0xFFEF4444), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'FIDIC Cl. 20.1 Strict Rule: Notice must be served within 28 days of event occurrence. 1 claim has 4 days remaining before time-bar forfeiture!',
              style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w600, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimCard(FidicClaimEvent ev) {
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
              Text(ev.id, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: ev.statusColor.withAlpha(20), borderRadius: BorderRadius.circular(4)),
                child: Text(
                  '${ev.daysLeftInNoticeWindow}d Notice Window',
                  style: TextStyle(color: ev.statusColor, fontSize: 9.5, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(ev.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(ev.fidicClause, style: const TextStyle(color: Color(0xFFFFB95F), fontSize: 10.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(6)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Impacted: ${ev.criticalPathTask}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5)),
                    Text('+${ev.daysRequested} Days EoT', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Proof: ${ev.weatherProof}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showNoticeModal(ev),
              icon: const Icon(Icons.gavel_rounded, size: 14),
              label: const Text('INSPECT CLAIM & NOTICE LETTER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF38BDF8),
                side: const BorderSide(color: Color(0xFF38BDF8)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
