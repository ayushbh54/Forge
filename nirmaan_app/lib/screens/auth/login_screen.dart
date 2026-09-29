import 'package:flutter/material.dart';
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

  bool _isLoading = false;
  String _selectedRole = 'Project Manager';
  String _selectedDept = 'Civil';
  String _selectedTrade = 'General Labour';
  String _selectedLanguage = 'English';

  final List<String> _languages = ['English', 'Hindi', 'Marathi', 'Gujarati', 'Tamil', 'Telugu', 'Kannada', 'Malayalam', 'Bengali', 'Punjabi'];
  final List<String> _roles = ['Project Manager', 'Site Engineer', 'Supervisor', 'Labour/Tradesperson', 'QA/QC Inspector', 'HSE Officer', 'Materials Controller', 'Planning Engineer'];
  final List<String> _departments = ['Civil', 'Piping', 'Electrical', 'Instrumentation', 'Mechanical', 'HSE'];
  final List<String> _trades = ['Welder', 'Fitter', 'Rigger', 'Electrician', 'Painter', 'General Labour'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_loginFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // Simulate API call GET /api/auth
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppShell()));
      }
    }
  }

  void _handleRegister() async {
    if (_registerFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // Simulate API call POST /api/auth
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppShell()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        elevation: 0,
        title: const Text('Authentication', style: TextStyle(color: Color(0xFFF1F5F9))),
        actions: [
          DropdownButton<String>(
            value: _selectedLanguage,
            dropdownColor: const Color(0xFF162347),
            style: const TextStyle(color: Color(0xFFF1F5F9)),
            icon: const Icon(Icons.language, color: Color(0xFF94A3B8)),
            underline: const SizedBox(),
            items: _languages.map((String lang) {
              return DropdownMenuItem<String>(
                value: lang,
                child: Text(lang),
              );
            }).toList(),
            onChanged: (String? val) {
              if (val != null) setState(() => _selectedLanguage = val);
            },
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0284C7),
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(text: 'LOGIN'),
            Tab(text: 'REGISTER'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoginTab(),
          _buildRegisterTab(),
        ],
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(label: 'Project ID', icon: Icons.work_outline),
            const SizedBox(height: 16),
            _buildTextField(label: 'Phone or Email', icon: Icons.person_outline),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Role',
              value: _selectedRole,
              items: _roles,
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(label: 'Full Name', icon: Icons.badge_outlined, requiredField: true),
            const SizedBox(height: 16),
            _buildTextField(label: 'Phone Number', icon: Icons.phone_outlined),
            const SizedBox(height: 16),
            _buildTextField(label: 'Email Address', icon: Icons.email_outlined),
            const SizedBox(height: 16),
            _buildTextField(label: 'Project Unique ID', icon: Icons.fingerprint, requiredField: true),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Role',
              value: _selectedRole,
              items: _roles,
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Department',
              value: _selectedDept,
              items: _departments,
              onChanged: (v) => setState(() => _selectedDept = v!),
            ),
            if (_selectedRole == 'Labour/Tradesperson') ...[
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Trade',
                value: _selectedTrade,
                items: _trades,
                onChanged: (v) => setState(() => _selectedTrade = v!),
              ),
            ],
            const SizedBox(height: 16),
            _buildTextField(label: 'Badge Number (Optional)', icon: Icons.card_membership),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isLoading ? null : _handleRegister,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('REGISTER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required IconData icon, bool requiredField = false}) {
    return TextFormField(
      style: const TextStyle(color: Color(0xFFF1F5F9)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF26396E)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF0284C7)),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: const Color(0xFF162347),
      ),
      validator: requiredField ? (val) {
        if (val == null || val.isEmpty) return 'This field is required';
        return null;
      } : null,
    );
  }

  Widget _buildDropdown({required String label, required String value, required List<String> items, required void Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(0xFF162347),
      style: const TextStyle(color: Color(0xFFF1F5F9)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF26396E)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF0284C7)),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: const Color(0xFF162347),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
