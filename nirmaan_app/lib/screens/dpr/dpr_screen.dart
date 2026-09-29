import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import 'dpr_history_screen.dart';

class DprScreen extends StatefulWidget {
  final String? initialActivity;
  final String? initialDelayReason;
  final String? initialNotes;

  const DprScreen({
    super.key,
    this.initialActivity,
    this.initialDelayReason,
    this.initialNotes,
  });

  @override
  State<DprScreen> createState() => _DprScreenState();
}

class _DprScreenState extends State<DprScreen> {
  String? _selectedActivityId;
  final TextEditingController _qtyController = TextEditingController();
  String _selectedDelay = 'No Delay';
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _delays = [
    'No Delay',
    'Weather/Rain',
    'Material Shortage',
    'Manpower Shortage',
    'Equipment Breakdown',
    'Design Change',
    'Client Hold',
    'Permit Delay',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDelayReason != null && _delays.contains(widget.initialDelayReason)) {
      _selectedDelay = widget.initialDelayReason!;
    }
    if (widget.initialNotes != null) {
      _notesController.text = widget.initialNotes!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      if (provider.activities.isNotEmpty) {
        if (widget.initialActivity != null) {
          final found = provider.activities.where((a) => a.id == widget.initialActivity || a.code == widget.initialActivity).toList();
          if (found.isNotEmpty) {
            setState(() {
              _selectedActivityId = found.first.id;
            });
          } else {
            setState(() {
              _selectedActivityId = provider.activities.first.id;
            });
          }
        } else {
          setState(() {
            _selectedActivityId = provider.activities.first.id;
          });
        }
      }
    });
  }

  void _submitDpr() async {
    if (_selectedActivityId == null) return;
    final provider = context.read<AppProvider>();
    
    setState(() {
      _isSubmitting = true;
    });

    final data = {
      'activityId': _selectedActivityId,
      'quantity': double.tryParse(_qtyController.text) ?? 0.0,
      'delayReason': _selectedDelay,
      'notes': _notesController.text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await provider.submitDpr(data);

    setState(() {
      _isSubmitting = false;
    });

    if (mounted) {
      if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: AppTheme.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('DPR Submitted Successfully!'),
            backgroundColor: AppTheme.tertiary,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DprHistoryScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final activities = provider.activities;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Submit DPR', style: TextStyle(color: AppTheme.textPrimary)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DprHistoryScreen()),
              );
            },
          )
        ],
      ),
      body: activities.isEmpty
          ? const Center(child: Text('No activities available', style: TextStyle(color: AppTheme.textPrimary)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReporterInfo(provider),
                  const SizedBox(height: 24),
                  const Text('Activity', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedActivityId,
                        dropdownColor: AppTheme.surfaceCard,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        items: activities.map((ActivityModel act) {
                          return DropdownMenuItem<String>(
                            value: act.id,
                            child: Text('${act.code} - ${act.name}'),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedActivityId = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Completed Quantity', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Enter amount...',
                            hintStyle: const TextStyle(color: AppTheme.textSecondary),
                            filled: true,
                            fillColor: AppTheme.surfaceCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppTheme.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppTheme.border),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _selectedActivityId != null
                            ? (activities.firstWhere((a) => a.id == _selectedActivityId, orElse: () => activities.first).unit)
                            : 'unit',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Delay Reason', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedDelay,
                        dropdownColor: AppTheme.surfaceCard,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        items: _delays.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedDelay = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Notes / Remarks', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Any issues on site?',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.surfaceCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Photo Evidence', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: AppTheme.textSecondary, size: 32),
                          SizedBox(height: 8),
                          Text('Tap to capture or upload', style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitDpr,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit DPR', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildReporterInfo(AppProvider provider) {
    final userName = provider.currentUser?['name'] ?? 'Ayush Singh';
    final userRole = provider.currentUser?['role'] ?? 'Site Supervisor';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.primary,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
              Text(userRole, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}
