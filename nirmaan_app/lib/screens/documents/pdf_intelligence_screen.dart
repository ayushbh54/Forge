import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class PdfIntelligenceScreen extends StatefulWidget {
  const PdfIntelligenceScreen({super.key});

  @override
  State<PdfIntelligenceScreen> createState() => _PdfIntelligenceScreenState();
}

class _PdfIntelligenceScreenState extends State<PdfIntelligenceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isAnalyzing = false;
  bool _hasAnalyzed = false;
  bool _isTranslating = false;
  bool _hasTranslated = false;
  int _translationProgressPage = 0;
  final int _totalDocPages = 18; // Sample tender document (18 pages)
  String _selectedTargetLanguage = 'Hindi (हिन्दी)';

  final List<String> _targetLanguages = [
    'Hindi (हिन्दी)',
    'Bengali (বাংলা)',
    'Marathi (मराठी)',
    'Telugu (తెలుగు)',
    'Tamil (தமிழ்)',
    'Gujarati (ગુજરાતી)',
    'Kannada (ಕನ್ನಡ)',
    'Malayalam (മലയാളം)',
    'Assamese (অসমীয়া)',
    'Punjabi (ਪੰਜਾਬੀ)',
    'Odia (ଓଡ଼ିଆ)',
    'Urdu (اردو)',
    'Maithili (मैथिली)',
    'Sanskrit (संस्कृतम्)',
    'English',
  ];

  bool _showInsightsHistory = true;
  bool _showTranslationHistory = true;

  final List<Map<String, dynamic>> _insightsHistory = [
    {
      'docName': 'Tender_NIT_NHAI_BRG_2026_Vol_II_Specs.pdf',
      'pages': 86,
      'size': '34.2 MB',
      'extractedPages': 24,
      'distillationRatio': '27.9%',
      'timestamp': 'Today, 11:20 AM',
      'clausesFound': 14,
      'hash': 'sha256-a1b2c3d4e5f60718',
    },
    {
      'docName': 'FIDIC_Yellow_Book_Conditions_Schedule_C.pdf',
      'pages': 142,
      'size': '48.1 MB',
      'extractedPages': 38,
      'distillationRatio': '26.7%',
      'timestamp': 'Yesterday, 03:40 PM',
      'clausesFound': 22,
      'hash': 'sha256-9e8d7c6b5a4f3e2d',
    },
    {
      'docName': 'IRC_SP_47_Cable_Stayed_Bridge_Guidelines.pdf',
      'pages': 64,
      'size': '19.5 MB',
      'extractedPages': 18,
      'distillationRatio': '28.1%',
      'timestamp': '03 Oct, 05:10 PM',
      'clausesFound': 9,
      'hash': 'sha256-3f2e1d0c9b8a7f6e',
    },
  ];

  final List<Map<String, dynamic>> _translationHistory = [
    {
      'docName': 'Tender_NIT_NHAI_BRG_2026_Vol_II_Specs.pdf',
      'targetLang': 'Hindi (हिन्दी)',
      'pages': 18,
      'status': '100% Translated',
      'tableFormatPreserved': true,
      'timestamp': 'Today, 11:32 AM',
      'token': 'DL-PDF-HI-9821',
    },
    {
      'docName': 'Pier_24_Caisson_Steining_Procedure.pdf',
      'targetLang': 'Assamese (অসমীয়া)',
      'pages': 12,
      'status': '100% Translated',
      'tableFormatPreserved': true,
      'timestamp': 'Yesterday, 02:15 PM',
      'token': 'DL-PDF-AS-7740',
    },
    {
      'docName': 'Cable_Tensioning_Safety_Checklist.pdf',
      'targetLang': 'Bengali (বাংলা)',
      'pages': 8,
      'status': '100% Translated',
      'tableFormatPreserved': true,
      'timestamp': '04 Oct, 09:50 AM',
      'token': 'DL-PDF-BN-6612',
    },
  ];

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

  void _triggerPdfAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _hasAnalyzed = false;
    });

    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;
    setState(() {
      _isAnalyzing = false;
      _hasAnalyzed = true;
    });
  }

  void _triggerPageTranslation() async {
    setState(() {
      _isTranslating = true;
      _hasTranslated = false;
      _translationProgressPage = 1;
    });

    for (int p = 1; p <= _totalDocPages; p++) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() {
        _translationProgressPage = p;
      });
    }

    if (!mounted) return;
    setState(() {
      _isTranslating = false;
      _hasTranslated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final projectName = provider.currentProject?.name ?? 'Brahmaputra River Multi-Span Bridge Package II';

    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tender PDF AI Intelligence & Translation',
              style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Zero-Manipulation Insights & Layout-Preserved Multi-Language Engine',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(icon: Icon(Icons.table_chart_rounded, size: 20), text: 'Structured Insights (15-40%)'),
            Tab(icon: Icon(Icons.g_translate_rounded, size: 20), text: 'Page-by-Page Translation'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInsightsTab(projectName),
          _buildTranslationTab(),
        ],
      ),
    );
  }

  // --- TAB 1: STRUCTURED PDF INSIGHTS ---
  Widget _buildInsightsTab(String projectName) {
    final List<Widget> items = [];

    // Document Banner
    items.add(
      Container(
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tender_NIT_NHAI_BRG_2026_Vol_II_Specs.pdf',
                        style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Size: 34.2 MB • 86 Pages • Project: $projectName',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isAnalyzing ? null : _triggerPdfAnalysis,
                    icon: _isAnalyzing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.psychology_rounded, size: 18),
                    label: Text(
                      _isAnalyzing ? 'Extracting Zero-Loss Data...' : 'Extract Key Insights (No Manipulation)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    items.add(const SizedBox(height: 16));

    if (_hasAnalyzed) {
      // Distillation KPI Summary
      items.add(
        Row(
          children: [
            Expanded(
              child: _buildMetricPill(
                'Distillation Ratio',
                '28.4% Essential',
                '71.6% Boilerplate Filtered',
                Icons.filter_alt_rounded,
                const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricPill(
                'Data Integrity',
                '100% Exact Numbers',
                '0 Alterations / Exact Match',
                Icons.verified_rounded,
                const Color(0xFF38BDF8),
              ),
            ),
          ],
        ),
      );

      items.add(const SizedBox(height: 16));

      // Executive Scope & Critical Milestones
      items.add(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF162347),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF26396E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.flag_rounded, color: Color(0xFFFFB95F), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Tender Milestones & Liquidated Damages (Clause 8.7)',
                    style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMilestoneRow('Milestone 1', 'Substructure Well Sinking (P1-P24)', 'Month 8', '0.05% per day delay'),
              _buildMilestoneRow('Milestone 2', 'Pylon P-24 Concrete & Cable Anchors', 'Month 16', '0.075% per day delay'),
              _buildMilestoneRow('Milestone 3', 'Full Deck Stitching & Static Load Test', 'Month 24', 'Max 10% Contract Price cap'),
            ],
          ),
        ),
      );

      items.add(const SizedBox(height: 16));

      // PRESERVED DATA TABLE (Bill of Quantities / Key Tolerances)
      items.add(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF162347),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF26396E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.table_view_rounded, color: Color(0xFF10B981), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Preserved BOQ Table (Original Formatting Preserved)',
                    style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Extracted directly from Page 42 Table 4.1 without any rounding or alteration',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFF111C38)),
                  dataRowColor: WidgetStateProperty.all(const Color(0xFF162347)),
                  border: TableBorder.all(color: const Color(0xFF26396E), borderRadius: BorderRadius.circular(8)),
                  columns: const [
                    DataColumn(label: Text('Item #', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11))),
                    DataColumn(label: Text('Description of Work', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11))),
                    DataColumn(label: Text('Quantity', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11))),
                    DataColumn(label: Text('Unit', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11))),
                    DataColumn(label: Text('Specified Tolerance', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11))),
                  ],
                  rows: const [
                    DataRow(cells: [
                      DataCell(Text('03.02.01', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 11, fontFamily: 'monospace'))),
                      DataCell(Text('M60 Grade Self-Compacting Concrete Pier', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 11))),
                      DataCell(Text('14,250.00', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace'))),
                      DataCell(Text('cum', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11))),
                      DataCell(Text('± 5 mm / IS 456', style: TextStyle(color: Color(0xFFFFB95F), fontSize: 11, fontFamily: 'monospace'))),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('03.02.04', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 11, fontFamily: 'monospace'))),
                      DataCell(Text('Fe550D Corrosion Resistant Thermo Rebar', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 11))),
                      DataCell(Text('3,820.50', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace'))),
                      DataCell(Text('MT', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11))),
                      DataCell(Text('± 2 mm Cover / IRC:112', style: TextStyle(color: Color(0xFFFFB95F), fontSize: 11, fontFamily: 'monospace'))),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('04.01.12', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 11, fontFamily: 'monospace'))),
                      DataCell(Text('1860 MPa High Tensile Stay Cable Strands', style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 11))),
                      DataCell(Text('840.00', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace'))),
                      DataCell(Text('Tons', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11))),
                      DataCell(Text('Zero Relaxation / IRC:SP:47', style: TextStyle(color: Color(0xFFFFB95F), fontSize: 11, fontFamily: 'monospace'))),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      items.add(
        Container(
          padding: const EdgeInsets.all(32),
          alignment: Alignment.center,
          child: const Column(
            children: [
              Icon(Icons.auto_stories_rounded, size: 48, color: Color(0xFF26396E)),
              SizedBox(height: 12),
              Text(
                'Tap "Extract Key Insights" to parse all 86 pages of this tender PDF into structured milestones and tables without data manipulation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    items.add(const SizedBox(height: 16));
    items.add(_buildInsightsHistorySection());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: items,
    );
  }

  // --- TAB 2: PAGE-BY-PAGE TRANSLATION ---
  Widget _buildTranslationTab() {
    final List<Widget> items = [];

    // Language Selector Card
    items.add(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF162347),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF26396E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TARGET NATIVE LANGUAGE FOR 1-TO-1 PAGE TRANSLATION',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1326),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF26396E)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTargetLanguage,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF162347),
                  style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 14, fontWeight: FontWeight.bold),
                  items: _targetLanguages.map((lang) {
                    return DropdownMenuItem(value: lang, child: Text(lang));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedTargetLanguage = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Protocol: Each page (1..N) is translated individually. If a page has a table, the exact table format is preserved with numbers unchanged.',
              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isTranslating ? null : _triggerPageTranslation,
                    icon: _isTranslating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.translate_rounded, size: 18),
                    label: Text(
                      _isTranslating ? 'Translating Page $_translationProgressPage / $_totalDocPages...' : 'Translate Entire PDF (Page-Preserving)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    items.add(const SizedBox(height: 16));

    if (_isTranslating) {
      items.add(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF162347),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Translating Page $_translationProgressPage of $_totalDocPages', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('${((_translationProgressPage / _totalDocPages) * 100).toInt()}%', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _translationProgressPage / _totalDocPages,
                backgroundColor: const Color(0xFF0B1326),
                color: const Color(0xFF10B981),
              ),
            ],
          ),
        ),
      );
      items.add(const SizedBox(height: 16));
    }

    if (_hasTranslated) {
      // Download / Share Banner
      items.add(
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Translation Complete (18 Pages -> 18 Pages)', style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('All tables, headers, and numeric tolerances strictly maintained.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading translated PDF with preserved tables...')),
                  );
                },
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Save PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );

      items.add(const SizedBox(height: 16));

      // Side-by-side Page Preview (Original vs Translated)
      items.add(
        const Text(
          'SIDE-BY-SIDE PAGE COMPARISON (PAGE 1 EXAMPLE)',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      );
      items.add(const SizedBox(height: 8));

      items.add(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF162347),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF26396E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.compare_rounded, color: Color(0xFF38BDF8), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Page 1: Scope of Work & Structural Specifications',
                    style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Side by Side Cards
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // English
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1326),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF26396E)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ORIGINAL (ENGLISH)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text(
                            'The Contractor shall execute the construction of the 2.4 km four-lane river bridge including substructure well foundations down to -54.0m scour level, Pier P-24 M60 caps, and stay cables under IRC:SP:47.',
                            style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 11, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Translated Hindi
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1326),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TRANSLATED (HINDI)', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text(
                            'ठेकेदार -54.0m गहराई तक कुआं नींव (वेल फाउंडेशन), पियर P-24 M60 कंक्रीट कैप्स, और IRC:SP:47 के तहत केबल-स्टेड तारों सहित 2.4 km चार-लेन नदी पुल का निर्माण निष्पादित करेगा।',
                            style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 11, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    items.add(const SizedBox(height: 16));
    items.add(_buildTranslationHistorySection());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: items,
    );
  }

  Widget _buildMetricPill(String title, String val, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26396E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow(String title, String scope, String time, String penalty) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB95F).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(title, style: const TextStyle(color: Color(0xFFFFB95F), fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scope, style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 11, fontWeight: FontWeight.w600)),
                Text('Deadline: $time • Liquidated Damages: $penalty', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsHistorySection() {
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
          InkWell(
            onTap: () => setState(() => _showInsightsHistory = !_showInsightsHistory),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_edu_rounded, color: Color(0xFF38BDF8), size: 20),
                    const SizedBox(width: 8),
                    const Text('Tender PDF Intelligence & OCR History', style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_insightsHistory.length}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Icon(_showInsightsHistory ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF94A3B8)),
              ],
            ),
          ),
          if (_showInsightsHistory) ...[
            const SizedBox(height: 12),
            const Text(
              'Past tender analyses with strict 15–40% distillation and zero-manipulation verification logs.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _insightsHistory.length,
              separatorBuilder: (_, _) => const Divider(color: Color(0xFF26396E), height: 16),
              itemBuilder: (context, index) {
                final item = _insightsHistory[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['docName'],
                            style: const TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(item['distillationRatio'], style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${item['pages']} Pages • ${item['size']} • Extracted: ${item['extractedPages']} Pages (${item['clausesFound']} Clauses) • ${item['timestamp']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(item['hash'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 9, fontFamily: 'monospace')),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTranslationHistorySection() {
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
          InkWell(
            onTap: () => setState(() => _showTranslationHistory = !_showTranslationHistory),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.manage_history_rounded, color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 8),
                    const Text('PDF Translation History & Download Archive', style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_translationHistory.length}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Icon(_showTranslationHistory ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF94A3B8)),
              ],
            ),
          ),
          if (_showTranslationHistory) ...[
            const SizedBox(height: 12),
            const Text(
              'Sequential page-by-page translated documents with preserved table formats ready for download.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _translationHistory.length,
              separatorBuilder: (_, _) => const Divider(color: Color(0xFF26396E), height: 16),
              itemBuilder: (context, index) {
                final item = _translationHistory[index];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['docName'], style: const TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text('Target: ${item['targetLang']} • ${item['pages']} Pages • ${item['timestamp']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Table Format Preserved ✅', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Text(item['token'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 9, fontFamily: 'monospace')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.file_download_outlined, color: Color(0xFF38BDF8), size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Downloading ${item['docName']} (${item['targetLang']})...')),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
