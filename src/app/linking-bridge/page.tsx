'use client';

import React, { useState } from 'react';
import { Sidebar } from '../../components/Sidebar';
import { Header } from '../../components/Header';
import { VoiceCommandModal } from '../../components/VoiceCommandModal';
import { GeminiBrainModal } from '../../components/GeminiBrainModal';
import { ProjectOnboardModal } from '../../components/ProjectOnboardModal';
import { useWorkspace } from '../../context/WorkspaceContext';

export default function LinkingBridgePage() {
  const workspace = useWorkspace();
  const { user, currentProject, activities, conflicts, submitVoiceUpdate, refreshData, showToast } = workspace;

  const [isVoiceOpen, setIsVoiceOpen] = useState(false);
  const [isGeminiOpen, setIsGeminiOpen] = useState(false);
  const [isOnboardOpen, setIsOnboardOpen] = useState(false);

  const [testInput, setTestInput] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);
  const [geminiResult, setGeminiResult] = useState<any>(null);

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
    const act = activities.find(a => a.activityCode === actCode);
    const progress = Math.min(100, Math.round(((act?.installedQuantity || 0) + (qty || 15)) / (act?.plannedQuantity || 100) * 100));
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
          activeConflictsCount={conflicts.filter(c => c.status === 'OPEN').length}
        />
      )}

      <main className={`${currentProject ? 'pl-72' : 'pl-0'} pt-16 min-h-screen p-space-lg flex flex-col gap-4`}>
        {/* Banner */}
        <div className="p-5 bg-surface-container-low border border-surface-container-high rounded-DEFAULT flex items-center justify-between">
          <div className="flex items-center gap-3">
            <span className="w-10 h-10 rounded-DEFAULT bg-primary-container text-white flex items-center justify-center font-bold shadow-sm">
              <span className="material-symbols-outlined text-[22px]">cable</span>
            </span>
            <div>
              <h1 className="text-lg font-black text-on-surface">SIH26122 Intelligent Schedule-Linking Layer</h1>
              <p className="text-xs text-on-surface-variant font-mono">
                Oil India Limited · Automated Bridge between Field Reality (WhatsApp / Audio) & Primavera P6 WBS
              </p>
            </div>
          </div>

          <button
            onClick={() => setIsGeminiOpen(true)}
            className="px-3.5 py-2 bg-gradient-to-r from-primary/20 to-tertiary/20 text-on-surface border border-tertiary/40 font-semibold text-xs rounded-DEFAULT flex items-center gap-1.5 shadow-sm"
          >
            <span className="material-symbols-outlined text-[17px] text-tertiary">psychology</span>
            <span>Gemini Brain Assistant</span>
          </button>
        </div>

        {/* Live Interactive Parser Playground */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {/* Input Box */}
          <div className="bg-surface-container-lowest p-5 rounded-DEFAULT border border-surface-container-high flex flex-col gap-3 shadow-sm">
            <div className="flex items-center justify-between">
              <span className="text-xs uppercase font-bold text-primary font-mono flex items-center gap-1">
                <span className="material-symbols-outlined text-[16px]">mic</span>
                Multi-Modal Field Ingestion (Hindi / English / Hinglish)
              </span>
              <button
                onClick={() => setIsVoiceOpen(true)}
                className="px-3 py-1 bg-primary hover:bg-primary-container text-on-primary font-bold text-xs rounded-sm flex items-center gap-1"
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
              className="w-full p-3 bg-surface-container-low border border-surface-container-high rounded-sm text-xs text-on-surface focus:outline-none focus:ring-1 focus:ring-primary font-medium"
            />

            <div className="flex justify-between items-center">
              <div className="flex flex-wrap gap-1.5">
                <button
                  onClick={() => handleTestParse('Line 24 ka pipe installation start ho gaya hai, 45 meter welding complete hai, lekin spool delay ki wajah se do joints pending hain.')}
                  className="px-2.5 py-1 bg-surface-container hover:bg-surface-container-high text-[11px] text-on-surface-variant rounded-sm border border-surface-container-high"
                >
                  Sample 1: Line 24 Hindi Note
                </button>
                <button
                  onClick={() => handleTestParse('Pier 24 cap rebar 85 percent complete, pre-pour QA inspection passed.')}
                  className="px-2.5 py-1 bg-surface-container hover:bg-surface-container-high text-[11px] text-on-surface-variant rounded-sm border border-surface-container-high"
                >
                  Sample 2: Civil Rebar
                </button>
              </div>

              <button
                onClick={() => handleTestParse(testInput)}
                disabled={isProcessing || !testInput.trim()}
                className="px-5 py-2 bg-primary hover:bg-primary-container text-on-primary font-bold text-xs rounded-sm shadow-sm flex items-center gap-1.5 disabled:opacity-50"
              >
                <span className="material-symbols-outlined text-[16px]">psychology</span>
                <span>{isProcessing ? 'Analyzing...' : 'Parse & Link'}</span>
              </button>
            </div>
          </div>

          {/* Gemini AI Result Box */}
          <div className="bg-surface-container-lowest p-5 rounded-DEFAULT border border-surface-container-high flex flex-col gap-3 shadow-sm">
            <span className="text-xs uppercase font-bold text-tertiary font-mono flex items-center gap-1">
              <span className="material-symbols-outlined text-[16px]">hub</span>
              Gemini Entity Extraction & P6 WBS Match
            </span>

            {geminiResult ? (
              <div className="flex flex-col gap-3 animate-fade-in text-xs">
                <div className="p-3 bg-surface-container-low rounded-sm border border-primary/30 flex items-center justify-between">
                  <div>
                    <span className="font-mono text-primary font-bold">{geminiResult.matchedActivityCode}</span>
                    <h3 className="font-bold text-on-surface">{geminiResult.activityName}</h3>
                    <span className="text-[10px] text-on-surface-variant font-mono">WBS: {geminiResult.wbsCode} · Discipline: {geminiResult.discipline}</span>
                  </div>
                  <div className="text-right">
                    <span className="px-2 py-0.5 rounded-sm bg-tertiary/15 text-tertiary font-mono font-bold text-xs border border-tertiary/30">
                      {geminiResult.confidenceScore}% Match
                    </span>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-2 text-xs">
                  <div className="p-2 bg-surface-container rounded-sm">
                    <span className="text-[10px] uppercase text-on-surface-variant block">Quantity</span>
                    <strong className="text-primary font-mono">{geminiResult.extractedQuantity} {geminiResult.unit}</strong>
                  </div>
                  <div className="p-2 bg-surface-container rounded-sm">
                    <span className="text-[10px] uppercase text-on-surface-variant block">Detected Delay</span>
                    <strong className={geminiResult.detectedDelay ? 'text-error' : 'text-on-surface-variant'}>
                      {geminiResult.detectedDelay || 'None'}
                    </strong>
                  </div>
                </div>

                <div className="p-2.5 bg-surface-container-low rounded-sm border border-surface-container-high text-on-surface-variant leading-relaxed text-[11px]">
                  <strong>Gemini Reasoning:</strong> {geminiResult.aiReasoning}
                </div>

                <button
                  onClick={() => handleConfirmAndLink(geminiResult.matchedActivityCode, geminiResult.extractedQuantity)}
                  className="w-full py-2.5 bg-tertiary hover:bg-tertiary-container text-on-tertiary font-bold text-xs rounded-sm shadow-md flex items-center justify-center gap-1.5 transition-all active:scale-95"
                >
                  <span className="material-symbols-outlined text-[17px]">link</span>
                  <span>Confirm & Map to Primavera P6 Baseline</span>
                </button>
              </div>
            ) : (
              <div className="flex-1 flex flex-col items-center justify-center p-8 text-center text-on-surface-variant gap-2">
                <span className="material-symbols-outlined text-[36px] opacity-40">cable</span>
                <p className="text-xs">Type a site observation or click a sample to see Gemini AI schedule-linking in real time.</p>
              </div>
            )}
          </div>
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
