'use client';

import React, { useState } from 'react';

export const TechnicalTranslationView: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'INSIGHTS' | 'TRANSLATION'>('INSIGHTS');

  // Tab 1: PDF Insights State
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [hasAnalyzed, setHasAnalyzed] = useState(true);
  const [query, setQuery] = useState('What are the liquidated damages under Clause 8.7 for pier well sinking delays?');
  const [qaAnswer, setQaAnswer] = useState<string | null>(
    'Under Section 04.2 / Clause 8.7 of the Bridge Tender Specs, delay in Substructure Well Sinking (Milestone 1) incurs liquidated damages of 0.05% of the contract value per day, capped at a maximum of 10% of total contract price under FIDIC Yellow Book provisions.'
  );
  const [showInsightsHistory, setShowInsightsHistory] = useState(true);

  // Tab 2: Page-by-Page Translation State
  const [selectedTargetLanguage, setSelectedTargetLanguage] = useState<string>('Hindi (हिन्दी)');
  const [isTranslating, setIsTranslating] = useState(false);
  const [hasTranslated, setHasTranslated] = useState(true);
  const [translationProgressPage, setTranslationProgressPage] = useState(18);
  const totalDocPages = 18;
  const [showTranslationHistory, setShowTranslationHistory] = useState(true);

  // Top 15 Indian Languages
  const targetLanguages = [
    { code: 'hi', label: 'Hindi (हिन्दी)' },
    { code: 'bn', label: 'Bengali (বাংলা)' },
    { code: 'mr', label: 'Marathi (मराठी)' },
    { code: 'te', label: 'Telugu (తెలుగు)' },
    { code: 'ta', label: 'Tamil (தமிழ்)' },
    { code: 'gu', label: 'Gujarati (ગુજરાતી)' },
    { code: 'kn', label: 'Kannada (ಕನ್ನಡ)' },
    { code: 'ml', label: 'Malayalam (മലയാളം)' },
    { code: 'as', label: 'Assamese (অসমীয়া)' },
    { code: 'pa', label: 'Punjabi (ਪੰਜਾਬੀ)' },
    { code: 'or', label: 'Odia (ଓଡ଼ିଆ)' },
    { code: 'ur', label: 'Urdu (اردو)' },
    { code: 'mai', label: 'Maithili (मैथिली)' },
    { code: 'sa', label: 'Sanskrit (संस्कृतम्)' },
    { code: 'en', label: 'English' },
  ];

  // Preserved BOQ Technical Data Table (Zero Manipulation)
  const preservedBoqItems = [
    {
      code: '03.02.01',
      desc: 'M60 Grade Self-Compacting Concrete Pier Caps',
      descHi: 'M60 ग्रेड सेल्फ-कॉम्पैक्टिंग कंक्रीट पियर कैप्स',
      qty: '14,250.00',
      unit: 'cum',
      tolerance: '± 5 mm / IS 456',
      rate: '₹12,400',
      total: '₹17.67 Cr',
    },
    {
      code: '03.02.04',
      desc: 'Fe550D Corrosion Resistant Thermo Rebar',
      descHi: 'Fe550D संक्षारण प्रतिरोधी थर्मो रीबार स्टील',
      qty: '3,820.50',
      unit: 'MT',
      tolerance: '± 2 mm Cover / IRC:112',
      rate: '₹78,500',
      total: '₹29.99 Cr',
    },
    {
      code: '04.01.12',
      desc: '1860 MPa High Tensile Stay Cable Strands',
      descHi: '1860 MPa उच्च तन्यता स्टे केबल स्ट्रैंड्स',
      qty: '840.00',
      unit: 'Tons',
      tolerance: 'Zero Relaxation / IRC:SP:47',
      rate: '₹2,45,000',
      total: '₹20.58 Cr',
    },
    {
      code: '02.01.05',
      desc: 'Well Sinking Caisson Steining (-54.0m MSL)',
      descHi: 'वेल सिंकिंग कैसॉन स्टेइनिंग (-54.0m MSL स्तर)',
      qty: '48,600.00',
      unit: 'cum',
      tolerance: '± 25 mm Tilt/Shift / IRC:78',
      rate: '₹6,800',
      total: '₹33.05 Cr',
    },
    {
      code: '04.03.08',
      desc: 'Pot-PTFE Multi-Rotational Bridge Bearings',
      descHi: 'पॉट-पीटीएफई मल्टी-रोटेशनल ब्रिज बियरिंग्स',
      qty: '48.00',
      unit: 'Nos',
      tolerance: 'EN 1337-2 / IRC:83',
      rate: '₹4,50,000',
      total: '₹2.16 Cr',
    },
  ];

  // Past OCR Analysis Records
  const insightsHistory = [
    {
      docName: 'Tender_NIT_NHAI_BRG_2026_Vol_II_Specs.pdf',
      pages: 86,
      size: '34.2 MB',
      extractedPages: 24,
      distillationRatio: '27.9%',
      timestamp: 'Today, 11:20 AM',
      clausesFound: 14,
      hash: 'sha256-a1b2c3d4e5f607189a0b1c2d3e4f5a6b',
    },
    {
      docName: 'FIDIC_Yellow_Book_Conditions_Schedule_C.pdf',
      pages: 142,
      size: '48.1 MB',
      extractedPages: 38,
      distillationRatio: '26.7%',
      timestamp: 'Yesterday, 03:40 PM',
      clausesFound: 22,
      hash: 'sha256-9e8d7c6b5a4f3e2d1c0b9a8f7e6d5c4b',
    },
    {
      docName: 'IRC_SP_47_Cable_Stayed_Bridge_Guidelines.pdf',
      pages: 64,
      size: '19.5 MB',
      extractedPages: 18,
      distillationRatio: '28.1%',
      timestamp: '03 Oct, 05:10 PM',
      clausesFound: 9,
      hash: 'sha256-3f2e1d0c9b8a7f6e5d4c3b2a1f0e9d8c',
    },
  ];

  // Past Translation Records
  const translationHistory = [
    {
      docName: 'Tender_NIT_NHAI_BRG_2026_Vol_II_Specs.pdf',
      targetLang: 'Hindi (हिन्दी)',
      pages: 18,
      status: '100% Translated',
      tableFormatPreserved: true,
      timestamp: 'Today, 11:32 AM',
      token: 'DL-PDF-HI-9821',
    },
    {
      docName: 'Pier_24_Caisson_Steining_Procedure.pdf',
      targetLang: 'Assamese (অসমীয়া)',
      pages: 12,
      status: '100% Translated',
      tableFormatPreserved: true,
      timestamp: 'Yesterday, 02:15 PM',
      token: 'DL-PDF-AS-7740',
    },
    {
      docName: 'Cable_Tensioning_Safety_Checklist.pdf',
      targetLang: 'Bengali (বাংলা)',
      pages: 8,
      status: '100% Translated',
      tableFormatPreserved: true,
      timestamp: '04 Oct, 09:50 AM',
      token: 'DL-PDF-BN-6612',
    },
  ];

  const handleTriggerAnalysis = () => {
    setIsAnalyzing(true);
    setHasAnalyzed(false);
    setTimeout(() => {
      setIsAnalyzing(false);
      setHasAnalyzed(true);
    }, 1200);
  };

  const handleTriggerTranslation = () => {
    setIsTranslating(true);
    setHasTranslated(false);
    setTranslationProgressPage(1);
    const interval = setInterval(() => {
      setTranslationProgressPage((prev) => {
        if (prev >= totalDocPages) {
          clearInterval(interval);
          setIsTranslating(false);
          setHasTranslated(true);
          return totalDocPages;
        }
        return prev + 2;
      });
    }, 150);
  };

  return (
    <div className="bg-surface-container-lowest p-5 sm:p-6 rounded-2xl border border-surface-container-high shadow-sm flex flex-col gap-6">
      {/* Top Banner Header */}
      <div className="flex flex-wrap items-center justify-between gap-4 border-b border-surface-container-high/60 pb-5">
        <div>
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-xl bg-primary/15 border border-primary/30 flex items-center justify-center text-primary">
              <span className="material-symbols-outlined text-[22px]">menu_book</span>
            </div>
            <div>
              <h2 className="text-base font-bold text-white tracking-tight flex items-center gap-2">
                <span>Tender PDF AI Intelligence & Layout-Preserving Translation</span>
                <span className="px-2.5 py-0.5 rounded-full bg-tertiary/15 text-tertiary border border-tertiary/30 text-[10px] font-mono font-bold">
                  Zero Data Manipulation
                </span>
              </h2>
              <p className="text-xs text-on-surface-variant mt-0.5">
                Up to 100 Pages / 50 MB · 15–40% Critical Clause Distillation · Strict Table Geometry Locking
              </p>
            </div>
          </div>
        </div>

        {/* Tab Switcher */}
        <div className="flex items-center gap-1.5 p-1 bg-surface-container rounded-xl border border-surface-container-high">
          <button
            onClick={() => setActiveTab('INSIGHTS')}
            className={`px-4 py-2 rounded-lg text-xs font-bold transition-all flex items-center gap-2 ${
              activeTab === 'INSIGHTS'
                ? 'bg-primary text-white shadow-sm'
                : 'text-on-surface-variant hover:text-white'
            }`}
          >
            <span className="material-symbols-outlined text-[16px]">table_chart</span>
            <span>Structured Insights (15–40%)</span>
          </button>
          <button
            onClick={() => setActiveTab('TRANSLATION')}
            className={`px-4 py-2 rounded-lg text-xs font-bold transition-all flex items-center gap-2 ${
              activeTab === 'TRANSLATION'
                ? 'bg-primary text-white shadow-sm'
                : 'text-on-surface-variant hover:text-white'
            }`}
          >
            <span className="material-symbols-outlined text-[16px]">g_translate</span>
            <span>Page-by-Page Translation</span>
          </button>
        </div>
      </div>

      {/* ========================================================= */}
      {/* TAB 1: STRUCTURED PDF INSIGHTS (15-40% DISTILLATION)     */}
      {/* ========================================================= */}
      {activeTab === 'INSIGHTS' && (
        <div className="flex flex-col gap-6 animate-fade-in">
          {/* Active Tender File Card */}
          <div className="p-4 bg-surface-container-low rounded-xl border border-surface-container-high flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div className="flex items-center gap-3.5">
              <div className="w-11 h-11 rounded-xl bg-red-500/15 border border-red-500/30 flex items-center justify-center text-red-400 flex-shrink-0">
                <span className="material-symbols-outlined text-[26px]">picture_as_pdf</span>
              </div>
              <div>
                <h3 className="text-sm font-bold text-white flex items-center gap-2">
                  <span>Tender_NIT_NHAI_BRG_2026_Vol_II_Specs.pdf</span>
                  <span className="px-2 py-0.5 rounded bg-primary/20 text-primary text-[10px] font-mono font-bold">
                    FIDIC Yellow Book
                  </span>
                </h3>
                <p className="text-xs text-on-surface-variant font-mono mt-0.5">
                  Size: 34.2 MB · 86 Pages · Brahmaputra River Bridge Package II (₹3,450 Cr)
                </p>
              </div>
            </div>

            <button
              onClick={handleTriggerAnalysis}
              disabled={isAnalyzing}
              className="px-4 py-2.5 bg-primary hover:bg-primary-container text-white text-xs font-bold rounded-xl shadow-sm transition-all flex items-center gap-2 flex-shrink-0 disabled:opacity-50"
            >
              <span className="material-symbols-outlined text-[16px]">
                {isAnalyzing ? 'sync' : 'psychology'}
              </span>
              <span>{isAnalyzing ? 'Extracting Zero-Loss Data...' : 'Extract Key Insights (No Manipulation)'}</span>
            </button>
          </div>

          {/* KPI Distillation Summary */}
          {hasAnalyzed && (
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div className="p-3.5 bg-surface-container-low rounded-xl border border-surface-container-high flex flex-col gap-1">
                <div className="flex items-center gap-2 text-tertiary">
                  <span className="material-symbols-outlined text-[18px]">filter_alt</span>
                  <span className="text-xs font-bold uppercase tracking-wider">Distillation Ratio</span>
                </div>
                <span className="text-lg font-black text-white font-mono">28.4% Essential</span>
                <span className="text-[11px] text-on-surface-variant">71.6% Redundant Boilerplate Filtered</span>
              </div>

              <div className="p-3.5 bg-surface-container-low rounded-xl border border-surface-container-high flex flex-col gap-1">
                <div className="flex items-center gap-2 text-primary">
                  <span className="material-symbols-outlined text-[18px]">verified</span>
                  <span className="text-xs font-bold uppercase tracking-wider">Data Integrity</span>
                </div>
                <span className="text-lg font-black text-white font-mono">100% Exact Numbers</span>
                <span className="text-[11px] text-on-surface-variant">0 Alterations · Raw Float Values Locked</span>
              </div>

              <div className="p-3.5 bg-surface-container-low rounded-xl border border-surface-container-high flex flex-col gap-1">
                <div className="flex items-center gap-2 text-secondary">
                  <span className="material-symbols-outlined text-[18px]">gavel</span>
                  <span className="text-xs font-bold uppercase tracking-wider">Critical Penalties</span>
                </div>
                <span className="text-lg font-black text-white font-mono">14 Extracted Clauses</span>
                <span className="text-[11px] text-on-surface-variant">Clause 8.7 Liquidated Damages Identified</span>
              </div>
            </div>
          )}

          {/* Tender Milestones & Clause 8.7 Liquidated Damages */}
          <div className="p-4 bg-surface-container-low rounded-xl border border-surface-container-high flex flex-col gap-3">
            <div className="flex items-center gap-2 text-secondary">
              <span className="material-symbols-outlined text-[20px]">flag</span>
              <h4 className="text-xs font-bold uppercase tracking-wider text-white">
                Tender Milestones & Liquidated Damages (Clause 8.7 Enforced)
              </h4>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              <div className="p-3 bg-surface-container rounded-lg border border-surface-container-high flex flex-col gap-1.5">
                <div className="flex items-center justify-between">
                  <span className="px-2 py-0.5 rounded bg-secondary/20 text-secondary font-mono font-bold text-[10px]">
                    Milestone 1
                  </span>
                  <span className="text-[11px] text-on-surface-variant font-mono">Month 8</span>
                </div>
                <h5 className="text-xs font-bold text-white">Substructure Well Sinking (P1-P24)</h5>
                <p className="text-[11px] text-secondary font-mono">Liquidated Damages: 0.05% per day delay</p>
              </div>

              <div className="p-3 bg-surface-container rounded-lg border border-surface-container-high flex flex-col gap-1.5">
                <div className="flex items-center justify-between">
                  <span className="px-2 py-0.5 rounded bg-secondary/20 text-secondary font-mono font-bold text-[10px]">
                    Milestone 2
                  </span>
                  <span className="text-[11px] text-on-surface-variant font-mono">Month 16</span>
                </div>
                <h5 className="text-xs font-bold text-white">Pylon P-24 M60 Caps & Stay Anchors</h5>
                <p className="text-[11px] text-secondary font-mono">Liquidated Damages: 0.075% per day delay</p>
              </div>

              <div className="p-3 bg-surface-container rounded-lg border border-surface-container-high flex flex-col gap-1.5">
                <div className="flex items-center justify-between">
                  <span className="px-2 py-0.5 rounded bg-secondary/20 text-secondary font-mono font-bold text-[10px]">
                    Milestone 3
                  </span>
                  <span className="text-[11px] text-on-surface-variant font-mono">Month 24</span>
                </div>
                <h5 className="text-xs font-bold text-white">Full Deck Stitching & Static Load Test</h5>
                <p className="text-[11px] text-secondary font-mono">Max 10% Contract Price Cap</p>
              </div>
            </div>
          </div>

          {/* PRESERVED BOQ TECHNICAL DATA TABLE (ZERO DATA MANIPULATION) */}
          <div className="p-4 bg-surface-container-low rounded-xl border border-surface-container-high flex flex-col gap-3">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-tertiary text-[20px]">table_chart</span>
                <div>
                  <h4 className="text-xs font-bold uppercase tracking-wider text-white">
                    Preserved BOQ Table (Zero Data Manipulation Policy)
                  </h4>
                  <p className="text-[11px] text-on-surface-variant">
                    Extracted verbatim from Page 42 Table 4.1 · Mathematical dimensions & tolerances 100% locked
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-2 font-mono text-[10px] text-tertiary px-2.5 py-1 rounded-full bg-tertiary/10 border border-tertiary/30">
                <span className="material-symbols-outlined text-[13px]">lock</span>
                <span>SHA-256 Tamper Sealed</span>
              </div>
            </div>

            <div className="overflow-x-auto rounded-lg border border-surface-container-high">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="bg-surface-container border-b border-surface-container-high text-primary font-mono text-[11px]">
                    <th className="py-2.5 px-3">Item #</th>
                    <th className="py-2.5 px-3">Description of Work</th>
                    <th className="py-2.5 px-3 text-right">Quantity</th>
                    <th className="py-2.5 px-3">Unit</th>
                    <th className="py-2.5 px-3">Specified Tolerance</th>
                    <th className="py-2.5 px-3 text-right">Unit Rate</th>
                    <th className="py-2.5 px-3 text-right">Total Amount</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-surface-container-high/60 font-mono text-on-surface">
                  {preservedBoqItems.map((item, idx) => (
                    <tr key={idx} className="hover:bg-surface-container/60 transition-colors">
                      <td className="py-2.5 px-3 text-primary font-bold">{item.code}</td>
                      <td className="py-2.5 px-3 font-sans text-white font-medium">{item.desc}</td>
                      <td className="py-2.5 px-3 text-right text-tertiary font-bold">{item.qty}</td>
                      <td className="py-2.5 px-3 text-on-surface-variant">{item.unit}</td>
                      <td className="py-2.5 px-3 text-secondary">{item.tolerance}</td>
                      <td className="py-2.5 px-3 text-right text-on-surface-variant">{item.rate}</td>
                      <td className="py-2.5 px-3 text-right text-white font-bold">{item.total}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="p-2.5 bg-surface-container rounded-lg flex items-center justify-between text-[11px] font-mono text-on-surface-variant">
              <span>Cryptographic Proof: sha256-a1b2c3d4e5f607189a0b1c2d3e4f5a6b</span>
              <span className="text-tertiary">Verified Match (0 byte offset)</span>
            </div>
          </div>

          {/* Interactive Document Q&A */}
          <div className="p-4 bg-surface-container-low rounded-xl border border-primary/30 flex flex-col gap-2.5">
            <span className="text-xs uppercase font-bold text-primary flex items-center gap-1.5">
              <span className="material-symbols-outlined text-[16px]">contact_support</span>
              <span>Ask Document Intelligence (With Exact Page & Clause Citations)</span>
            </span>
            <div className="flex gap-2">
              <input
                type="text"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                className="flex-1 px-3 py-2 bg-surface-container-lowest text-xs rounded-lg border border-surface-container-high text-white focus:outline-none focus:ring-1 focus:ring-primary"
                placeholder="Ask any specification or clause in this tender..."
              />
              <button
                onClick={() => setQaAnswer('Under Section 04.2 / Clause 8.7 of the Bridge Tender Specs, delay in Substructure Well Sinking (Milestone 1) incurs liquidated damages of 0.05% of the contract value per day, capped at a maximum of 10% of total contract price under FIDIC Yellow Book provisions.')}
                className="px-4 py-2 bg-primary text-white font-bold text-xs rounded-lg hover:bg-primary-container transition-all"
              >
                Query Spec
              </button>
            </div>
            {qaAnswer && (
              <div className="p-3 bg-surface-container rounded-lg border border-surface-container-high text-xs flex flex-col gap-1.5">
                <span className="font-semibold text-white leading-relaxed">{qaAnswer}</span>
                <div className="flex items-center gap-2 mt-1">
                  <span className="text-[10px] text-on-surface-variant font-mono uppercase">Verified Citations:</span>
                  <span className="px-2 py-0.5 rounded bg-primary/20 text-primary font-mono text-[10px]">
                    Page 42 (Sec 4.2.1)
                  </span>
                  <span className="px-2 py-0.5 rounded bg-primary/20 text-primary font-mono text-[10px]">
                    Page 68 (FIDIC Cl. 8.7)
                  </span>
                </div>
              </div>
            )}
          </div>

          {/* INLINE EXPANDABLE OCR & INSIGHTS HISTORY SECTION RIGHT BELOW */}
          <div className="bg-surface-container-low p-4 sm:p-5 rounded-xl border border-surface-container-high flex flex-col gap-3">
            <div
              onClick={() => setShowInsightsHistory(!showInsightsHistory)}
              className="flex items-center justify-between cursor-pointer select-none"
            >
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-primary text-[20px]">history_edu</span>
                <h4 className="text-xs font-bold uppercase tracking-wider text-white flex items-center gap-2">
                  <span>Tender PDF Intelligence & OCR History</span>
                  <span className="px-2 py-0.5 rounded-full bg-primary/20 text-primary font-mono text-[10px]">
                    {insightsHistory.length} Scans
                  </span>
                </h4>
              </div>
              <span className="material-symbols-outlined text-on-surface-variant text-[20px]">
                {showInsightsHistory ? 'expand_less' : 'expand_more'}
              </span>
            </div>

            {showInsightsHistory && (
              <div className="flex flex-col gap-2 pt-2 border-t border-surface-container-high/60 animate-fade-in">
                <p className="text-[11px] text-on-surface-variant">
                  Audit log of previously processed tender documents with 15–40% distillation and SHA-256 integrity proofs.
                </p>
                <div className="flex flex-col gap-2">
                  {insightsHistory.map((h, i) => (
                    <div
                      key={i}
                      className="p-3 bg-surface-container rounded-lg border border-surface-container-high flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2"
                    >
                      <div className="flex flex-col gap-1">
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-bold text-white">{h.docName}</span>
                          <span className="px-2 py-0.2 rounded bg-tertiary/15 text-tertiary text-[10px] font-mono font-bold">
                            {h.distillationRatio} Essential
                          </span>
                        </div>
                        <span className="text-[11px] text-on-surface-variant font-mono">
                          {h.pages} Pages · {h.size} · Extracted: {h.extractedPages} Pages ({h.clausesFound} Clauses) · {h.timestamp}
                        </span>
                        <span className="text-[9px] text-outline font-mono truncate max-w-sm">{h.hash}</span>
                      </div>

                      <button
                        onClick={() => alert(`Exporting insights summary for ${h.docName}`)}
                        className="px-3 py-1 bg-surface-container-high hover:bg-surface-variant text-white text-[11px] font-bold rounded-md transition-all flex items-center gap-1 self-end sm:self-center"
                      >
                        <span className="material-symbols-outlined text-[14px]">download</span>
                        <span>Export Insights</span>
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* TAB 2: PAGE-BY-PAGE MULTI-LANGUAGE TRANSLATION            */}
      {/* ========================================================= */}
      {activeTab === 'TRANSLATION' && (
        <div className="flex flex-col gap-6 animate-fade-in">
          {/* Language Selector & Engine Config */}
          <div className="p-4 bg-surface-container-low rounded-xl border border-surface-container-high flex flex-col gap-4">
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
              <div>
                <span className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">
                  Target Native Language (Top 15 Indian Languages Supported)
                </span>
                <p className="text-xs text-on-surface-variant mt-0.5">
                  Translates every page sequentially (1..N). Preserves exact table format with 0% numerical deviation.
                </p>
              </div>

              <div className="flex items-center gap-2">
                <span className="px-2.5 py-1 rounded-full bg-primary/20 text-primary text-[10px] font-mono font-bold">
                  Max: 100 Pages / 50 MB
                </span>
                <span className="px-2.5 py-1 rounded-full bg-tertiary/20 text-tertiary text-[10px] font-mono font-bold">
                  Table Layout Locked
                </span>
              </div>
            </div>

            <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
              <select
                value={selectedTargetLanguage}
                onChange={(e) => setSelectedTargetLanguage(e.target.value)}
                className="flex-1 px-3 py-2.5 bg-surface-container-lowest text-white font-bold text-xs rounded-xl border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary"
              >
                {targetLanguages.map((lang) => (
                  <option key={lang.code} value={lang.label}>
                    {lang.label}
                  </option>
                ))}
              </select>

              <button
                onClick={handleTriggerTranslation}
                disabled={isTranslating}
                className="px-5 py-2.5 bg-tertiary hover:bg-emerald-600 text-white text-xs font-bold rounded-xl shadow-sm transition-all flex items-center justify-center gap-2 disabled:opacity-50"
              >
                <span className="material-symbols-outlined text-[18px]">
                  {isTranslating ? 'sync' : 'translate'}
                </span>
                <span>
                  {isTranslating
                    ? `Translating Page ${translationProgressPage} of ${totalDocPages}...`
                    : 'Translate Entire PDF (Page-Preserving)'}
                </span>
              </button>
            </div>

            {/* Progress Bar when translating */}
            {isTranslating && (
              <div className="p-3 bg-surface-container rounded-lg flex flex-col gap-1.5">
                <div className="flex justify-between text-xs font-mono">
                  <span className="text-white font-bold">
                    Translating Page {translationProgressPage} of {totalDocPages}...
                  </span>
                  <span className="text-tertiary font-bold">
                    {Math.round((translationProgressPage / totalDocPages) * 100)}%
                  </span>
                </div>
                <div className="w-full h-2 bg-surface-container-high rounded-full overflow-hidden">
                  <div
                    className="h-full bg-tertiary transition-all duration-300"
                    style={{ width: `${(translationProgressPage / totalDocPages) * 100}%` }}
                  />
                </div>
                <span className="text-[10px] text-on-surface-variant font-mono">
                  Preserving raster cell borders & bounding boxes...
                </span>
              </div>
            )}
          </div>

          {/* Translation Complete Banner */}
          {hasTranslated && (
            <div className="p-4 bg-tertiary/10 rounded-xl border border-tertiary/30 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
              <div className="flex items-center gap-3">
                <span className="material-symbols-outlined text-tertiary text-[24px]">check_circle</span>
                <div>
                  <h4 className="text-xs font-bold text-white">
                    Sequential Translation Complete (18 of 18 Pages Ready in {selectedTargetLanguage})
                  </h4>
                  <p className="text-[11px] text-on-surface-variant font-mono">
                    All engineering tables, rebar quantities, and tolerance figures verified identical to source.
                  </p>
                </div>
              </div>

              <button
                onClick={() => alert(`Downloading ${selectedTargetLanguage} translated PDF package...`)}
                className="px-4 py-2 bg-tertiary hover:bg-emerald-600 text-white font-bold text-xs rounded-lg transition-all flex items-center gap-1.5 self-end sm:self-auto"
              >
                <span className="material-symbols-outlined text-[16px]">download</span>
                <span>Download Translated PDF</span>
              </button>
            </div>
          )}

          {/* SIDE-BY-SIDE HIGH FIDELITY COMPARISON (ORIGINAL VS TRANSLATED) */}
          <div className="flex flex-col gap-3">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold uppercase tracking-wider text-on-surface-variant">
                Side-by-Side Page Preview (Page 1 Sample with Preserved BOQ Table)
              </span>
              <span className="text-[11px] text-primary font-mono font-bold">1:1 Layout Synchronized</span>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Original Document (English) */}
              <div className="p-4 bg-surface-container-low rounded-xl border border-surface-container-high flex flex-col gap-3">
                <div className="flex items-center justify-between border-b border-surface-container-high/60 pb-2">
                  <span className="text-xs font-bold uppercase text-primary font-mono">
                    Original Document (English)
                  </span>
                  <span className="text-[10px] text-on-surface-variant font-mono">Page 1 of 18</span>
                </div>

                <div className="p-3 bg-surface-container rounded-lg text-xs leading-relaxed text-on-surface font-mono">
                  <p className="mb-2">
                    <strong>1.0 Project Scope & Structural Directives</strong>
                    <br />
                    The Contractor shall execute the construction of the 2.4 km four-lane river bridge including substructure well foundations down to -54.0m scour level, Pier P-24 M60 caps, and stay cables under IRC:SP:47.
                  </p>
                  <p className="text-on-surface-variant text-[11px]">
                    All quantities listed below in Table 1.1 must strictly adhere to the specified tolerance limits.
                  </p>
                </div>

                {/* English Table */}
                <div className="overflow-x-auto rounded border border-surface-container-high text-[11px] font-mono">
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="bg-surface-container text-primary">
                        <th className="p-2">Item</th>
                        <th className="p-2">Work Description</th>
                        <th className="p-2 text-right">Qty</th>
                        <th className="p-2">Tolerance</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-surface-container-high/60">
                      <tr>
                        <td className="p-2 text-white">03.02.01</td>
                        <td className="p-2">M60 Self-Compacting Pier Cap</td>
                        <td className="p-2 text-right text-tertiary">14,250 cum</td>
                        <td className="p-2 text-secondary">± 5 mm</td>
                      </tr>
                      <tr>
                        <td className="p-2 text-white">04.01.12</td>
                        <td className="p-2">1860 MPa Stay Cable Strands</td>
                        <td className="p-2 text-right text-tertiary">840 Tons</td>
                        <td className="p-2 text-secondary">Zero Relax</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Translated Document (Native Indian Language) */}
              <div className="p-4 bg-surface-container-low rounded-xl border border-tertiary/40 flex flex-col gap-3">
                <div className="flex items-center justify-between border-b border-surface-container-high/60 pb-2">
                  <span className="text-xs font-bold uppercase text-tertiary font-mono">
                    Translated Document ({selectedTargetLanguage})
                  </span>
                  <span className="px-2 py-0.5 rounded bg-tertiary/20 text-tertiary text-[10px] font-bold">
                    Table Geometry Locked
                  </span>
                </div>

                <div className="p-3 bg-surface-container rounded-lg text-xs leading-relaxed text-on-surface">
                  <p className="mb-2">
                    <strong>1.0 परियोजना का दायरा और संरचनात्मक निर्देश</strong>
                    <br />
                    ठेकेदार -54.0m गहराई तक कुआं नींव (वेल फाउंडेशन), पियर P-24 M60 कंक्रीट कैप्स, और IRC:SP:47 के तहत केबल-स्टेड तारों सहित 2.4 km चार-लेन नदी पुल का निर्माण निष्पादित करेगा।
                  </p>
                  <p className="text-on-surface-variant text-[11px]">
                    तालिका 1.1 में नीचे दी गई सभी मात्राओं को निर्दिष्ट सहिष्णुता (टॉलरेंस) सीमाओं का सख्ती से पालन करना चाहिए।
                  </p>
                </div>

                {/* Translated Table (Preserved Format with 100% Identical Numbers) */}
                <div className="overflow-x-auto rounded border border-surface-container-high text-[11px] font-mono">
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="bg-surface-container text-tertiary">
                        <th className="p-2">मद #</th>
                        <th className="p-2">कार्य का विवरण (अनुवादित)</th>
                        <th className="p-2 text-right">मात्रा (अपरिवर्तित)</th>
                        <th className="p-2">सहिष्णुता</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-surface-container-high/60">
                      <tr>
                        <td className="p-2 text-white">03.02.01</td>
                        <td className="p-2 font-sans">M60 सेल्फ-कॉम्पैक्टिंग पियर कैप</td>
                        <td className="p-2 text-right text-tertiary font-bold">14,250 cum</td>
                        <td className="p-2 text-secondary">± 5 mm</td>
                      </tr>
                      <tr>
                        <td className="p-2 text-white">04.01.12</td>
                        <td className="p-2 font-sans">1860 MPa स्टे केबल स्ट्रैंड्स</td>
                        <td className="p-2 text-right text-tertiary font-bold">840 Tons</td>
                        <td className="p-2 text-secondary">Zero Relax</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>

          {/* INLINE EXPANDABLE TRANSLATION HISTORY SECTION RIGHT BELOW */}
          <div className="bg-surface-container-low p-4 sm:p-5 rounded-xl border border-surface-container-high flex flex-col gap-3">
            <div
              onClick={() => setShowTranslationHistory(!showTranslationHistory)}
              className="flex items-center justify-between cursor-pointer select-none"
            >
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-tertiary text-[20px]">manage_history</span>
                <h4 className="text-xs font-bold uppercase tracking-wider text-white flex items-center gap-2">
                  <span>PDF Translation History & Download Archive</span>
                  <span className="px-2 py-0.5 rounded-full bg-tertiary/20 text-tertiary font-mono text-[10px]">
                    {translationHistory.length} Translated Documents
                  </span>
                </h4>
              </div>
              <span className="material-symbols-outlined text-on-surface-variant text-[20px]">
                {showTranslationHistory ? 'expand_less' : 'expand_more'}
              </span>
            </div>

            {showTranslationHistory && (
              <div className="flex flex-col gap-2 pt-2 border-t border-surface-container-high/60 animate-fade-in">
                <p className="text-[11px] text-on-surface-variant">
                  Sequential page-by-page translated documents with preserved table formats ready for one-tap download.
                </p>
                <div className="flex flex-col gap-2">
                  {translationHistory.map((item, i) => (
                    <div
                      key={i}
                      className="p-3 bg-surface-container rounded-lg border border-surface-container-high flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2"
                    >
                      <div className="flex flex-col gap-1">
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-bold text-white">{item.docName}</span>
                          <span className="px-2 py-0.2 rounded bg-primary/20 text-primary text-[10px] font-mono font-bold">
                            {item.targetLang}
                          </span>
                        </div>
                        <span className="text-[11px] text-on-surface-variant font-mono">
                          {item.pages} Pages · {item.timestamp} · {item.status}
                        </span>
                        <div className="flex items-center gap-2">
                          <span className="px-1.5 py-0.2 rounded bg-tertiary/20 text-tertiary font-mono text-[9px] font-bold">
                            Table Format Preserved ✓
                          </span>
                          <span className="text-[9px] text-outline font-mono">{item.token}</span>
                        </div>
                      </div>

                      <button
                        onClick={() => alert(`Downloading ${item.docName} (${item.targetLang})`)}
                        className="px-3 py-1 bg-surface-container-high hover:bg-surface-variant text-white text-[11px] font-bold rounded-md transition-all flex items-center gap-1 self-end sm:self-center"
                      >
                        <span className="material-symbols-outlined text-[14px]">file_download</span>
                        <span>Download PDF</span>
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
