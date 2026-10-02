import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../core/localization/language_controller.dart';
import '../../core/models/persona_model.dart';
import '../app_shell.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final TextEditingController _projectIdController = TextEditingController(text: 'PRJ-OIL-2026');
  final TextEditingController _identifierController = TextEditingController(text: 'm.vance@oil.in');
  final TextEditingController _passwordController = TextEditingController(text: '••••••••');

  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regPhoneController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regProjectIdController = TextEditingController(text: 'PRJ-OIL-2026');
  final TextEditingController _regBadgeController = TextEditingController(text: 'LAB-2026');

  bool _isLoading = false;
  String _selectedRole = 'Project Director';
  String _selectedDept = 'Piping';
  String _selectedTrade = '6G Pipe Welder (TIG/MIG)';
  String _activeCategoryFilter = 'ALL';

  final List<String> _roles = [
    'Project Director',
    'Site Piping Supervisor',
    'Planning & Controls Engineer',
    'QA/QC Lead Inspector',
    'HSE & Safety Lead',
    'Stores & Materials Manager',
    'Skilled 6G Welder (Labour ID)',
  ];

  final List<String> _departments = [
    'Piping & Pipeline Engineering',
    'Civil & Structural Engineering',
    'Project Controls & Planning',
    'Quality Assurance & Inspection (QA/QC)',
    'Health, Safety & Environment (HSE)',
    'Stores & Materials Management',
    'Field Operations & Workforce',
  ];

  final List<String> _trades = [
    '6G Pipe Welder (TIG/MIG)',
    'Structural Steel Erector',
    'Pipe Fitter / Fabricator',
    'Heavy Crane / Rigging Operator',
    'Civil Barbender / Mason',
    'Scaffolding Inspector',
    'Electrical Technician',
    'Hydrotest Technician',
    'General Construction Tradesperson',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _projectIdController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _regNameController.dispose();
    _regPhoneController.dispose();
    _regEmailController.dispose();
    _regProjectIdController.dispose();
    _regBadgeController.dispose();
    super.dispose();
  }

  Future<void> _handlePersonaSelect(PersonaModel persona) async {
    setState(() => _isLoading = true);

    final userData = {
      'id': persona.id,
      'name': persona.name,
      'role': persona.role,
      'department': persona.department,
      'fidicRole': persona.fidicRole,
      'email': persona.email,
      'projectId': 'PRJ-OIL-2026',
    };

    try {
      await context.read<AppProvider>().loginUser(userData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text(
              'Logged in as ${persona.name} (${persona.role})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Login error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCustomLogin() async {
    if (_loginFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final userData = {
        'id': 'USR-CUSTOM',
        'name': _identifierController.text.trim().split('@')[0],
        'role': _selectedRole,
        'department': _selectedDept,
        'fidicRole': _selectedRole,
        'email': _identifierController.text.trim(),
        'projectId': _projectIdController.text.trim(),
      };

      try {
        await context.read<AppProvider>().loginUser(userData);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AppShell()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFEF4444),
              content: Text('Authentication error: $e'),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRegister() async {
    if (_registerFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final userData = {
        'id': 'USR-REG-${DateTime.now().millisecondsSinceEpoch % 10000}',
        'name': _regNameController.text.trim(),
        'role': _selectedRole,
        'department': _selectedDept,
        'fidicRole': _selectedRole,
        'email': _regEmailController.text.trim(),
        'phone': _regPhoneController.text.trim(),
        'projectId': _regProjectIdController.text.trim(),
        'badgeNumber': _regBadgeController.text.trim(),
      };

      try {
        await context.read<AppProvider>().loginUser(userData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF10B981),
              content: Text('Welcome, ${userData['name']}! Connected to ${_regProjectIdController.text}.'),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AppShell()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFEF4444),
              content: Text('Registration error: $e'),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070D1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E172E),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF1E3A8A)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('N', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NIRMAAN OS',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'OIL INDIA LIMITED · SIH26122',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Regional Language Selector
          ListenableBuilder(
            listenable: LanguageController.instance,
            builder: (context, _) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.translate_rounded, color: Color(0xFF38BDF8), size: 20),
                tooltip: 'Select Language',
                color: const Color(0xFF162347),
                onSelected: (code) {
                  LanguageController.instance.changeLanguage(code);
                },
                itemBuilder: (context) {
                  return LanguageController.instance.supportedLanguages.map((lang) {
                    final isSelected = lang.code == LanguageController.instance.currentLanguageCode;
                    return PopupMenuItem<String>(
                      value: lang.code,
                      child: Row(
                        children: [
                          Text(lang.nativeName, style: TextStyle(color: isSelected ? const Color(0xFF38BDF8) : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          const SizedBox(width: 8),
                          Text('(${lang.name})', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                        ],
                      ),
                    );
                  }).toList();
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0284C7),
          indicatorWeight: 3,
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'ROLE DIRECT', icon: Icon(Icons.groups_rounded, size: 18)),
            Tab(text: 'STAFF SSO', icon: Icon(Icons.lock_outline_rounded, size: 18)),
            Tab(text: 'REGISTER ID', icon: Icon(Icons.person_add_alt_1_rounded, size: 18)),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildRoleDirectTab(),
              _buildStaffSsoTab(),
              _buildRegisterTab(),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0284C7)),
                    SizedBox(height: 16),
                    Text(
                      'Authenticating Identity & Project WBS...',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: 1-TAP ROLE DIRECT ACCESS (ADMIN, STAFF, LABOUR)
  // ===========================================================================
  Widget _buildRoleDirectTab() {
    final filtered = _activeCategoryFilter == 'ALL'
        ? kAllPersonas
        : kAllPersonas.where((p) => p.category == _activeCategoryFilter).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        // Live Network Status Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF111C38),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1E2E5C)),
          ),
          child: const Row(
            children: [
              Icon(Icons.satellite_alt_rounded, size: 16, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Oil India Duliajan Node Online · RTK Geodetic 99.4%',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                'LIVE SYNC',
                style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Headline
        const Text(
          'Select Operational Persona',
          style: TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap any role to launch tailored mobile cockpit with specialized permissions.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.3),
        ),
        const SizedBox(height: 14),

        // Role Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('ALL', 'All Roles (${kAllPersonas.length})', Icons.apps_rounded),
              const SizedBox(width: 8),
              _buildFilterChip('ADMIN', 'Admin / PM (1)', Icons.shield_rounded),
              const SizedBox(width: 8),
              _buildFilterChip('STAFF', 'Site Staff (2)', Icons.engineering_rounded),
              const SizedBox(width: 8),
              _buildFilterChip('SPECIALIST', 'Specialist (3)', Icons.verified_user_rounded),
              const SizedBox(width: 8),
              _buildFilterChip('LABOUR', 'Labour ID (1)', Icons.badge_rounded),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Persona Cards Grid
        ...filtered.map((persona) => _buildPersonaCard(persona)),
      ],
    );
  }

  Widget _buildFilterChip(String category, String label, IconData icon) {
    final isSelected = _activeCategoryFilter == category;
    return InkWell(
      onTap: () => setState(() => _activeCategoryFilter = category),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF111C38),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF1E2E5C),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaCard(PersonaModel persona) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E172E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: persona.accentColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handlePersonaSelect(persona),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: persona.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: persona.accentColor.withValues(alpha: 0.4)),
                      ),
                      child: Icon(persona.icon, color: persona.accentColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  persona.name,
                                  style: const TextStyle(
                                    color: Color(0xFFF1F5F9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: persona.accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: persona.accentColor.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  persona.category,
                                  style: TextStyle(
                                    color: persona.accentColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            persona.role,
                            style: TextStyle(
                              color: persona.accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            persona.department,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Color(0xFF1E2E5C), height: 1),
                const SizedBox(height: 8),

                // Capability tags
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: persona.highlights.map((h) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111C38),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF1E2E5C)),
                      ),
                      child: Text(
                        '✓ $h',
                        style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      persona.fidicRole,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Launch Cockpit',
                          style: TextStyle(
                            color: persona.accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: persona.accentColor),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: STAFF / CORPORATE CREDENTIAL LOGIN
  // ===========================================================================
  Widget _buildStaffSsoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF111C38),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E2E5C)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security_rounded, color: Color(0xFF38BDF8), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Corporate Single Sign-On (SSO) for Oil India Limited & JV Consortium Engineering Staff.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildTextField(
              controller: _projectIdController,
              label: 'Project Unique ID',
              icon: Icons.business_rounded,
              hint: 'e.g. PRJ-OIL-2026',
            ),
            const SizedBox(height: 14),

            _buildTextField(
              controller: _identifierController,
              label: 'Corporate Email or Badge ID',
              icon: Icons.badge_outlined,
              hint: 'e.g. m.vance@oil.in or OIL-ENG-04',
            ),
            const SizedBox(height: 14),

            _buildDropdown(
              label: 'Designated Staff Role',
              value: _selectedRole,
              items: _roles,
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
            const SizedBox(height: 14),

            _buildDropdown(
              label: 'Department',
              value: _selectedDept,
              items: _departments,
              onChanged: (v) => setState(() => _selectedDept = v!),
            ),
            const SizedBox(height: 14),

            _buildTextField(
              controller: _passwordController,
              label: 'Security Passkey / PIN',
              icon: Icons.key_rounded,
              isPassword: true,
              hint: 'Enter your 6-digit access PIN',
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              onPressed: _isLoading ? null : _handleCustomLogin,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'AUTHENTICATE & ENTER',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 3: REGISTER NEW WORKER / STAFF
  // ===========================================================================
  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(
              controller: _regNameController,
              label: 'Full Legal Name',
              icon: Icons.person_rounded,
              hint: 'e.g. Ramesh Chandra Das',
              requiredField: true,
            ),
            const SizedBox(height: 14),

            _buildTextField(
              controller: _regPhoneController,
              label: 'Phone Number',
              icon: Icons.phone_rounded,
              hint: '+91 98765 43210',
            ),
            const SizedBox(height: 14),

            _buildTextField(
              controller: _regEmailController,
              label: 'Email Address (Optional)',
              icon: Icons.email_rounded,
              hint: 'worker@contractor.in',
            ),
            const SizedBox(height: 14),

            _buildTextField(
              controller: _regProjectIdController,
              label: 'Project Unique ID',
              icon: Icons.fingerprint_rounded,
              hint: 'PRJ-OIL-2026',
              requiredField: true,
            ),
            const SizedBox(height: 14),

            _buildDropdown(
              label: 'Assigned Role',
              value: _selectedRole,
              items: _roles,
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
            const SizedBox(height: 14),

            _buildDropdown(
              label: 'Assigned Department',
              value: _selectedDept,
              items: _departments,
              onChanged: (v) => setState(() => _selectedDept = v!),
            ),
            const SizedBox(height: 14),

            if (_selectedRole.toLowerCase().contains('labour') || _selectedRole.toLowerCase().contains('welder')) ...[
              _buildDropdown(
                label: 'Certified Trade / Skill',
                value: _selectedTrade,
                items: _trades,
                onChanged: (v) => setState(() => _selectedTrade = v!),
              ),
              const SizedBox(height: 14),
            ],

            _buildTextField(
              controller: _regBadgeController,
              label: 'Digital Badge / Gate Pass ID',
              icon: Icons.card_membership_rounded,
              hint: 'e.g. LAB-2026',
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              onPressed: _isLoading ? null : _handleRegister,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ENROLL & CONNECT ID',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isPassword = false,
    bool requiredField = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (requiredField ? ' *' : ''),
          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 20),
            filled: true,
            fillColor: const Color(0xFF111C38),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1E2E5C)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1E2E5C)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
            ),
          ),
          validator: (v) {
            if (requiredField && (v == null || v.trim().isEmpty)) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : items.first,
          dropdownColor: const Color(0xFF162347),
          style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF111C38),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1E2E5C)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1E2E5C)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
