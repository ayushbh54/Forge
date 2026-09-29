import os

base_dir = "/Users/ayushsinghbhadoria/Desktop/sih/Nirmaan/nirmaan_app/lib/screens"

files = {
    "materials/materials_screen.dart": """import 'package:flutter/material.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({Key? key}) : super(key: key);

  @override
  _MaterialsScreenState createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text('Stores Ledger', style: TextStyle(color: Color(0xFFF1F5F9))),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0284C7),
          labelColor: const Color(0xFF0284C7),
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'GRN'),
            Tab(text: 'GIN'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Color(0xFFF1F5F9)),
              decoration: InputDecoration(
                hintText: 'Search material code or description...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFF162347),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF26396E)),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList('All'),
                _buildList('GRN'),
                _buildList('GIN'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0284C7),
        onPressed: () {
          // Navigate to add material screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(String filter) {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        return Card(
          color: const Color(0xFF162347),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('DOC-00${index + 1}', style: const TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? const Color(0xFF4EDEA3).withOpacity(0.2) : const Color(0xFFFFB95F).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(index % 2 == 0 ? 'GRN' : 'GIN', style: TextStyle(color: index % 2 == 0 ? const Color(0xFF4EDEA3) : const Color(0xFFFFB95F), fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Material: Cement (CEM-43G)', style: TextStyle(color: Color(0xFFF1F5F9))),
                const Text('Quantity: 500 Bags', style: TextStyle(color: Color(0xFF94A3B8))),
                const SizedBox(height: 8),
                const Text('Source: Ultratech Supplier', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                const Text('Date: 2023-10-25', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }
}
""",
    "materials/add_material_screen.dart": """import 'package:flutter/material.dart';

class AddMaterialScreen extends StatefulWidget {
  const AddMaterialScreen({Key? key}) : super(key: key);

  @override
  _AddMaterialScreenState createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  String _docType = 'GRN';
  String _unit = 'kg';

  @override
  Widget build(BuildContext context) {
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
            _buildTextField('Material Code'),
            const SizedBox(height: 16),
            _buildTextField('Description'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(flex: 2, child: _buildTextField('Quantity')),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unit,
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
            _buildTextField('Source/Supplier'),
            const SizedBox(height: 16),
            _buildTextField('Destination Location'),
            const SizedBox(height: 16),
            _buildTextField('Associated Activity Code'),
            const SizedBox(height: 16),
            _buildTextField('Issued To Supervisor'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  // Submit
                },
                child: const Text('Submit Transaction', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label) {
    return TextField(
      style: const TextStyle(color: Color(0xFFF1F5F9)),
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
""",
    "conflicts/conflicts_screen.dart": """import 'package:flutter/material.dart';

class ConflictsScreen extends StatefulWidget {
  const ConflictsScreen({Key? key}) : super(key: key);

  @override
  _ConflictsScreenState createState() => _ConflictsScreenState();
}

class _ConflictsScreenState extends State<ConflictsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text('Conflict & Dispute Center', style: TextStyle(color: Color(0xFFF1F5F9))),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Color(0xFFF1F5F9)),
            color: const Color(0xFF162347),
            onSelected: (val) => setState(() => _filter = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All', style: TextStyle(color: Color(0xFFF1F5F9)))),
              const PopupMenuItem(value: 'OPEN', child: Text('OPEN', style: TextStyle(color: Color(0xFFF1F5F9)))),
              const PopupMenuItem(value: 'RESOLVED', child: Text('RESOLVED', style: TextStyle(color: Color(0xFFF1F5F9)))),
            ],
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            color: const Color(0xFF162347),
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: const Text('Quantity Variance in Excavation', style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold)),
              subtitle: const Text('Activity: ACT-102 | Type: Measurement', style: TextStyle(color: Color(0xFF94A3B8))),
              leading: const CircleAvatar(backgroundColor: Colors.red, radius: 10),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                const Text('Claimed: 500 cum | Verified: 450 cum', style: TextStyle(color: Color(0xFFF1F5F9))),
                const SizedBox(height: 8),
                const Text('Spec/Clause Reference: FIDIC Clause 12.1', style: TextStyle(color: Color(0xFF94A3B8))),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                    onPressed: () {
                      _showResolveDialog(context);
                    },
                    child: const Text('Resolve'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showResolveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF162347),
        title: const Text('Resolve Conflict', style: TextStyle(color: Color(0xFFF1F5F9))),
        content: TextField(
          style: const TextStyle(color: Color(0xFFF1F5F9)),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter resolution note...',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFF0B1326),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            onPressed: () => Navigator.pop(context),
            child: const Text('Submit Resolution'),
          ),
        ],
      ),
    );
  }
}
""",
    "audit/audit_screen.dart": """import 'package:flutter/material.dart';

class AuditScreen extends StatelessWidget {
  const AuditScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text('Tamper-Proof Audit Trail', style: TextStyle(color: Color(0xFFF1F5F9))),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Column(
                  children: [
                    Icon(Icons.edit_document, color: Color(0xFF38BDF8)),
                    SizedBox(height: 4),
                    Container(width: 2, height: 100, color: Color(0xFF26396E)),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162347),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF26396E)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Quantity Updated', style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold)),
                            Text('10:45 AM', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Actor: Rahul Sharma (Site Engineer)', style: TextStyle(color: Color(0xFF94A3B8))),
                        const Text('Entity: ACTIVITY | ID: ACT-204', style: TextStyle(color: Color(0xFF94A3B8))),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('450', style: TextStyle(color: Colors.red, decoration: TextDecoration.lineThrough)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 8),
                            const Text('500', style: TextStyle(color: Color(0xFF4EDEA3))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1326),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('SHA-256: e3b0c44298fc1c14...', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10)),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
""",
    "ai/gemini_brain_screen.dart": """import 'package:flutter/material.dart';

class GeminiBrainScreen extends StatefulWidget {
  const GeminiBrainScreen({Key? key}) : super(key: key);

  @override
  _GeminiBrainScreenState createState() => _GeminiBrainScreenState();
}

class _GeminiBrainScreenState extends State<GeminiBrainScreen> {
  final List<String> _messages = ['Hello! I am Nirmaan AI Copilot. How can I assist you with your project today?'];
  final TextEditingController _controller = TextEditingController();

  void _sendMessage(String text) {
    if (text.isEmpty) return;
    setState(() {
      _messages.add(text);
      _controller.clear();
      // Simulate AI response
      _messages.add('Analyzing data... Based on current API inputs, schedule is on track.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text('Gemini AI Brain Copilot', style: TextStyle(color: Color(0xFFF1F5F9))),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _buildQuickPrompt('Analyze project health'),
                _buildQuickPrompt('Identify risks'),
                _buildQuickPrompt('Suggest schedule recovery'),
                _buildQuickPrompt('Budget forecast'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isUser = index % 2 != 0;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF0284C7) : const Color(0xFF162347),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _messages[index],
                      style: const TextStyle(color: Color(0xFFF1F5F9)),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF111C38),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Color(0xFFF1F5F9)),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF162347),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF0284C7),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickPrompt(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        backgroundColor: const Color(0xFF162347),
        label: Text(text, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
        onPressed: () => _sendMessage(text),
      ),
    );
  }
}
""",
    "ai/voice_assistant_screen.dart": """import 'package:flutter/material.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({Key? key}) : super(key: key);

  @override
  _VoiceAssistantScreenState createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  bool _isRecording = false;
  String _transcript = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text('Voice-First Site Update', style: TextStyle(color: Color(0xFFF1F5F9))),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isRecording ? 'Listening...' : 'Tap to speak in Hindi or English',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 18),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isRecording = !_isRecording;
                    if (!_isRecording) {
                      _transcript = 'Excavation completed for 500 cubic meters in zone B.';
                    } else {
                      _transcript = '';
                    }
                  });
                },
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: _isRecording ? Colors.red : const Color(0xFF0284C7),
                  child: const Icon(Icons.mic, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),
              if (_transcript.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF162347),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_transcript, style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 16)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                  onPressed: () {},
                  child: const Text('Confirm & Submit as DPR'),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
""",
    "documents/pdf_intelligence_screen.dart": """import 'package:flutter/material.dart';

class PdfIntelligenceScreen extends StatelessWidget {
  const PdfIntelligenceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text('PDF Intelligence', style: TextStyle(color: Color(0xFFF1F5F9))),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            InkWell(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF162347),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF26396E), style: BorderStyle.solid),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.upload_file, size: 48, color: Color(0xFF38BDF8)),
                    SizedBox(height: 16),
                    Text('Upload Tender PDF', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 18)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard('Extract Key Insights', Icons.insights, Colors.amber),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard('Page-Preserving Translation', Icons.g_translate, Colors.green),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFF1F5F9))),
        ],
      ),
    );
  }
}
""",
    "linking/linking_bridge_screen.dart": """import 'package:flutter/material.dart';

class LinkingBridgeScreen extends StatelessWidget {
  const LinkingBridgeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text('NLP Activity Linking Bridge', style: TextStyle(color: Color(0xFFF1F5F9))),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              maxLines: 5,
              style: const TextStyle(color: Color(0xFFF1F5F9)),
              decoration: InputDecoration(
                hintText: 'Enter raw field text here (e.g., Daily report, Site diary)...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFF162347),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {},
                child: const Text('Extract & Match', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Match Results', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF162347),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('No results yet. Run extraction.', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
""",
    "settings/settings_screen.dart": """import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text('App Settings', style: TextStyle(color: Color(0xFFF1F5F9))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('User Profile', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('Admin User', style: TextStyle(color: Color(0xFFF1F5F9))),
            subtitle: const Text('Role: Project Manager', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          const Divider(color: Color(0xFF26396E)),
          const Text('Server Configuration', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            style: const TextStyle(color: Color(0xFFF1F5F9)),
            decoration: InputDecoration(
              labelText: 'API Base URL',
              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFF162347),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            controller: TextEditingController(text: 'http://10.0.2.2:3000'),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF26396E)),
          const Text('Language Selection', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['English', 'हिंदी', 'తెలుగు', 'தமிழ்', 'मराठी', 'বাংলা'].map((lang) {
              return ChoiceChip(
                label: Text(lang),
                selected: lang == 'English',
                onSelected: (val) {},
                selectedColor: const Color(0xFF0284C7),
                backgroundColor: const Color(0xFF162347),
                labelStyle: const TextStyle(color: Color(0xFFF1F5F9)),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {},
            child: const Text('Logout'),
          )
        ],
      ),
    );
  }
}
""",
    "more/more_screen.dart": """import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {'label': 'Materials', 'icon': Icons.inventory, 'color': Colors.orange},
      {'label': 'Conflicts', 'icon': Icons.gavel, 'color': Colors.red},
      {'label': 'Audit Trail', 'icon': Icons.history, 'color': Colors.blue},
      {'label': 'AI Brain', 'icon': Icons.psychology, 'color': Colors.purple},
      {'label': 'Voice Assistant', 'icon': Icons.mic, 'color': Colors.green},
      {'label': 'PDF Intelligence', 'icon': Icons.picture_as_pdf, 'color': Colors.redAccent},
      {'label': 'Linking Bridge', 'icon': Icons.link, 'color': Colors.teal},
      {'label': 'Supervisor Visit', 'icon': Icons.visibility, 'color': Colors.cyan},
      {'label': 'HR Module', 'icon': Icons.people, 'color': Colors.indigo},
      {'label': 'Documents', 'icon': Icons.folder, 'color': Colors.amber},
      {'label': 'Settings', 'icon': Icons.settings, 'color': Colors.grey},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text('More Features', style: TextStyle(color: Color(0xFFF1F5F9))),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return InkWell(
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF162347),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'], color: item['color'], size: 32),
                  const SizedBox(height: 8),
                  Text(
                    item['label'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
"""
}

for rel_path, content in files.items():
    full_path = os.path.join(base_dir, rel_path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w", encoding="utf-8") as f:
        f.write(content)

print("All screens generated successfully.")
