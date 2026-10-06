'use client';

import React, { useState } from 'react';
import { Sidebar } from '../../components/Sidebar';
import { Header } from '../../components/Header';
import { LoginGateway } from '../../components/LoginGateway';
import { VoiceCommandModal } from '../../components/VoiceCommandModal';
import { GeminiBrainModal } from '../../components/GeminiBrainModal';
import { ProjectOnboardModal } from '../../components/ProjectOnboardModal';
import { useWorkspace } from '../../context/WorkspaceContext';

const SAMPLE_FIELD_HISTORY = [
  {
    id: 'INF-001',
    source: 'VOICE_HINDI',
    reportedBy: 'Tapan Das (Piping Foreman)',
    timestamp: 'Today, 11:45 IST',
    rawText: 'Line 24 ka pipe welding 45 meter complete hai, lekin spool delay ki wajah se do joints pending hain.',
    matchedCode: 'PIP-L5-024',
    matchedName: '12" Cross-Country Gas Pipeline Welding',
    confidence: 96,
    quantity: '45 meters',
    delay: 'Spool Shortage at Central Stores',
    status: 'LINKED_TO_P6',
  },
  {
    id: 'INF-002',
    source: 'WHATSAPP_TEXT',
    reportedBy: 'K. Sharma (Civil Supervisor)',
    timestamp: 'Today, 09:30 IST',
    rawText: 'Pier 24 cap rebar 85 percent complete, pre-pour QA inspection passed by third party.',
    matchedCode: 'ACT-3088',
    matchedName: 'Pier 24 Concrete Pour & Micro-Piling',
    confidence: 94,
    quantity: '85 %',
    delay: 'None (Ahead of Schedule)',
    status: 'LINKED_TO_P6',
  },
  {
    id: 'INF-003',
    source: 'VOICE_ENGLISH',
    reportedBy: 'Biren Chetia (Rigging Lead)',
    timestamp: 'Yesterday, 16:15 IST',
    rawText: 'Crane 04 hydraulic ram seal leaking near Station 14+350, lifting suspended for 6 hours.',
    matchedCode: 'PIP-L5-024',
    matchedName: 'Heavy Rigging & Spool Lower-in',
    confidence: 91,
    quantity: '0 hrs',
    delay: 'Hydraulic Hose Breakdown',
    status: 'DELAY_FLAGGED',
  },
];

export default function LinkingBridgePage() {
  const workspace = useWorkspace();
  const { user, isAuthenticated, currentProject, activities, conflicts, submitVoiceUpdate, refreshData, showToast, sidebarCollapsed } = workspace;

  const [isVoiceOpen, setIsVoiceOpen] = useState(false);
  const [isGeminiOpen, setIsGeminiOpen] = useState(false);
  const [isOnboardOpen, setIsOnboardOpen] = useState(false);

  const [testInput, setTestInput] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);
  const [geminiResult, setGeminiResult] = useState<any>(null);
  const [isHistoryExpanded, setIsHistoryExpanded] = useState(true);

  if (!isAuthenticated) {
    return <LoginGateway onLoginSuccess={() => refreshData()} />;
  }

  const handleTestParse = async (text: string) => {
    setTestInput(text);
    if (!text.trim()) return;
    setIsProcessing(true);

    try {
      const res = await fetch('/api/gemini', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'PARSE_FIELD_UPDATE',
          payload: {
            rawText: text,
            projectId: currentProject?.id,
          },
        }),
      });
      const data = await res.json();
      if (data.success) {
        setGeminiResult(data.result);
      }
    } catch (e: any) {
      console.error('Error during field parse:', e);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleConfirmAndLink = async (actCode: string, qty?: number) => {
    const act = activities.find((a) => a.activityCode === actCode);
    const progress = Math.min(
      100,
      Math.round((((act?.installedQuantity || 0) + (qty || 15)) / (act?.plannedQuantity || 100)) * 100)
    );
    await submitVoiceUpdate(actCode, progress, geminiResult?.detectedDelay);
    showToast(`Mapped site observation to ${actCode} in SQLite! Consensus recalculated.`);
  };

  return (
    <div className="min-h-screen bg-background text-on-surface">
      {currentProject ? (
        <Header
          user={user}
          project={currentProject}
          onOpenVoiceModal={() => setIsVoiceOpen(true)}
          onOpenGeminiBrain={() => setIsGeminiOpen(true)}
          isMobileHUD={false}
          onToggleMobileHUD={() => {}}
        />
      ) : (
        <header className="fixed top-0 left-0 right-0 h-16 bg-surface-container border-b border-surface-container-high px-6 z-40 flex items-center justify-between">
          <span className="font-bold text-sm text-on-surface">SIH26122 Intelligent Schedule-Linking Engine</span>
          <button
            onClick={() => setIsOnboardOpen(true)}
            className="px-4 py-2 bg-primary text-on-primary font-bold text-xs rounded-DEFAULT"
          >
            + Onboard Project
          </button>
        </header>
      )}

      {currentProject && (
        <Sidebar
          project={currentProject}
          activeConflictsCount={conflicts.filter((c) => c.status === 'OPEN').length}
        />
      )}

      <main
        className={`${
          currentProject ? (sidebarCollapsed ? 'pl-[72px]' : 'pl-72') : 'pl-0'
        } pt-16 min-h-screen p-space-lg flex flex-col gap-6 transition-all duration-300 ease-in-out`}
      >
        {/* Banner */}
        <div className="p-5 bg-surface-container-low border border-surface-container-high rounded-xl flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <span className="w-10 h-10 rounded-xl bg-primary text-on-primary flex items-center justify-center font-bold shadow-sm">
              <span className="material-symbols-outlined text-[24px]">cable</span>
            </span>
            <div>
              <h1 className="text-base font-bold text-on-surface">SIH26122 Intelligent Schedule-Linking Layer</h1>
              <p className="text-xs text-on-surface-variant font-mono">
                Oil India Limited · Automated Bridge between Field Reality (WhatsApp / Audio) & Primavera P6 WBS
              </p>
            </div>
          </div>

          <button
            onClick={() => setIsGeminiOpen(true)}
            className="px-3.5 py-2 bg-gradient-to-r from-primary/20 to-tertiary/20 text-on-surface border border-tertiary/40 font-semibold text-xs rounded-xl flex items-center gap-1.5 shadow-sm shrink-0"
          >
            <span className="material-symbols-outlined text-[17px] text-tertiary">psychology</span>
            <span>Gemini Brain Assistant</span>
          </button>
        </div>

        {/* Live Interactive Parser Playground */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {/* Input Box */}
          <div className="bg-surface-container-lowest p-5 rounded-xl border border-surface-container-high flex flex-col gap-3 shadow-sm">
            <div className="flex items-center justify-between">
              <span className="text-xs uppercase font-bold text-primary font-mono flex items-center gap-1">
                <span className="material-symbols-outlined text-[16px]">mic</span>
                Multi-Modal Field Ingestion (Hindi / English / Hinglish)
              </span>
              <button
                onClick={() => setIsVoiceOpen(true)}
                className="px-3 py-1.5 bg-primary hover:bg-primary/90 text-on-primary font-bold text-xs rounded-lg flex items-center gap-1 shadow-sm"
              >
                <span className="material-symbols-outlined text-[15px]">record_voice_over</span>
                Voice Update
              </button>
            </div>

            <textarea
              rows={4}
              value={testInput}
              onChange={(e) => setTestInput(e.target.value)}
              placeholder="Paste WhatsApp field message, DPR memo, or speak (e.g. Line 24 ka pipe welding 45 meter complete hai, lekin store se spool shortage hai...)"
              className="w-full p-3 bg-surface-container-low border border-surface-container-high rounded-lg text-xs text-on-surface focus:outline-none focus:ring-1 focus:ring-primary font-medium"
            />

            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
              <div className="flex flex-wrap gap-1.5">
                <button
                  onClick={() =>
                    handleTestParse(
                      'Line 24 ka pipe installation start ho gaya hai, 45 meter welding complete hai, lekin spool delay ki wajah se do joints pending hain.'
                    )
                  }
                  className="px-2.5 py-1 bg-surface-container hover:bg-surface-container-high text-[11px] text-on-surface-variant rounded-md border border-surface-container-high"
                >
                  Sample 1: Line 24 Hindi Note
                </button>
                <button
                  onClick={() =>
                    handleTestParse('Pier 24 cap rebar 85 percent complete, pre-pour QA inspection passed.')
                  }
                  className="px-2.5 py-1 bg-surface-container hover:bg-surface-container-high text-[11px] text-on-surface-variant rounded-md border border-surface-container-high"
                >
                  Sample 2: Civil Rebar
                </button>
              </div>

              <button
                onClick={() => handleTestParse(testInput)}
                disabled={isProcessing || !testInput.trim()}
                className="px-5 py-2 bg-primary hover:bg-primary/90 text-on-primary font-bold text-xs rounded-lg shadow-sm flex items-center gap-1.5 disabled:opacity-50 shrink-0"
              >
                <span className="material-symbols-outlined text-[16px]">psychology</span>
                <span>{isProcessing ? 'Analyzing...' : 'Parse & Link'}</span>
              </button>
            </div>
          </div>

          {/* Gemini AI Result Box */}
          <div className="bg-surface-container-lowest p-5 rounded-xl border border-surface-container-high flex flex-col gap-3 shadow-sm">
            <span className="text-xs uppercase font-bold text-tertiary font-mono flex items-center gap-1">
              <span className="material-symbols-outlined text-[16px]">hub</span>
              Gemini Entity Extraction & P6 WBS Match
            </span>

            {geminiResult ? (
              <div className="flex flex-col gap-3 animate-fade-in text-xs">
                <div className="p-3 bg-surface-container-low rounded-lg border border-primary/30 flex items-center justify-between">
                  <div>
                    <span className="font-mono text-primary font-bold">{geminiResult.matchedActivityCode}</span>
                    <h3 className="font-bold text-on-surface">{geminiResult.activityName}</h3>
                    <span className="text-[10px] text-on-surface-variant font-mono">
                      WBS: {geminiResult.wbsCode} · Discipline: {geminiResult.discipline}
                    </span>
                  </div>
                  <div className="text-right">
                    <span className="px-2 py-0.5 rounded bg-tertiary/15 text-tertiary font-mono font-bold text-xs border border-tertiary/30">
                      {geminiResult.confidenceScore}% Match
                    </span>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-2 text-xs">
                  <div className="p-2.5 bg-surface-container rounded-lg">
                    <span className="text-[10px] uppercase text-on-surface-variant block">Quantity</span>
                    <strong className="text-primary font-mono text-sm">
                      {geminiResult.extractedQuantity} {geminiResult.unit}
                    </strong>
                  </div>
                  <div className="p-2.5 bg-surface-container rounded-lg">
                    <span className="text-[10px] uppercase text-on-surface-variant block">Detected Delay</span>
                    <strong
                      className={`text-sm ${geminiResult.detectedDelay ? 'text-error' : 'text-on-surface-variant'}`}
                    >
                      {geminiResult.detectedDelay || 'None'}
                    </strong>
                  </div>
                </div>

                <div className="p-2.5 bg-surface-container-low rounded-lg border border-surface-container-high text-on-surface-variant leading-relaxed text-[11px]">
                  <strong>Gemini Reasoning:</strong> {geminiResult.aiReasoning}
                </div>

                <button
                  onClick={() =>
                    handleConfirmAndLink(geminiResult.matchedActivityCode, geminiResult.extractedQuantity)
                  }
                  className="w-full py-2.5 bg-tertiary hover:bg-tertiary/90 text-on-tertiary font-bold text-xs rounded-lg shadow-md flex items-center justify-center gap-1.5 transition-all"
                >
                  <span className="material-symbols-outlined text-[17px]">link</span>
                  <span>Confirm & Map to Primavera P6 Baseline</span>
                </button>
              </div>
            ) : (
              <div className="flex-1 flex flex-col items-center justify-center p-8 text-center text-on-surface-variant gap-2">
                <span className="material-symbols-outlined text-[36px] opacity-40">cable</span>
                <p className="text-xs">
                  Type a site observation or click a sample to see Gemini AI schedule-linking in real time.
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Inline Structured Informal Field Observations & Audio Voice Notes History */}
        <div className="border border-surface-container-high rounded-xl bg-surface-container-lowest overflow-hidden shadow-sm">
          <div className="p-4 bg-surface-container-low/70 flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-surface-container-high">
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center text-primary">
                <span className="material-symbols-outlined text-[18px]">history</span>
              </div>
              <div>
                <h3 className="text-sm font-bold text-on-surface flex items-center gap-2">
                  Informal Field Observations & Audio Log History
                  <span className="px-2 py-0.5 rounded-full bg-primary/15 text-primary text-[10px] font-mono font-bold">
                    {SAMPLE_FIELD_HISTORY.length} Records
                  </span>
                </h3>
                <p className="text-[11px] text-on-surface-variant">
                  Voice memos, WhatsApp messages, and site notes transcribed and mapped to Primavera activities
                </p>
              </div>
            </div>

            <button
              onClick={() => setIsHistoryExpanded(!isHistoryExpanded)}
              className="px-3 py-1.5 bg-surface-container hover:bg-surface-container-high text-on-surface rounded-lg text-xs font-semibold flex items-center gap-1 transition-colors self-end sm:self-center"
            >
              <span className="material-symbols-outlined text-[16px]">
                {isHistoryExpanded ? 'expand_less' : 'expand_more'}
              </span>
              <span>{isHistoryExpanded ? 'Collapse' : 'Show All'}</span>
            </button>
          </div>

          {isHistoryExpanded && (
            <div className="p-4 flex flex-col gap-3">
              {SAMPLE_FIELD_HISTORY.map((item) => (
                <div
                  key={item.id}
                  className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col md:flex-row md:items-center justify-between gap-3 hover:border-primary/40 transition-all"
                >
                  <div className="flex items-start gap-3">
                    <div className="w-8 h-8 rounded-lg bg-surface-container-high flex items-center justify-center text-primary shrink-0 mt-0.5">
                      <span className="material-symbols-outlined text-[18px]">
                        {item.source.includes('VOICE') ? 'mic' : 'chat'}
                      </span>
                    </div>
                    <div>
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="text-xs font-bold text-on-surface">{item.reportedBy}</span>
                        <span className="px-2 py-0.5 rounded font-mono text-[10px] bg-primary/15 text-primary font-bold">
                          {item.source}
                        </span>
                        <span className="text-[10px] font-mono text-on-surface-variant">
                          {item.timestamp}
                        </span>
                      </div>
                      <p className="text-xs text-on-surface mt-1.5 italic bg-surface-container-lowest p-2 rounded-lg border border-surface-container-high/60">
                        "{item.rawText}"
                      </p>
                      <div className="mt-2 flex flex-wrap items-center gap-3 text-[11px] font-mono text-on-surface-variant">
                        <span className="text-primary font-bold">
                          Mapped: {item.matchedCode} ({item.matchedName})
                        </span>
                        <span>•</span>
                        <span className="text-tertiary font-bold">Confidence: {item.confidence}%</span>
                        <span>•</span>
                        <span>Quantity: {item.quantity}</span>
                        {item.delay !== 'None (Ahead of Schedule)' && (
                          <>
                            <span>•</span>
                            <span className="text-error font-bold">Delay: {item.delay}</span>
                          </>
                        )}
                      </div>
                    </div>
                  </div>

                  <div className="self-end md:self-center shrink-0">
                    <span className="px-2.5 py-1 rounded-full font-mono text-[10px] font-bold bg-tertiary/20 text-tertiary border border-tertiary/30">
                      {item.status}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </main>

      <VoiceCommandModal
        isOpen={isVoiceOpen}
        onClose={() => setIsVoiceOpen(false)}
        activities={activities}
        onConfirmUpdate={(actCode, prog, delay) => submitVoiceUpdate(actCode, prog, delay)}
      />

      <GeminiBrainModal
        isOpen={isGeminiOpen}
        onClose={() => setIsGeminiOpen(false)}
      />

      <ProjectOnboardModal
        isOpen={isOnboardOpen}
        onClose={() => setIsOnboardOpen(false)}
        onProjectCreated={() => refreshData()}
        onWipeData={() => workspace.wipeAllData()}
        onLoadBenchmark={() => workspace.loadBenchmark()}
      />
    </div>
  );
}
