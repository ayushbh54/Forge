// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class AddMaterialScreen extends StatefulWidget {
  const AddMaterialScreen({super.key});

  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  String _docType = 'GRN';
  String _unit = 'kg';

  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _sourceCtrl = TextEditingController();
  final TextEditingController _destCtrl = TextEditingController();
  final TextEditingController _actCodeCtrl = TextEditingController();
  final TextEditingController _supervisorCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _sourceCtrl.dispose();
    _destCtrl.dispose();
    _actCodeCtrl.dispose();
    _supervisorCtrl.dispose();
    super.dispose();
  }

  void _submit(AppProvider provider) async {
    final material = {
      'docType': _docType,
      'code': _codeCtrl.text,
      'description': _descCtrl.text,
      'quantity': double.tryParse(_qtyCtrl.text) ?? 0.0,
      'unit': _unit,
      'source': _sourceCtrl.text,
      'destination': _destCtrl.text,
      'activityCode': _actCodeCtrl.text,
      'supervisor': _supervisorCtrl.text,
      'date': DateTime.now().toIso8601String().split('T')[0],
    };
    
    await provider.recordMaterialTransaction(material);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text('New Material Transaction', style: TextStyle(color: Color(0xFFF1F5F9))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Document Type', style: TextStyle(color: Color(0xFF94A3B8))),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('GRN', style: TextStyle(color: Color(0xFFF1F5F9))),
                    value: 'GRN',
                    groupValue: _docType,
                    activeColor: const Color(0xFF0284C7),
                    onChanged: (val) => setState(() => _docType = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('GIN', style: TextStyle(color: Color(0xFFF1F5F9))),
                    value: 'GIN',
                    groupValue: _docType,
                    activeColor: const Color(0xFF0284C7),
                    onChanged: (val) => setState(() => _docType = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField('Material Code', _codeCtrl),
            const SizedBox(height: 16),
            _buildTextField('Description', _descCtrl),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(flex: 2, child: _buildTextField('Quantity', _qtyCtrl, isNumber: true)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    dropdownColor: const Color(0xFF162347),
                    style: const TextStyle(color: Color(0xFFF1F5F9)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF162347),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: ['meters', 'kg', 'tons', 'pieces', 'liters', 'cubic meters']
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (val) => setState(() => _unit = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField('Source/Supplier', _sourceCtrl),
            const SizedBox(height: 16),
            _buildTextField('Destination Location', _destCtrl),
            const SizedBox(height: 16),
            _buildTextField('Associated Activity Code', _actCodeCtrl),
            const SizedBox(height: 16),
            _buildTextField('Issued To Supervisor', _supervisorCtrl),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _submit(provider),
                child: const Text('Submit Transaction', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Color(0xFFF1F5F9)),
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFF162347),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF26396E)),
        ),
      ),
    );
  }
}
