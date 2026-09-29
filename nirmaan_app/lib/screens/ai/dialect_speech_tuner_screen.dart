import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Representation of an Indic dialect / acoustic model profile.
class DialectProfile {
  final String id;
  final String name;
  final String nativeName;
  final String localeCode;
  final String acousticModel;
  final String description;
  final String region;
  final int codeMixedRate;
  final double confidence;
  final Color accentColor;
  final List<SamplePhrase> samplePhrases;

  const DialectProfile({
    required this.id,
    required this.name,
    required this.nativeName,
    required this.localeCode,
    required this.acousticModel,
    required this.description,
    required this.region,
    required this.codeMixedRate,
    required this.confidence,
    required this.accentColor,
    required this.samplePhrases,
  });
}

/// Pre-configured sample industrial sentence for acoustic testing.
class SamplePhrase {
  final String text;
  final String translation;
  final List<EntityHighlight> expectedEntities;

  const SamplePhrase({
    required this.text,
    required this.translation,
    required this.expectedEntities,
  });
}

/// Construction domain lexicon dictionary entry.
class LexiconItem {
  final String id;
  final String term;
  final String devanagari;
  final String category;
  final String entityType;
  final String definition;
  final String standardRef;
  final List<String> aliases;
  double boostDb;
  bool isEnabled;
  final bool isCustom;
  final Color color;

  LexiconItem({
    required this.id,
    required this.term,
    required this.devanagari,
    required this.category,
    required this.entityType,
    required this.definition,
    required this.standardRef,
    required this.aliases,
    required this.boostDb,
    this.isEnabled = true,
    this.isCustom = false,
    required this.color,
  });
}

/// Tagged entity extracted from acoustic transcription.
class EntityHighlight {
  final String token;
  final String entityType;
  final String standardCategory;
  final double confidence;
  final Color color;
  final IconData icon;

  const EntityHighlight({
    required this.token,
    required this.entityType,
    required this.standardCategory,
    required this.confidence,
    required this.color,
    required this.icon,
  });
}

class DialectSpeechTunerScreen extends StatefulWidget {
  const DialectSpeechTunerScreen({super.key});

  @override
  State<DialectSpeechTunerScreen> createState() => _DialectSpeechTunerScreenState();
}

class _DialectSpeechTunerScreenState extends State<DialectSpeechTunerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _waveformAnimController;

  // Selected Dialect
  late DialectProfile _selectedDialect;

  // Acoustic Calibration Parameters
  double _noiseSuppressionDb = 24.0;
  double _acousticGain = 1.4;
  double _codeSwitchTolerance = 75.0;
  bool _hotwordBoostingActive = true;
  bool _plantTurbomachineryFilter = true;

  // Lexicon Search & Filter
  String _lexiconSearchQuery = '';
  String _selectedLexiconCategory = 'ALL';

  // Voice Test Recorder State
  bool _isRecording = false;
  bool _isDecoding = false;
  Timer? _recordingTimer;
  int _recordingMilliseconds = 0;
  String _transcribedText = '';
  List<EntityHighlight> _detectedEntities = [];
  double _currentWerScore = 1.6;
  int _acousticLatencyMs = 114;

  // Dialects List
  final List<DialectProfile> _dialects = const [
    DialectProfile(
      id: 'hindi',
      name: 'Hindi (Standard)',
      nativeName: 'मानक हिन्दी',
      localeCode: 'hi-IN',
      acousticModel: 'Bhashini-ASR-Hi-Industrial (v3.4)',
      description: 'Formal site diary, PSU client meetings, CPWD specs.',
      region: 'Northern Industrial Belt (UP, Delhi NCR, MP, Rajasthan)',
      codeMixedRate: 14,
      confidence: 99.2,
      accentColor: AppTheme.primary,
      samplePhrases: [
        SamplePhrase(
          text: 'जोन 4 में 32 इंच पाइप स्पूल का फिटअप पूरा हो गया है, टांका वेल्डिंग चालू है।',
          translation: 'Zone 4 32-inch pipe spool fitup completed, tack welding in progress.',
          expectedEntities: [
            EntityHighlight(
              token: 'पाइप स्पूल',
              entityType: 'COMPONENT',
              standardCategory: 'Spool',
              confidence: 99.4,
              color: AppTheme.primaryLight,
              icon: Icons.precision_manufacturing_rounded,
            ),
            EntityHighlight(
              token: 'फिटअप',
              entityType: 'INSPECTION',
              standardCategory: 'Fitup',
              confidence: 98.7,
              color: AppTheme.secondary,
              icon: Icons.checklist_rounded,
            ),
            EntityHighlight(
              token: 'टांका वेल्डिंग',
              entityType: 'PROCESS',
              standardCategory: 'Tack Weld',
              confidence: 97.9,
              color: AppTheme.tertiary,
              icon: Icons.fireplace_rounded,
            ),
          ],
        ),
        SamplePhrase(
          text: 'हाइड्रोटेस्ट 150 बार प्रेशर पर 24 घंटे के लिए होल्ड रखा गया है।',
          translation: 'Hydrotest holding at 150 bar pressure for 24 hours.',
          expectedEntities: [
            EntityHighlight(
              token: 'हाइड्रोटेस्ट',
              entityType: 'QA STAGE',
              standardCategory: 'Hydrotest',
              confidence: 99.1,
              color: Color(0xFFF43F5E),
              icon: Icons.speed_rounded,
            ),
            EntityHighlight(
              token: '150 बार',
              entityType: 'METRIC',
              standardCategory: 'Pressure',
              confidence: 96.5,
              color: AppTheme.secondary,
              icon: Icons.straighten_rounded,
            ),
          ],
        ),
        SamplePhrase(
          text: '3LPE कोटिंग के बाद हॉलिडे चेकिंग में कोई पिनहोल डिफेक्ट नहीं मिला।',
          translation: 'No pinhole defects found in holiday checking after 3LPE coating.',
          expectedEntities: [
            EntityHighlight(
              token: 'हॉलिडे चेकिंग',
              entityType: 'NDT CHECK',
              standardCategory: 'Holiday Detection',
              confidence: 98.4,
              color: Color(0xFFA855F7),
              icon: Icons.flash_on_rounded,
            ),
          ],
        ),
      ],
    ),
    DialectProfile(
      id: 'hinglish',
      name: 'Hinglish (Site Jargon)',
      nativeName: 'साइट जार्गन / Hinglish',
      localeCode: 'hi-Latn-IN',
      acousticModel: 'IndicConformer-Hinglish-Industrial (v4.1)',
      description: 'Heavy code-switching used by mechanical pipefitters & foremen.',
      region: 'Pan-India Piping Yards, Refineries & Cross-Country Spreads',
      codeMixedRate: 78,
      confidence: 98.4,
      accentColor: AppTheme.secondary,
      samplePhrases: [
        SamplePhrase(
          text: 'Line 7B pe spool ka fitup check pass ho gaya, tack weld abhi complete kiya.',
          translation: 'Spool fitup passed on Line 7B, tack weld completed just now.',
          expectedEntities: [
            EntityHighlight(
              token: 'spool',
              entityType: 'COMPONENT',
              standardCategory: 'Spool',
              confidence: 99.1,
              color: AppTheme.primaryLight,
              icon: Icons.precision_manufacturing_rounded,
            ),
            EntityHighlight(
              token: 'fitup',
              entityType: 'INSPECTION',
              standardCategory: 'Fitup',
              confidence: 99.0,
              color: AppTheme.secondary,
              icon: Icons.checklist_rounded,
            ),
            EntityHighlight(
              token: 'tack weld',
              entityType: 'PROCESS',
              standardCategory: 'Tack Weld',
              confidence: 98.3,
              color: AppTheme.tertiary,
              icon: Icons.fireplace_rounded,
            ),
          ],
        ),
        SamplePhrase(
          text: 'Hydrotest manifold ready hai, holiday detection 15kV spark test approve ho gaya.',
          translation: 'Hydrotest manifold ready, holiday detection 15kV spark test approved.',
          expectedEntities: [
            EntityHighlight(
              token: 'Hydrotest',
              entityType: 'QA STAGE',
              standardCategory: 'Hydrotest',
              confidence: 99.5,
              color: Color(0xFFF43F5E),
              icon: Icons.speed_rounded,
            ),
            EntityHighlight(
              token: 'holiday detection',
              entityType: 'NDT CHECK',
              standardCategory: 'Holiday Detection',
              confidence: 98.9,
              color: Color(0xFFA855F7),
              icon: Icons.flash_on_rounded,
            ),
          ],
        ),
      ],
    ),
    DialectProfile(
      id: 'assamese',
      name: 'Assamese (অসমীয়া)',
      nativeName: 'অসমীয়া',
      localeCode: 'as-IN',
      acousticModel: 'Bhashini-ASR-As-Refinery (v2.2)',
      description: 'Brahmaputra HDD river crossings, Numaligarh (NRL), Digboi sites.',
      region: 'Upper Assam Corridor & North-East Gas Grid (NEGG)',
      codeMixedRate: 26,
      confidence: 97.1,
      accentColor: AppTheme.tertiary,
      samplePhrases: [
        SamplePhrase(
          text: 'ব্ৰহ্মপুত্ৰ ক্ৰছিংৰ পাইপ স্পুলৰ ফিটআপ সম্পূৰ্ণ হ\'ল, এতিয়া হাইড্ৰ\'টেষ্ট চলি আছে।',
          translation: 'Brahmaputra crossing pipe spool fitup complete, hydrotest now ongoing.',
          expectedEntities: [
            EntityHighlight(
              token: 'স্পুলৰ',
              entityType: 'COMPONENT',
              standardCategory: 'Spool',
              confidence: 97.6,
              color: AppTheme.primaryLight,
              icon: Icons.precision_manufacturing_rounded,
            ),
            EntityHighlight(
              token: 'ফিটআপ',
              entityType: 'INSPECTION',
              standardCategory: 'Fitup',
              confidence: 98.2,
              color: AppTheme.secondary,
              icon: Icons.checklist_rounded,
            ),
            EntityHighlight(
              token: 'হাইড্ৰ\'টেষ্ট',
              entityType: 'QA STAGE',
              standardCategory: 'Hydrotest',
              confidence: 98.8,
              color: Color(0xFFF43F5E),
              icon: Icons.speed_rounded,
            ),
          ],
        ),
      ],
    ),
    DialectProfile(
      id: 'bhojpuri',
      name: 'Bhojpuri (भोजपुरी)',
      nativeName: 'भोजपुरी',
      localeCode: 'bho-IN',
      acousticModel: 'PurvanchalConformer-Bho-Pipeline (v2.8)',
      description: 'Cross-country trenching, stringing, downhill welder crews.',
      region: 'Purvanchal Expressway, Bihar Pipeline & Eastern Corridor',
      codeMixedRate: 42,
      confidence: 97.8,
      accentColor: Color(0xFFF97316),
      samplePhrases: [
        SamplePhrase(
          text: 'नदी पार वाला 16-इंच स्पूल के फिटअप हो गइल, अब टांका लगावे के बा।',
          translation: 'River-crossing 16-inch spool fitup is done, tack weld to be placed now.',
          expectedEntities: [
            EntityHighlight(
              token: 'स्पूल',
              entityType: 'COMPONENT',
              standardCategory: 'Spool',
              confidence: 98.9,
              color: AppTheme.primaryLight,
              icon: Icons.precision_manufacturing_rounded,
            ),
            EntityHighlight(
              token: 'फिटअप',
              entityType: 'INSPECTION',
              standardCategory: 'Fitup',
              confidence: 98.4,
              color: AppTheme.secondary,
              icon: Icons.checklist_rounded,
            ),
            EntityHighlight(
              token: 'टांका',
              entityType: 'PROCESS',
              standardCategory: 'Tack Weld',
              confidence: 97.6,
              color: AppTheme.tertiary,
              icon: Icons.fireplace_rounded,
            ),
          ],
        ),
        SamplePhrase(
          text: 'हाइड्रोटेस्ट खातिर पानी भरल गइल बा, हॉलिडे चेकिंग में सब क्लियर बा।',
          translation: 'Water filled for hydrotest, holiday checking is completely clear.',
          expectedEntities: [
            EntityHighlight(
              token: 'हाइड्रोटेस्ट',
              entityType: 'QA STAGE',
              standardCategory: 'Hydrotest',
              confidence: 99.2,
              color: Color(0xFFF43F5E),
              icon: Icons.speed_rounded,
            ),
            EntityHighlight(
              token: 'हॉलिडे चेकिंग',
              entityType: 'NDT CHECK',
              standardCategory: 'Holiday Detection',
              confidence: 98.1,
              color: Color(0xFFA855F7),
              icon: Icons.flash_on_rounded,
            ),
          ],
        ),
      ],
    ),
    DialectProfile(
      id: 'bengali',
      name: 'Bengali (বাংলা)',
      nativeName: 'বাংলা',
      localeCode: 'bn-IN',
      acousticModel: 'BanglaSpeech-ASR-Yard (v3.0)',
      description: 'Haldia dock, petrochemical expansion, fabrication shop floor.',
      region: 'West Bengal Industrial Hub, Haldia, Kolkata Port',
      codeMixedRate: 34,
      confidence: 98.3,
      accentColor: Color(0xFFA855F7),
      samplePhrases: [
        SamplePhrase(
          text: 'হালদিয়া টার্মিনালের স্পুল ফিটআপ কমপ্লিট, কালকে হলিডে ডিটেকশন শুরু হবে।',
          translation: 'Haldia terminal spool fitup complete, holiday detection starts tomorrow.',
          expectedEntities: [
            EntityHighlight(
              token: 'স্পুল',
              entityType: 'COMPONENT',
              standardCategory: 'Spool',
              confidence: 98.5,
              color: AppTheme.primaryLight,
              icon: Icons.precision_manufacturing_rounded,
            ),
            EntityHighlight(
              token: 'ফিটআপ',
              entityType: 'INSPECTION',
              standardCategory: 'Fitup',
              confidence: 98.9,
              color: AppTheme.secondary,
              icon: Icons.checklist_rounded,
            ),
            EntityHighlight(
              token: 'হলিডে ডিটেকশন',
              entityType: 'NDT CHECK',
              standardCategory: 'Holiday Detection',
              confidence: 99.0,
              color: Color(0xFFA855F7),
              icon: Icons.flash_on_rounded,
            ),
          ],
        ),
      ],
    ),
  ];

  // Construction Terminology Lexicon Dictionary
  late List<LexiconItem> _lexicon;

  @override
  void initState() {
    super.initState();
    _selectedDialect = _dialects[1]; // Default to Hinglish (Site Jargon)
    _tabController = TabController(length: 3, vsync: this);

    _waveformAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _initializeLexicon();
  }

  void _initializeLexicon() {
    _lexicon = [
      LexiconItem(
        id: 'spool',
        term: 'Spool',
        devanagari: 'पाइप स्पूल',
        category: 'Piping',
        entityType: 'EQUIPMENT / COMPONENT',
        definition:
            'Pre-fabricated piping assembly segment including pipes, flanges, elbows, and fittings fabricated in shop prior to field erection.',
        standardRef: 'ASME B31.3 / B31.8 Ch V',
        aliases: ['spool', 'ispool', 'पाइप स्पूल', 'स्पूल पाइप', 'পাইপ স্পুল', 'pipe spool'],
        boostDb: 4.5,
        color: AppTheme.primaryLight,
      ),
      LexiconItem(
        id: 'fitup',
        term: 'Fitup',
        devanagari: 'फिटअप',
        category: 'Welding',
        entityType: 'INSPECTION / QA-QC',
        definition:
            'Dimensional inspection of bevel angle, root gap (2.5 - 3.2 mm), and hi-lo internal misalignment prior to deposition of tack welds.',
        standardRef: 'API 1104 Sec 6.2 / ASME Sec IX',
        aliases: ['fitup', 'fit up', 'फिटअप', 'फिटर चेकिंग', 'ফিটআপ', 'bevel fitup'],
        boostDb: 4.8,
        color: AppTheme.secondary,
      ),
      LexiconItem(
        id: 'tack_weld',
        term: 'Tack Weld',
        devanagari: 'टांका वेल्डिंग',
        category: 'Welding',
        entityType: 'PROCESS / WELD',
        definition:
            'Discontinuous temporary weld beads applied to bridge and hold joint geometry and alignment intact prior to final root pass.',
        standardRef: 'AWS D1.1 / ASME Sec IX QW-400',
        aliases: ['tack weld', 'tack', 'टांका वेल्डिंग', 'टांका मारना', 'ট্যাক', 'bridge tack'],
        boostDb: 4.0,
        color: AppTheme.tertiary,
      ),
      LexiconItem(
        id: 'hydrotest',
        term: 'Hydrotest',
        devanagari: 'हाइड्रोटेस्ट',
        category: 'Integrity',
        entityType: 'QA MILESTONE / TEST',
        definition:
            'Hydrostatic integrity and leak proof test performed by charging pipe with de-oxygenated water up to 1.5x design pressure for 24-hr hold.',
        standardRef: 'ASME B31.8 Ch VIII / OISD-141',
        aliases: ['hydrotest', 'hydro test', 'हाइड्रोटेस्ट', 'प्रेशर टेस्ट', 'হাইড্ৰ\'টেষ্ট', 'water pressure'],
        boostDb: 5.2,
        color: const Color(0xFFF43F5E),
      ),
      LexiconItem(
        id: 'holiday_detection',
        term: 'Holiday Detection',
        devanagari: 'हॉलिडे चेकिंग',
        category: 'NDT',
        entityType: 'NDT INSPECTION / DEFECT',
        definition:
            'High-voltage non-destructive spark flaw test (12kV to 25kV) across 3LPE/FBE external pipe coating to detect micro-pinholes or holidays.',
        standardRef: 'NACE SP0188 / ASTM G62',
        aliases: ['holiday detection', 'holiday checking', 'हॉलिडे चेकिंग', 'हॉलिडे डिटेक्शन', 'হলিডে', 'spark test'],
        boostDb: 4.6,
        color: const Color(0xFFA855F7),
      ),
      LexiconItem(
        id: 'ndt_radiography',
        term: 'NDT Radiography (RT)',
        devanagari: 'एक्स-रे टेस्टिंग (RT)',
        category: 'NDT',
        entityType: 'NDT QUALITY',
        definition:
            'Gamma/X-ray radiographic film examination of circumferential girth weld joints to identify slag inclusions, porosity, or lack of penetration.',
        standardRef: 'API 1104 Sec 11 / ASME Sec V',
        aliases: ['radiography', 'rt test', 'x-ray', 'एक्स-रे', 'রেডিওগ্রাফি'],
        boostDb: 3.8,
        color: Colors.amber,
      ),
      LexiconItem(
        id: 'tie_in',
        term: 'Tie-In',
        devanagari: 'टाई-इन वेल्डिंग',
        category: 'Piping',
        entityType: 'MILESTONE',
        definition:
            'Final underground closure weld connecting two long pipeline continuous test sections or connecting mainline pipe to valve station manifold.',
        standardRef: 'API 1104 Golden Weld Spec',
        aliases: ['tie-in', 'golden weld', 'टाई-इन', 'টাই-ইন'],
        boostDb: 4.1,
        color: Colors.tealAccent,
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _waveformAnimController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  // --- Voice Recorder & Simulated Acoustic Decoding ---
  void _startRecording({SamplePhrase? sample}) {
    setState(() {
      _isRecording = true;
      _isDecoding = false;
      _recordingMilliseconds = 0;
      _transcribedText = '';
      _detectedEntities = [];
    });

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _recordingMilliseconds += 100;
      });
      if (_recordingMilliseconds >= 3200) {
        _stopRecording(sample: sample);
      }
    });
  }

  void _stopRecording({SamplePhrase? sample}) {
    _recordingTimer?.cancel();
    setState(() {
      _isRecording = false;
      _isDecoding = true;
    });

    // High fidelity acoustic decoding simulation
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final targetPhrase = sample ?? _selectedDialect.samplePhrases.first;

      setState(() {
        _isDecoding = false;
        _transcribedText = targetPhrase.text;
        _detectedEntities = targetPhrase.expectedEntities;
        _currentWerScore = math.max(0.8, (math.Random().nextDouble() * 1.8)).toDouble();
        _acousticLatencyMs = 95 + math.Random().nextInt(40);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.tertiary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Acoustic decode complete: ${_detectedEntities.length} lexicon entities mapped [WER: ${_currentWerScore.toStringAsFixed(1)}%]',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.surfaceContainerHigh,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  void _openAddLexiconDialog() {
    final termController = TextEditingController();
    final devanagariController = TextEditingController();
    final defController = TextEditingController();
    final aliasesController = TextEditingController();
    String category = 'Piping';
    String entityType = 'EQUIPMENT / COMPONENT';
    double boost = 4.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppTheme.border),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Register Custom Site Lexicon',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: termController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Standard Term (English)',
                        hintText: 'e.g. Downhill Weld, Casing Spacer',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: devanagariController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Native Transliteration / Jargon',
                        hintText: 'e.g. डाउनहिल वेल्डिंग, केसिंग स्पेसर',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: category,
                            dropdownColor: AppTheme.surfaceCard,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                            decoration: const InputDecoration(labelText: 'Trade Category'),
                            items: ['Piping', 'Welding', 'Integrity', 'NDT', 'Civil', 'HSE']
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => category = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: entityType,
                            dropdownColor: AppTheme.surfaceCard,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                            decoration: const InputDecoration(labelText: 'Entity Class'),
                            items: [
                              'EQUIPMENT / COMPONENT',
                              'INSPECTION / QA-QC',
                              'PROCESS / WELD',
                              'QA MILESTONE / TEST',
                              'METRIC / PARAMETER'
                            ]
                                .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => entityType = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: aliasesController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Phonetic Aliases (Comma-separated)',
                        hintText: 'e.g. downhill, root-pass, 5G weld',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: defController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Industrial Technical Definition',
                        hintText: 'Standard pipeline spec definition',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Acoustic Hotword Boost: +${boost.toStringAsFixed(1)} dB',
                          style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const Text(
                          'High Priority Bias',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    Slider(
                      value: boost,
                      min: 1.0,
                      max: 6.0,
                      divisions: 10,
                      activeColor: AppTheme.primaryLight,
                      inactiveColor: AppTheme.border,
                      onChanged: (v) => setModalState(() => boost = v),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Add to Active Lexicon Dictionary'),
                        onPressed: () {
                          if (termController.text.trim().isEmpty) return;
                          final newAliases = aliasesController.text
                              .split(',')
                              .map((a) => a.trim())
                              .where((a) => a.isNotEmpty)
                              .toList();
                          if (newAliases.isEmpty) newAliases.add(termController.text.toLowerCase());

                          setState(() {
                            _lexicon.insert(
                              0,
                              LexiconItem(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                term: termController.text.trim(),
                                devanagari: devanagariController.text.trim().isEmpty
                                    ? termController.text.trim()
                                    : devanagariController.text.trim(),
                                category: category,
                                entityType: entityType,
                                definition: defController.text.trim().isEmpty
                                    ? 'Custom registered site lexicon term.'
                                    : defController.text.trim(),
                                standardRef: 'Project Site Custom',
                                aliases: newAliases,
                                boostDb: boost,
                                isCustom: true,
                                color: AppTheme.primaryLight,
                              ),
                            );
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added "${termController.text.trim()}" to site acoustic dictionary!'),
                              backgroundColor: AppTheme.surfaceContainerHigh,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openCalibrationDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppTheme.border),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Acoustic Front-End Calibration',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Plant Noise Suppression', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                      Text('-${_noiseSuppressionDb.toStringAsFixed(0)} dB', style: const TextStyle(color: AppTheme.tertiary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Slider(
                    value: _noiseSuppressionDb,
                    min: 6.0,
                    max: 36.0,
                    divisions: 10,
                    activeColor: AppTheme.tertiary,
                    inactiveColor: AppTheme.border,
                    onChanged: (v) {
                      setModalState(() => _noiseSuppressionDb = v);
                      setState(() => _noiseSuppressionDb = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Acoustic Mic Input Gain', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                      Text('${_acousticGain.toStringAsFixed(1)}x', style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Slider(
                    value: _acousticGain,
                    min: 0.8,
                    max: 2.5,
                    divisions: 17,
                    activeColor: AppTheme.primaryLight,
                    inactiveColor: AppTheme.border,
                    onChanged: (v) {
                      setModalState(() => _acousticGain = v);
                      setState(() => _acousticGain = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Code-Switching Tolerance', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                      Text('${_codeSwitchTolerance.toStringAsFixed(0)}%', style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Slider(
                    value: _codeSwitchTolerance,
                    min: 20.0,
                    max: 100.0,
                    divisions: 16,
                    activeColor: AppTheme.secondary,
                    inactiveColor: AppTheme.border,
                    onChanged: (v) {
                      setModalState(() => _codeSwitchTolerance = v);
                      setState(() => _codeSwitchTolerance = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Turbomachinery Bandpass Filter', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                    subtitle: const Text('Notch filter at 400Hz - 1.2kHz generator hum', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    value: _plantTurbomachineryFilter,
                    activeThumbColor: AppTheme.primaryLight,
                    onChanged: (v) {
                      setModalState(() => _plantTurbomachineryFilter = v);
                      setState(() => _plantTurbomachineryFilter = v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hotword Decoder Bias', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                    subtitle: const Text('Inject +4.5dB phonetic priority for pipeline lexicon', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    value: _hotwordBoostingActive,
                    activeThumbColor: AppTheme.tertiary,
                    onChanged: (v) {
                      setModalState(() => _hotwordBoostingActive = v);
                      setState(() => _hotwordBoostingActive = v);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voice Dialect & Lexicon Tuner',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Indic Neural Engine v4.2 • ${_selectedDialect.name}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppTheme.primaryLight),
            tooltip: 'Acoustic Calibration',
            onPressed: _openCalibrationDialog,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt, color: AppTheme.textSecondary),
            tooltip: 'Reset to Factory Weights',
            onPressed: () {
              setState(() {
                _initializeLexicon();
                _noiseSuppressionDb = 24.0;
                _acousticGain = 1.4;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Acoustic model parameters reset to default.'),
                  backgroundColor: AppTheme.surfaceContainerHigh,
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryLight,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.translate, size: 18), text: 'Dialects'),
            Tab(icon: Icon(Icons.menu_book_rounded, size: 18), text: 'Lexicon'),
            Tab(icon: Icon(Icons.mic, size: 18), text: 'Test Bench'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Top Industrial Status Strip
          _buildAcousticEngineHeader(),

          // Main Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDialectSelectionTab(),
                _buildLexiconDictionaryTab(),
                _buildVoiceTestBenchTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Top Status Strip ---
  Widget _buildAcousticEngineHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              label: 'ACTIVE MODEL',
              value: _selectedDialect.acousticModel.split(' ').first,
              subtext: _selectedDialect.localeCode,
              color: _selectedDialect.accentColor,
            ),
          ),
          Container(width: 1, height: 28, color: AppTheme.border),
          Expanded(
            child: _buildMetricTile(
              label: 'BIASED TERMS',
              value: '${_lexicon.where((l) => l.isEnabled).length} Hotwords',
              subtext: '+4.5 dB Boost',
              color: AppTheme.tertiary,
            ),
          ),
          Container(width: 1, height: 28, color: AppTheme.border),
          Expanded(
            child: _buildMetricTile(
              label: 'NOISE FILTER',
              value: '-${_noiseSuppressionDb.toStringAsFixed(0)} dB',
              subtext: '400Hz Notch',
              color: AppTheme.secondary,
            ),
          ),
          Container(width: 1, height: 28, color: AppTheme.border),
          Expanded(
            child: _buildMetricTile(
              label: 'CONFIDENCE',
              value: '${_selectedDialect.confidence.toStringAsFixed(1)}%',
              subtext: 'WER ${_currentWerScore.toStringAsFixed(1)}%',
              color: AppTheme.primaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtext,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          subtext,
          style: const TextStyle(
            fontSize: 9,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 1: DIALECT SELECTION
  // ==========================================
  Widget _buildDialectSelectionTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Intro Notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.spatial_audio_off_rounded, color: AppTheme.primaryLight, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: const Text(
                  'Select the primary linguistic acoustic model calibrated for your project region. Models handle bilingual code-switching and noisy field walkie-talkie audio.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'REGIONAL SITE ACOUSTIC MODELS (5 SUPPORTED DIALECTS)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 10),

        ..._dialects.map((dialect) {
          final isSelected = dialect.id == _selectedDialect.id;
          return Card(
            color: isSelected ? AppTheme.surfaceContainerHigh : AppTheme.surfaceCard,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? dialect.accentColor : AppTheme.border,
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _selectedDialect = dialect;
                  _transcribedText = '';
                  _detectedEntities = [];
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Switched to ${dialect.name} acoustic model (${dialect.localeCode})'),
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: dialect.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: dialect.accentColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            dialect.localeCode,
                            style: TextStyle(
                              color: dialect.accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dialect.name,
                                style: TextStyle(
                                  color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                dialect.nativeName,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: dialect.accentColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.textMuted,
                                width: 2,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      dialect.description,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dialect.region,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.border, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('Code-Switching: ', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            Text('${dialect.codeMixedRate}%', style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Acoustic Match: ', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            Text('${dialect.confidence}%', style: TextStyle(fontSize: 11, color: dialect.accentColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Neural Model: ', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            Text(dialect.acousticModel.split('-').first, style: const TextStyle(fontSize: 11, color: AppTheme.primaryLight)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // TAB 2: LEXICON DICTIONARY
  // ==========================================
  Widget _buildLexiconDictionaryTab() {
    final filteredLexicon = _lexicon.where((item) {
      final matchesCategory = _selectedLexiconCategory == 'ALL' ||
          item.category.toUpperCase() == _selectedLexiconCategory.toUpperCase();
      final matchesSearch = _lexiconSearchQuery.isEmpty ||
          item.term.toLowerCase().contains(_lexiconSearchQuery.toLowerCase()) ||
          item.devanagari.contains(_lexiconSearchQuery) ||
          item.aliases.any((a) => a.toLowerCase().contains(_lexiconSearchQuery.toLowerCase()));
      return matchesCategory && matchesSearch;
    }).toList();

    final categories = ['ALL', 'PIPING', 'WELDING', 'INTEGRITY', 'NDT'];

    return Column(
      children: [
        // Search & Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _lexiconSearchQuery = val),
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search terms (Spool, फिटअप, Hydrotest...)',
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: _lexiconSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => setState(() => _lexiconSearchQuery = ''),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Term', style: TextStyle(fontSize: 12)),
                onPressed: _openAddLexiconDialog,
              ),
            ],
          ),
        ),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedLexiconCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryLight.withValues(alpha: 0.2),
                  backgroundColor: AppTheme.surfaceCard,
                  labelStyle: TextStyle(color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary),
                  side: BorderSide(color: isSelected ? AppTheme.primaryLight : AppTheme.border),
                  onSelected: (val) {
                    if (val) setState(() => _selectedLexiconCategory = cat);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 6),

        // Lexicon List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredLexicon.length,
            itemBuilder: (context, index) {
              final item = filteredLexicon[index];
              return Card(
                color: AppTheme.surfaceCard,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: item.isEnabled ? AppTheme.border : AppTheme.border.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.tag, color: item.color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item.term,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${item.devanagari})',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (item.isCustom) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('CUSTOM', style: TextStyle(fontSize: 9, color: AppTheme.primaryLight)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.entityType,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: item.color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item.standardRef,
                                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: item.isEnabled,
                            activeThumbColor: AppTheme.tertiary,
                            onChanged: (val) {
                              setState(() {
                                item.isEnabled = val;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.definition,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: item.aliases.map((alias) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Text(
                              '≈ $alias',
                              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                            ),
                          );
                        }).toList(),
                      ),
                      const Divider(color: AppTheme.border, height: 20),
                      Row(
                        children: [
                          const Icon(Icons.bolt, size: 14, color: AppTheme.primaryLight),
                          const SizedBox(width: 4),
                          Text(
                            'Hotword Priority Bias: +${item.boostDb.toStringAsFixed(1)} dB',
                            style: const TextStyle(fontSize: 11, color: AppTheme.primaryLight, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                            icon: const Icon(Icons.mic, size: 14, color: AppTheme.tertiary),
                            label: const Text('Test Term', style: TextStyle(fontSize: 11, color: AppTheme.tertiary)),
                            onPressed: () {
                              _tabController.animateTo(2);
                              _startRecording(
                                sample: SamplePhrase(
                                  text: 'Checking ${item.term} (${item.devanagari}) on mainline pipeline.',
                                  translation: 'Testing pronunciation for ${item.term}',
                                  expectedEntities: [
                                    EntityHighlight(
                                      token: item.term,
                                      entityType: item.entityType,
                                      standardCategory: item.term,
                                      confidence: 99.0,
                                      color: item.color,
                                      icon: Icons.tag,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: VOICE TEST BENCH & ENTITY TAGGER
  // ==========================================
  Widget _buildVoiceTestBenchTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Active Dialect Indicator Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _selectedDialect.accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _selectedDialect.accentColor.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.mic_external_on, color: _selectedDialect.accentColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tuning Bench: ${_selectedDialect.name}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedDialect.accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Model: ${_selectedDialect.acousticModel} • Hotword Bias: Active',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Change', style: TextStyle(fontSize: 11)),
                onPressed: () => _tabController.animateTo(0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Recorder Widget with Animated Soundwave
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isRecording ? AppTheme.primaryLight : AppTheme.border,
              width: _isRecording ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                _isRecording
                    ? 'LISTENING TO ACOUSTIC STREAM...'
                    : _isDecoding
                        ? 'RUNNING INDIC CONFORMER DECODE...'
                        : 'TAP MIC OR A SITE SAMPLE TO RUN REAL-TIME ACOUSTIC TEST',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: _isRecording
                      ? AppTheme.primaryLight
                      : _isDecoding
                          ? AppTheme.secondary
                          : AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 16),

              // Animated Soundwave Bar Graphic
              SizedBox(
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(24, (index) {
                    return AnimatedBuilder(
                      animation: _waveformAnimController,
                      builder: (context, child) {
                        double height = 6.0;
                        if (_isRecording) {
                          final wave = math.sin((_waveformAnimController.value * 2 * math.pi) + (index * 0.4));
                          height = 10.0 + (wave.abs() * 38.0);
                        } else if (_isDecoding) {
                          height = 8.0 + ((index % 4) * 6.0);
                        }
                        return Container(
                          width: 4,
                          height: height,
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          decoration: BoxDecoration(
                            color: _isRecording
                                ? (index % 3 == 0 ? AppTheme.secondary : AppTheme.primaryLight)
                                : AppTheme.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),

              // Recorder Center Button
              GestureDetector(
                onTap: () {
                  if (_isRecording) {
                    _stopRecording();
                  } else {
                    _startRecording();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isRecording
                          ? [Colors.redAccent, Colors.red]
                          : [AppTheme.primary, const Color(0xFF0369A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isRecording
                            ? Colors.redAccent.withValues(alpha: 0.5)
                            : AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: _isRecording ? 24 : 12,
                        spreadRadius: _isRecording ? 4 : 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Timer / Status
              Text(
                _isRecording
                    ? '00:0${(_recordingMilliseconds / 1000).toStringAsFixed(1)}s (16 kHz Indic Stream)'
                    : '16-bit PCM • Turbomachinery Filter Active',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick Regional Test Sentence Shortcuts
        const Text(
          'DIALECT SAMPLE PHRASES (TAP TO TEST ACOUSTIC DECODER)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 8),

        ..._selectedDialect.samplePhrases.map((phrase) {
          return Card(
            color: AppTheme.surfaceCard,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppTheme.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _startRecording(sample: phrase),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up_outlined, size: 18, color: AppTheme.primaryLight),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            phrase.text,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            phrase.translation,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Simulate', style: TextStyle(fontSize: 10, color: AppTheme.primaryLight)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 16),

        // Real-Time Acoustic Transcription Output
        const Text(
          'REAL-TIME ACOUSTIC TRANSCRIPTION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_transcribedText.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    child: Text(
                      'No speech captured yet. Tap record or select a sample above.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                    ),
                  ),
                )
              else ...[
                Text(
                  _transcribedText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt, size: 12, color: AppTheme.tertiary),
                          const SizedBox(width: 4),
                          Text(
                            'Latency: ${_acousticLatencyMs}ms',
                            style: const TextStyle(fontSize: 10, color: AppTheme.tertiary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'WER: ${_currentWerScore.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 10, color: AppTheme.primaryLight, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16, color: AppTheme.textSecondary),
                      tooltip: 'Copy Transcript',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transcription copied to clipboard.'),
                            backgroundColor: AppTheme.surfaceContainerHigh,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Entity Tagging Breakdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'REAL-TIME DOMAIN ENTITY TAGGING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppTheme.textMuted,
              ),
            ),
            if (_detectedEntities.isNotEmpty)
              Text(
                '${_detectedEntities.length} Entities Identified',
                style: const TextStyle(fontSize: 11, color: AppTheme.tertiary, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (_detectedEntities.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Center(
              child: Text(
                'Entities extracted by the Nirmaan acoustic brain will appear here.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
          )
        else
          ..._detectedEntities.map((entity) {
            return Card(
              color: AppTheme.surfaceCard,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: entity.color.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: entity.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(entity.icon, color: entity.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                entity.token,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: entity.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  entity.entityType,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: entity.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lexicon Match: ${entity.standardCategory}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${entity.confidence.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: entity.color,
                          ),
                        ),
                        const Text(
                          'Acoustic Match',
                          style: TextStyle(fontSize: 9, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 16),

        // Action: Push to DPR / AI Pipeline
        if (_transcribedText.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Export Tagged Speech to DPR Draft'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transcription and 3 entities forwarded to Daily Progress Report draft!'),
                    backgroundColor: AppTheme.tertiary,
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
