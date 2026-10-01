import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class AddWorkerScreen extends StatefulWidget {
  const AddWorkerScreen({super.key});

  @override
  State<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends State<AddWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTrade = 'WELDER';
  DateTime? _certExpiry = DateTime.now().add(const Duration(days: 365));

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _badgeController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _contractorController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _trades = [
    'WELDER', 'FITTER', 'RIGGER', 'ELECTRICIAN',
    'PAINTER', 'CARPENTER', 'MASON', 'GENERAL_LABOUR'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _badgeController.dispose();
    _skillsController.dispose();
    _contractorController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final trade = _selectedTrade ?? 'GENERAL_LABOUR';
    final workerData = <String, dynamic>{
      'id': 'WRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'name': _nameController.text.trim(),
      'badgeNumber': _badgeController.text.trim(),
      'trade': trade,
      'skills': _skillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      'contractor': _contractorController.text.trim().isNotEmpty ? _contractorController.text.trim() : 'Consortium Gang A',
      'gang': _contractorController.text.trim().isNotEmpty ? _contractorController.text.trim() : 'Consortium Gang A',
      'safetyCertExpiry': _certExpiry?.toIso8601String().split('T')[0] ?? '2028-12-31',
      'safetyCertValidTill': _certExpiry?.toIso8601String().split('T')[0] ?? '2028-12-31',
      'phone': _phoneController.text.trim(),
      'attendanceStatus': 'ABSENT',
      'verificationMethod': 'NOT_VERIFIED',
    };

    final provider = context.read<AppProvider>();
    final success = await provider.createWorker(workerData);

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Worker added and registered successfully' : 'Worker saved to local register'),
          backgroundColor: const Color(0xFF4EDEA3),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        title: const Text('Add New Worker', style: TextStyle(color: Color(0xFFF1F5F9))),
        backgroundColor: const Color(0xFF111C38),
        iconTheme: const IconThemeData(color: Color(0xFFF1F5F9)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField('Full Name', Icons.person, _nameController),
              const SizedBox(height: 16),
              _buildTextField('Badge Number', Icons.badge, _badgeController),
              const SizedBox(height: 16),
              _buildDropdownField(),
              const SizedBox(height: 16),
              _buildTextField('Skills (comma separated)', Icons.build, _skillsController),
              const SizedBox(height: 16),
              _buildTextField('Contractor / Gang', Icons.group, _contractorController),
              const SizedBox(height: 16),
              _buildDateField(),
              const SizedBox(height: 16),
              _buildTextField('Phone Number', Icons.phone, _phoneController, isNumeric: true),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isNumeric = false}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Color(0xFFF1F5F9)),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFF162347),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'This field is required';
        return null;
      },
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      dropdownColor: const Color(0xFF162347),
      decoration: InputDecoration(
        labelText: 'Trade',
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.work, color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFF162347),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
      style: const TextStyle(color: Color(0xFFF1F5F9)),
      initialValue: _selectedTrade,
      items: _trades.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (val) {
        setState(() {
          _selectedTrade = val;
        });
      },
      validator: (val) {
        if (val == null || val.isEmpty) return 'Please select a trade';
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF0284C7),
                  onPrimary: Colors.white,
                  surface: Color(0xFF162347),
                  onSurface: Color(0xFFF1F5F9),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _certExpiry = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Safety Certificate Expiry',
          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF94A3B8)),
          filled: true,
          fillColor: const Color(0xFF162347),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
        child: Text(
          _certExpiry != null ? '${_certExpiry!.toLocal()}'.split(' ')[0] : 'Select Date',
          style: TextStyle(color: _certExpiry != null ? const Color(0xFFF1F5F9) : const Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}
