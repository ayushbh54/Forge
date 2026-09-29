'use client';

import React, { useState } from 'react';

export const TechnicalTranslationView: React.FC = () => {
  const [sourceLang, setSourceLang] = useState<'EN' | 'HI'>('EN');
  const [query, setQuery] = useState('What are the radiography NDT requirements for Line 24 welding?');
  const [qaAnswer, setQaAnswer] = useState<string | null>(
    'Under Section 04.2 of the Oil India Pipeline Specification, 100% of all girth welds on Line 24 (12" API 5L X52) must undergo Radiographic Examination (RT) per API 1104 / ASME B31.4 prior to trench lower-in. All hold points require Level-II NDT Inspector sign-off.'
  );

  const glossaryTerms = [
    { term: 'API 5L X52', desc: 'Standard pipe specification for high-pressure petroleum conveyance' },
    { term: 'WBS 03.02.04', desc: 'Corridor pipeline trenching & pier cap work breakdown' },
    { term: 'ASTM C39', desc: 'Standard compressive strength test method for cylindrical concrete specimens' },
    { term: 'FIDIC Cl. 8.4', desc: 'Extension of Time (EOT) claim provisions for employer/material delays' },
    { term: 'Spool / Erection', desc: 'Prefabricated pipe section assembled for mechanical tie-in' },
  ];

  return (
    <div className="bg-surface-container-lowest p-5 rounded-DEFAULT border border-surface-container-high shadow-sm flex flex-col gap-4">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-surface-container-high/60 pb-3">
        <div>
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-primary text-[20px]">translate</span>
            <h2 className="text-sm font-bold uppercase tracking-wider text-on-surface">
              CDE Document Intelligence & Technical Translation (Hindi ↔ English)
            </h2>
          </div>
          <p className="text-xs text-on-surface-variant">
            Layout-preserving technical document translation with protected industrial engineering glossary
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="px-2.5 py-0.5 rounded-full bg-primary/20 text-primary text-xs font-mono font-bold">
            Protected Terms: 142 Active
          </span>
          <span className="px-2.5 py-0.5 rounded-full bg-tertiary/20 text-tertiary text-xs font-mono font-bold">
            OCR Quality: 99.8%
          </span>
        </div>
      </div>

      {/* Side-by-Side Translation Preview */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Original English Spec */}
        <div className="p-4 bg-surface-container-low rounded-DEFAULT border border-surface-container-high flex flex-col gap-2">
          <div className="flex items-center justify-between text-xs text-on-surface-variant font-mono">
            <span className="font-bold uppercase text-primary">Original (English Document - OIL-SPEC-PIP-04.pdf)</span>
            <span>Page 42 of 188</span>
          </div>
          <div className="p-3 bg-surface-container rounded-sm text-xs leading-relaxed text-on-surface font-mono">
            <p className="mb-2">
              <strong>Section 4.2.1: Non-Destructive Testing (NDT) Protocol</strong><br />
              All orbital butt welds on 12-inch Trunk Line 24 shall be subjected to 100% radiographic inspection (RT) in accordance with API 1104 standards.
            </p>
            <p>
              Hold points shall remain active until 3rd-party Level-II inspector clears all radiographic films. Any weld exhibiting lack of root penetration (LOP) or cracks shall be marked as an immediate defect and rectified before backfilling.
            </p>
          </div>
        </div>

        {/* High-Fidelity Hindi Technical Translation */}
        <div className="p-4 bg-surface-container-low rounded-DEFAULT border border-surface-container-high flex flex-col gap-2">
          <div className="flex items-center justify-between text-xs text-on-surface-variant font-mono">
            <span className="font-bold uppercase text-tertiary">Verified Technical Translation (Hindi / हिंदी)</span>
            <span className="px-2 py-0.5 rounded-sm bg-tertiary/20 text-tertiary text-[10px] font-bold">Structure Preserved</span>
          </div>
          <div className="p-3 bg-surface-container rounded-sm text-xs leading-relaxed text-on-surface">
            <p className="mb-2">
              <strong>अनुभाग 4.2.1: गैर-विनाशकारी परीक्षण (NDT) प्रोटोकॉल</strong><br />
              12-इंच ट्रंक <span className="font-mono text-primary font-bold">Line 24</span> के सभी ऑर्बिटल बट वेल्ड्स का <span className="font-mono text-primary font-bold">API 1104</span> मानकों के अनुसार 100% रेडियोग्राफिक परीक्षण (<span className="font-mono text-primary font-bold">RT</span>) किया जाना अनिवार्य है।
            </p>
            <p>
              होल्ड पॉइंट्स तब तक सक्रिय रहेंगे जब तक कि तृतीय-पक्ष लेवल-II इंस्पेक्टर सभी फिल्मों को मंज़ूरी न दे दे। रूट पेनेट्रेशन की कमी (<span className="font-mono text-secondary font-bold">LOP</span>) या दरार पाए जाने पर उसे तत्काल दोष चिन्हित किया जाएगा और बैकफ़िलिंग से पहले सुधारा जाएगा।
            </p>
          </div>
        </div>
      </div>

      {/* Protected Engineering Glossary Chips */}
      <div className="p-3 bg-surface-container-low rounded-DEFAULT border border-surface-container-high flex flex-col gap-2">
        <span className="text-[11px] uppercase font-bold text-on-surface-variant tracking-wider">
          Protected Engineering Terms (Never mistranslated):
        </span>
        <div className="flex flex-wrap gap-2 text-xs">
          {glossaryTerms.map((g, idx) => (
            <div key={idx} className="px-2.5 py-1 bg-surface-container rounded-sm border border-surface-container-high flex items-center gap-1.5 font-mono">
              <span className="text-primary font-bold">{g.term}</span>
              <span className="text-on-surface-variant text-[10px]">— {g.desc}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Ask Document (Document Q&A with Page Citations) */}
      <div className="p-4 bg-surface-container rounded-DEFAULT border border-primary/20 flex flex-col gap-2">
        <span className="text-xs uppercase font-bold text-primary flex items-center gap-1">
          <span className="material-symbols-outlined text-[16px]">contact_support</span>
          Ask Document Intelligence (With Exact Page Citations)
        </span>
        <div className="flex gap-2">
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            className="flex-1 p-2 bg-surface-container-lowest text-xs rounded-sm border border-surface-container-high text-on-surface focus:outline-none focus:ring-1 focus:ring-primary"
          />
          <button className="px-4 py-2 bg-primary text-on-primary font-bold text-xs rounded-sm hover:bg-primary-container transition-all">
            Query Spec
          </button>
        </div>
        {qaAnswer && (
          <div className="mt-2 p-3 bg-surface-container-low rounded-sm border border-surface-container-high text-xs flex flex-col gap-1.5">
            <span className="font-semibold text-on-surface leading-relaxed">{qaAnswer}</span>
            <div className="flex items-center gap-2 mt-1">
              <span className="text-[10px] text-on-surface-variant font-mono uppercase">Verified Citations:</span>
              <span className="px-2 py-0.5 rounded-sm bg-primary/20 text-primary font-mono text-[10px] cursor-pointer hover:underline">
                Page 42 (Sec 4.2.1)
              </span>
              <span className="px-2 py-0.5 rounded-sm bg-primary/20 text-primary font-mono text-[10px] cursor-pointer hover:underline">
                Page 58 (Exhibit B)
              </span>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
