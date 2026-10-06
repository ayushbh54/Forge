import 'package:flutter/material.dart';
import '../../core/models/authority_matrix.dart';

class AuthorityMatrixScreen extends StatefulWidget {
  const AuthorityMatrixScreen({super.key});

  @override
  State<AuthorityMatrixScreen> createState() => _AuthorityMatrixScreenState();
}

class _AuthorityMatrixScreenState extends State<AuthorityMatrixScreen> {
  String _selectedRoleCode = AuthorityMatrix.allRoles.first.roleCode;

  @override
  Widget build(BuildContext context) {
    final selectedRole = AuthorityMatrix.allRoles.firstWhere(
      (r) => r.roleCode == _selectedRoleCode,
      orElse: () => AuthorityMatrix.allRoles.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Department & Authority Matrix',
              style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Role-Based Access Control (RBAC) & Governance',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Top Explanatory Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF162347),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF26396E)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project Authority & Delegation Protocol',
                        style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Multi-department permissions determine what each user can view, create, approve, or edit under FIDIC Red/Yellow book guidelines.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Horizontal Role Selector Carousel
          const Text(
            'SELECT ROLE & DEPARTMENT',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AuthorityMatrix.allRoles.map((role) {
                final isSelected = role.roleCode == _selectedRoleCode;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(role.icon, size: 16, color: isSelected ? Colors.white : role.badgeColor),
                    label: Text(
                      role.roleTitle.split(' / ').first,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: role.badgeColor,
                    backgroundColor: const Color(0xFF162347),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedRoleCode = role.roleCode);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Role Profile & FIDIC Jurisdiction Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF162347),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selectedRole.badgeColor.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: selectedRole.badgeColor.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: selectedRole.badgeColor.withValues(alpha: 0.2),
                      child: Icon(selectedRole.icon, color: selectedRole.badgeColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedRole.roleTitle,
                            style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedRole.departmentName,
                            style: TextStyle(color: selectedRole.badgeColor, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF26396E), height: 1),
                const SizedBox(height: 14),

                // Jurisdictional Clauses & Limits
                Row(
                  children: [
                    Expanded(
                      child: _buildMetaPill(
                        'FIDIC Jurisdiction',
                        selectedRole.fidicJurisdiction,
                        Icons.gavel_rounded,
                        const Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetaPill(
                        'Financial Authority',
                        selectedRole.financialLimit,
                        Icons.payments_rounded,
                        const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1. WHAT IS VISIBLE (VIEW SCOPE)
          _buildAuthoritySection(
            title: '1. What is Visible (View Scope & Dashboards)',
            subtitle: 'Screens, analytical matrices & live telemetry accessible to this role',
            icon: Icons.visibility_rounded,
            color: const Color(0xFF38BDF8),
            items: selectedRole.viewScope,
          ),
          const SizedBox(height: 16),

          // 2. WHAT CAN BE CREATED (CREATE AUTHORITY)
          _buildAuthoritySection(
            title: '2. What Can Be Created (Creation Authority)',
            subtitle: 'Documents, shift DPRs, permits, and inspection records this role can author',
            icon: Icons.add_circle_outline_rounded,
            color: const Color(0xFF10B981),
            items: selectedRole.createAuthority,
          ),
          const SizedBox(height: 16),

          // 3. WHAT CAN BE APPROVED (SIGN-OFF & HOLD POINTS)
          _buildAuthoritySection(
            title: '3. What Can Be Approved (Sign-Off & Approvals)',
            subtitle: 'Mandatory hold points, invoices, and claims requiring this role\'s authorization',
            icon: Icons.verified_user_rounded,
            color: const Color(0xFFFFB95F),
            items: selectedRole.approveAuthority,
          ),
          const SizedBox(height: 16),

          // 4. WHAT CAN BE EDITED (CHANGE AUTHORITY)
          _buildAuthoritySection(
            title: '4. What Can Be Edited (Modification Limits)',
            subtitle: 'Allowable adjustments to prevent unrecorded data tampering',
            icon: Icons.edit_note_rounded,
            color: const Color(0xFFA855F7),
            items: selectedRole.editAuthority,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMetaPill(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1326),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF26396E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 11, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthoritySection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF26396E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 13, color: color),
                    const SizedBox(width: 6),
                    Text(
                      item.replaceAll('_', ' '),
                      style: TextStyle(
                        color: const Color(0xFFF1F5F9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
