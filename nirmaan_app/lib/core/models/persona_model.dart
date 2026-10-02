import 'package:flutter/material.dart';

class PersonaModel {
  final String id;
  final String name;
  final String role;
  final String category; // 'ADMIN', 'STAFF', 'SPECIALIST', 'LABOUR'
  final String department;
  final String fidicRole;
  final String email;
  final Color accentColor;
  final IconData icon;
  final List<String> highlights;

  const PersonaModel({
    required this.id,
    required this.name,
    required this.role,
    required this.category,
    required this.department,
    required this.fidicRole,
    required this.email,
    required this.accentColor,
    required this.icon,
    required this.highlights,
  });

  Map<String, dynamic> toUserData() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'category': category,
      'department': department,
      'fidicRole': fidicRole,
      'projectId': 'PRJ-OIL-2026',
    };
  }
}

const List<PersonaModel> kAllPersonas = [
  // 1. ADMIN & EXECUTIVE LEADERSHIP
  PersonaModel(
    id: 'USR-DIR-01',
    name: 'Marcus Vance, P.E.',
    role: 'Project Director',
    category: 'ADMIN',
    department: 'Project Controls & Governance',
    fidicRole: "Engineer's Representative (FIDIC 3.1)",
    email: 'm.vance@oil.in',
    accentColor: Color(0xFFFFB95F),
    icon: Icons.analytics_rounded,
    highlights: ['EVM S-Curves (SPI/CPI)', 'FIDIC Delay Claim Shield', 'Capex Governance'],
  ),

  // 2. SITE STAFF POSTS (Engineering & Supervision)
  PersonaModel(
    id: 'USR-SUP-02',
    name: 'Vikram Joshi',
    role: 'Site Piping Supervisor',
    category: 'STAFF',
    department: 'Piping & Pipeline Engineering',
    fidicRole: 'Section In-Charge (Site Ops)',
    email: 'v.joshi@oil.in',
    accentColor: Color(0xFF38BDF8),
    icon: Icons.engineering_rounded,
    highlights: ['Voice DPR (Hindi/English)', 'Crew & Gang Allocation', 'Pipe Lower-in Progress'],
  ),
  PersonaModel(
    id: 'USR-PLN-03',
    name: 'Ananya Sen',
    role: 'Planning & Controls Engineer',
    category: 'STAFF',
    department: 'Project Controls & Planning',
    fidicRole: 'Scheduler & Delay Analyst',
    email: 'a.sen@oil.in',
    accentColor: Color(0xFF818CF8),
    icon: Icons.calendar_month_rounded,
    highlights: ['Primavera P6 WBS L1-L6', 'Critical Path Floats', 'Baseline Variance'],
  ),

  // 3. SPECIALIST STAFF POSTS (Quality, Safety & Stores)
  PersonaModel(
    id: 'USR-QA-04',
    name: 'R. K. Sharma',
    role: 'QA/QC Lead Inspector',
    category: 'SPECIALIST',
    department: 'Quality Assurance & Inspection',
    fidicRole: 'Quality Assurance Inspector',
    email: 'rk.sharma@oil.in',
    accentColor: Color(0xFF10B981),
    icon: Icons.fact_check_rounded,
    highlights: ['AUT Phased Array NDT', 'Golden Weld Approvals', 'ASTM Concrete Breaks'],
  ),
  PersonaModel(
    id: 'USR-HSE-05',
    name: 'Kavita Nair',
    role: 'HSE & Safety Lead',
    category: 'SPECIALIST',
    department: 'Health, Safety & Environment (HSE)',
    fidicRole: 'Safety Compliance Officer',
    email: 'k.nair@oil.in',
    accentColor: Color(0xFFF43F5E),
    icon: Icons.health_and_safety_rounded,
    highlights: ['Permits-to-Work (PTW)', 'Atmospheric Gas Alarms', 'Zero-Harm Audits'],
  ),
  PersonaModel(
    id: 'USR-MAT-06',
    name: 'Pranab Deka',
    role: 'Stores & Materials Manager',
    category: 'SPECIALIST',
    department: 'Stores & Supply Chain Management',
    fidicRole: 'Materials Controller',
    email: 'p.deka@oil.in',
    accentColor: Color(0xFFA855F7),
    icon: Icons.inventory_2_rounded,
    highlights: ['Heat Number Traceability', 'Weighbridge GRN/GIN', 'Pipe Yard Inventory'],
  ),

  // 4. WORKFORCE & TRADESPERSON (Labour)
  PersonaModel(
    id: 'USR-LAB-07',
    name: 'Tapan Das',
    role: 'Skilled 6G Welder',
    category: 'LABOUR',
    department: 'Field Workforce Gang',
    fidicRole: 'Certified Tradesperson (API 1104)',
    email: 't.das@oil.in',
    accentColor: Color(0xFF06B6D4),
    icon: Icons.badge_rounded,
    highlights: ['Digital Labour ID', 'GPS Biometric Attendance', 'Daily Shift Wage Ledger'],
  ),
];

PersonaModel getPersonaById(String? id) {
  if (id == null) return kAllPersonas.first;
  return kAllPersonas.firstWhere(
    (p) => p.id == id,
    orElse: () => kAllPersonas.first,
  );
}

PersonaModel getPersonaForUser(Map<String, dynamic>? user) {
  if (user == null) return kAllPersonas.first;
  final id = user['id'] as String?;
  if (id != null) {
    final match = kAllPersonas.where((p) => p.id == id);
    if (match.isNotEmpty) return match.first;
  }
  final role = (user['role'] as String? ?? '').toLowerCase();
  if (role.contains('director') || role.contains('manager') || role.contains('admin')) {
    return kAllPersonas[0];
  } else if (role.contains('supervisor') || role.contains('site')) {
    return kAllPersonas[1];
  } else if (role.contains('planning') || role.contains('scheduler')) {
    return kAllPersonas[2];
  } else if (role.contains('qa') || role.contains('qc') || role.contains('quality') || role.contains('inspector')) {
    return kAllPersonas[3];
  } else if (role.contains('hse') || role.contains('safety')) {
    return kAllPersonas[4];
  } else if (role.contains('material') || role.contains('store')) {
    return kAllPersonas[5];
  } else if (role.contains('weld') || role.contains('labour') || role.contains('worker') || role.contains('trades')) {
    return kAllPersonas[6];
  }
  return kAllPersonas.first;
}
