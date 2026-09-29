import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import 'pdf_intelligence_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String _selectedCategory = 'ALL';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _documents = [
    {
      'id': 'DOC-DWG-001',
      'title': 'Pipeline Alignment Sheet - Chainage 10+000 to 18+500',
      'category': 'DRAWINGS',
      'type': 'DWG / PDF',
      'version': 'Rev 3.2',
      'size': '18.4 MB',
      'uploadedAt': DateTime.now().subtract(const Duration(days: 4)),
      'status': 'APPROVED',
      'icon': Icons.architecture,
      'isTenderPdf': false,
    },
    {
      'id': 'DOC-FIDIC-024',
      'title': 'FIDIC Red Book Conditions of Contract - Particular Conditions',
      'category': 'CONTRACTS',
      'type': 'PDF',
      'version': 'Rev 1.0',
      'size': '8.2 MB',
      'uploadedAt': DateTime.now().subtract(const Duration(days: 12)),
      'status': 'BINDING',
      'icon': Icons.gavel,
      'isTenderPdf': true,
    },
    {
      'id': 'DOC-ITP-PIP-03',
      'title': 'Inspection & Test Plan (ITP) - High-Pressure Hydrotesting',
      'category': 'QUALITY',
      'type': 'PDF',
      'version': 'Rev 2.0',
      'size': '4.1 MB',
      'uploadedAt': DateTime.now().subtract(const Duration(days: 6)),
      'status': 'APPROVED',
      'icon': Icons.verified,
      'isTenderPdf': false,
    },
    {
      'id': 'DOC-PTW-HSE-08',
      'title': 'Permit to Work Standard Operating Procedure (SOP-HSE-04)',
      'category': 'PERMITS',
      'type': 'PDF',
      'version': 'Rev 4.1',
      'size': '3.6 MB',
      'uploadedAt': DateTime.now().subtract(const Duration(days: 15)),
      'status': 'ACTIVE',
      'icon': Icons.security,
      'isTenderPdf': false,
    },
    {
      'id': 'DOC-TEND-OIL-02',
      'title': 'EPC Package 2 Technical Specifications & Tender BOQ',
      'category': 'TENDER',
      'type': 'PDF',
      'version': 'Rev 2.1',
      'size': '24.8 MB',
      'uploadedAt': DateTime.now().subtract(const Duration(days: 20)),
      'status': 'TENDER',
      'icon': Icons.picture_as_pdf,
      'isTenderPdf': true,
    },
    {
      'id': 'DOC-SPEC-WELD-07',
      'title': 'Welding Procedure Specification (WPS) - API 1104 / ASME IX',
      'category': 'SPECIFICATIONS',
      'type': 'PDF',
      'version': 'Rev 1.3',
      'size': '5.9 MB',
      'uploadedAt': DateTime.now().subtract(const Duration(days: 8)),
      'status': 'APPROVED',
      'icon': Icons.description,
      'isTenderPdf': false,
    },
  ];

  final List<String> _categories = [
    'ALL',
    'DRAWINGS',
    'CONTRACTS',
    'QUALITY',
    'PERMITS',
    'TENDER',
    'SPECIFICATIONS',
  ];

  List<Map<String, dynamic>> get _filteredDocs {
    return _documents.where((doc) {
      if (_selectedCategory != 'ALL' && doc['category'] != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final title = (doc['title'] as String).toLowerCase();
        final id = (doc['id'] as String).toLowerCase();
        return title.contains(q) || id.contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final project = provider.currentProject;
    final docs = _filteredDocs;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project Documents & Drawings',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (project != null)
              Text(
                'Scope: ${project.name} (${project.code})',
                style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'PDF Intelligence Copilot',
            icon: const Icon(Icons.psychology, color: AppTheme.primaryLight),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PdfIntelligenceScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text('Upload Document', style: TextStyle(color: Colors.white)),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document upload dialog initialized. Select PDF / DWG file.'),
              backgroundColor: AppTheme.surfaceCard,
            ),
          );
        },
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          _buildAiIntelligenceBanner(),
          Expanded(
            child: docs.isEmpty
                ? const Center(
                    child: Text(
                      'No documents found matching criteria',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: docs.length,
                    itemBuilder: (context, index) => _buildDocCard(docs[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          TextField(
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search drawings, contracts, specs, ITP...',
              hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 18),
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
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                    backgroundColor: AppTheme.surfaceCard,
                    selectedColor: AppTheme.primary.withAlpha(60),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryLight : AppTheme.border,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiIntelligenceBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryLight.withAlpha(80)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryLight, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Tender & Drawing Intelligence',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Extract clauses, specs & multilingual translations directly from tenders.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PdfIntelligenceScreen()),
              );
            },
            child: const Text('Open Copilot', style: TextStyle(color: AppTheme.primaryLight, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(Map<String, dynamic> doc) {
    final DateTime dt = doc['uploadedAt'] as DateTime;
    final String dateStr = DateFormat('dd MMM yyyy').format(dt);
    final bool isTender = doc['isTenderPdf'] as bool? ?? false;

    return Card(
      color: AppTheme.surfaceCard,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(doc['icon'] as IconData, color: AppTheme.primaryLight, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['title'] as String,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${doc['id']} · ${doc['category']} · ${doc['version']}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    doc['status'] as String,
                    style: const TextStyle(color: AppTheme.tertiary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(color: AppTheme.border, height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Size: ${doc['size']} · $dateStr',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                Row(
                  children: [
                    if (isTender)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.psychology, size: 14, color: AppTheme.primaryLight),
                        label: const Text('AI Analysis', style: TextStyle(color: AppTheme.primaryLight, fontSize: 11)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PdfIntelligenceScreen()),
                          );
                        },
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.file_download_outlined, color: AppTheme.textSecondary, size: 18),
                      tooltip: 'Download Document',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Downloading ${doc['id']} (${doc['type']})...'),
                            backgroundColor: AppTheme.surfaceContainerHigh,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
