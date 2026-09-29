import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nirmaan_app/providers/app_provider.dart';
import 'package:intl/intl.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _projectName = '';
  String _projectCode = '';
  String _clientName = '';
  String _contractor = '';
  String _contractType = 'EPC';
  String _location = '';
  double _budget = 0.0;
  String _currency = 'INR';
  DateTime? _startDate;
  DateTime? _plannedFinishDate;

  final List<String> _contractTypes = ['EPC', 'FIDIC Red Book', 'BOT', 'Item Rate', 'Lump Sum'];

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0284C7),
              onPrimary: Color(0xFFF1F5F9),
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
        if (isStart) {
          _startDate = picked;
        } else {
          _plannedFinishDate = picked;
        }
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _plannedFinishDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both start and finish dates')),
        );
        return;
      }
      _formKey.currentState!.save();
      try {
        final provider = context.read<AppProvider>();
        final success = await provider.createProject({
          'name': _projectName,
          'code': _projectCode,
          'client': _clientName,
          'contractorJV': _contractor,
          'contractType': _contractType,
          'location': _location,
          'budget': _budget * 10000000, // Convert crores to actual value
          'currency': _currency,
          'startDate': _startDate!.toIso8601String(),
          'plannedFinishDate': _plannedFinishDate!.toIso8601String(),
          'status': 'PLANNING',
          'lifecycle': 'EXECUTION',
        });
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project created successfully'), backgroundColor: Color(0xFF4EDEA3)),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFF111C38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF26396E)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF26396E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0284C7)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        title: const Text('Create Project', style: TextStyle(color: Color(0xFFF1F5F9))),
        backgroundColor: const Color(0xFF111C38),
        iconTheme: const IconThemeData(color: Color(0xFFF1F5F9)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                style: const TextStyle(color: Color(0xFFF1F5F9)),
                decoration: _inputDecoration('Project Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _projectName = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Color(0xFFF1F5F9)),
                decoration: _inputDecoration('Project Code'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _projectCode = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Color(0xFFF1F5F9)),
                decoration: _inputDecoration('Client Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _clientName = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Color(0xFFF1F5F9)),
                decoration: _inputDecoration('Contractor / JV'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _contractor = value!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _contractType,
                dropdownColor: const Color(0xFF162347),
                style: const TextStyle(color: Color(0xFFF1F5F9)),
                decoration: _inputDecoration('Contract Type'),
                items: _contractTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _contractType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Color(0xFFF1F5F9)),
                decoration: _inputDecoration('Location'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _location = value!,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      style: const TextStyle(color: Color(0xFFF1F5F9)),
                      decoration: _inputDecoration('Budget (in Crores)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onSaved: (value) => _budget = double.parse(value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: 'INR',
                      style: const TextStyle(color: Color(0xFFF1F5F9)),
                      decoration: _inputDecoration('Currency'),
                      onSaved: (value) => _currency = value ?? 'INR',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111C38),
                          border: Border.all(color: const Color(0xFF26396E)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _startDate == null ? 'Start Date' : DateFormat('yyyy-MM-dd').format(_startDate!),
                          style: TextStyle(
                            color: _startDate == null ? const Color(0xFF94A3B8) : const Color(0xFFF1F5F9),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111C38),
                          border: Border.all(color: const Color(0xFF26396E)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _plannedFinishDate == null ? 'Planned Finish' : DateFormat('yyyy-MM-dd').format(_plannedFinishDate!),
                          style: TextStyle(
                            color: _plannedFinishDate == null ? const Color(0xFF94A3B8) : const Color(0xFFF1F5F9),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Create Project', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
