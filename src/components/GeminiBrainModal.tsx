'use client';

import React, { useState } from 'react';
import { useWorkspace } from '../context/WorkspaceContext';

interface GeminiBrainModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const GeminiBrainModal: React.FC<GeminiBrainModalProps> = ({ isOpen, onClose }) => {
  const workspace = useWorkspace();
  const [apiKeyInput, setApiKeyInput] = useState('');
  const [isKeySaved, setIsKeySaved] = useState(false);
  const [activeTab, setActiveTab] = useState<'COPILOT' | 'SCHEDULE_AUDIT' | 'NLP_TEST' | 'CONFIG'>('COPILOT');

  // Copilot Chat
  const [query, setQuery] = useState('');
  const [chatHistory, setChatHistory] = useState<Array<{ sender: 'user' | 'gemini'; text: string; timestamp: string }>>([
    {
      sender: 'gemini',
      text: `Hello! I am the **Gemini Autonomous Project Brain** for Nirmaan OS.\n\nI continuously supervise project schedules, analyze 5-factor progress triangulation, detect out-of-sequence activities, and draft FIDIC contractual notices.\n\nHow can I assist your project team today?`,
      timestamp: 'Just now',
    },
  ]);
  const [isLoading, setIsLoading] = useState(false);

  // Field NLP Test
  const [nlpInput, setNlpInput] = useState('Line 24 ka pipe installation 45 meter complete hai, lekin store se 2 spools nahi mile toh do joints pending hain.');
  const [nlpResult, setNlpResult] = useState<any>(null);

  if (!isOpen) return null;

  const handleSaveApiKey = async () => {
    if (!apiKeyInput.trim()) return;
    try {
      await fetch('/api/gemini', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'SET_KEY', apiKey: apiKeyInput.trim() }),
      });
      setIsKeySaved(true);
      workspace.showToast('Gemini API Key activated for live Gemini 2.0 inference!');
    } catch (e: any) {
      workspace.showToast('Failed to save API key');
    }
  };

  const handleSendChat = async (textToSend?: string) => {
    const message = textToSend || query;
    if (!message.trim()) return;

    const userEntry = { sender: 'user' as const, text: message, timestamp: 'Now' };
    setChatHistory(prev => [...prev, userEntry]);
    if (!textToSend) setQuery('');
    setIsLoading(true);

    try {
      const res = await fetch('/api/gemini', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'COPILOT_QUERY',
          payload: {
            query: message,
            projectId: workspace.currentProject?.id,
          },
          apiKey: apiKeyInput.trim() || undefined,
        }),
      });
      const data = await res.json();
      if (data.success) {
        setChatHistory(prev => [
          ...prev,
          { sender: 'gemini', text: data.reply, timestamp: new Date().toLocaleTimeString() },
        ]);
      } else {
        setChatHistory(prev => [
          ...prev,
          { sender: 'gemini', text: `Brain Error: ${data.error}`, timestamp: new Date().toLocaleTimeString() },
        ]);
      }
    } catch (e: any) {
      setChatHistory(prev => [
        ...prev,
        { sender: 'gemini', text: `Network error connecting to Gemini Brain: ${e.message}`, timestamp: new Date().toLocaleTimeString() },
      ]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleRunNlpTest = async () => {
    if (!nlpInput.trim()) return;
    setIsLoading(true);
    try {
      const res = await fetch('/api/gemini', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'PARSE_FIELD_UPDATE',
          payload: {
            rawText: nlpInput,
            projectId: workspace.currentProject?.id,
          },
          apiKey: apiKeyInput.trim() || undefined,
        }),
      });
      const data = await res.json();
      if (data.success) {
        setNlpResult(data.result);
      }
    } catch (e: any) {
      console.error(e);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-background/85 backdrop-blur-md animate-fade-in">
      <div className="w-full max-w-3xl bg-surface-container-lowest border border-surface-container-high rounded-xl shadow-2xl overflow-hidden flex flex-col h-[85vh]">
        {/* Header */}
        <div className="p-4 bg-surface-container flex items-center justify-between border-b border-surface-container-high">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-DEFAULT bg-gradient-to-tr from-primary to-tertiary flex items-center justify-center text-white shadow-md">
              <span className="material-symbols-outlined text-[20px]">psychology</span>
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="font-bold text-sm text-on-surface">Gemini Autonomous Project Brain</h2>
                <span className="px-1.5 py-0.5 rounded-sm bg-tertiary/15 text-tertiary text-[9px] font-mono font-bold flex items-center gap-1 border border-tertiary/30">
                  <span className="w-1.5 h-1.5 rounded-full bg-tertiary animate-pulse"></span>
                  Parallel Non-Clashing Core
                </span>
              </div>
              <p className="text-[11px] text-on-surface-variant font-mono">
                Multimodal Reasoning · Schedule Linking · 5-Factor Consensus · FIDIC Claims
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 flex items-center justify-center text-on-surface-variant hover:text-on-surface rounded-DEFAULT hover:bg-surface-container-high transition-colors"
          >
            <span className="material-symbols-outlined text-[18px]">close</span>
          </button>
        </div>

        {/* Navigation Tabs */}
        <div className="flex border-b border-surface-container-high bg-surface-container-low px-4 pt-2 gap-4 text-xs font-bold">
          <button
            onClick={() => setActiveTab('COPILOT')}
            className={`pb-2.5 border-b-2 flex items-center gap-1.5 transition-all ${
              activeTab === 'COPILOT'
                ? 'border-primary text-primary'
                : 'border-transparent text-on-surface-variant hover:text-on-surface'
            }`}
          >
            <span className="material-symbols-outlined text-[16px]">forum</span>
            <span>Interactive Copilot</span>
          </button>

          <button
            onClick={() => setActiveTab('NLP_TEST')}
            className={`pb-2.5 border-b-2 flex items-center gap-1.5 transition-all ${
              activeTab === 'NLP_TEST'
                ? 'border-primary text-primary'
                : 'border-transparent text-on-surface-variant hover:text-on-surface'
            }`}
          >
            <span className="material-symbols-outlined text-[16px]">cable</span>
            <span>Field Speech/Text Linking</span>
          </button>

          <button
            onClick={() => setActiveTab('CONFIG')}
            className={`pb-2.5 border-b-2 flex items-center gap-1.5 transition-all ${
              activeTab === 'CONFIG'
                ? 'border-primary text-primary'
                : 'border-transparent text-on-surface-variant hover:text-on-surface'
            }`}
          >
            <span className="material-symbols-outlined text-[16px]">key</span>
            <span>Gemini API Key & Engine</span>
          </button>
        </div>

        {/* Tab 1: Copilot Chat */}
        {activeTab === 'COPILOT' && (
          <div className="flex-1 flex flex-col overflow-hidden">
            {/* Messages Area */}
            <div className="flex-1 p-4 overflow-y-auto flex flex-col gap-3">
              {chatHistory.map((msg, i) => (
                <div
                  key={i}
                  className={`flex gap-3 max-w-[85%] ${
                    msg.sender === 'user' ? 'ml-auto flex-row-reverse' : 'mr-auto'
                  }`}
                >
                  <div
                    className={`w-7 h-7 rounded-full flex items-center justify-center shrink-0 ${
                      msg.sender === 'user'
                        ? 'bg-primary text-on-primary'
                        : 'bg-surface-container-high text-tertiary border border-surface-container-highest'
                    }`}
                  >
                    <span className="material-symbols-outlined text-[15px]">
                      {msg.sender === 'user' ? 'person' : 'smart_toy'}
                    </span>
                  </div>

                  <div
                    className={`p-3 rounded-lg text-xs leading-relaxed whitespace-pre-wrap ${
                      msg.sender === 'user'
                        ? 'bg-primary text-on-primary font-medium'
                        : 'bg-surface-container text-on-surface border border-surface-container-high shadow-sm'
                    }`}
                  >
                    {msg.text}
                    <div className="text-[9px] opacity-60 mt-1.5 text-right font-mono">{msg.timestamp}</div>
                  </div>
                </div>
              ))}
              {isLoading && (
                <div className="flex gap-2 items-center text-xs text-on-surface-variant font-mono p-2">
                  <span className="w-2 h-2 rounded-full bg-primary animate-ping"></span>
                  <span>Gemini Brain reasoning over schedule & telemetry...</span>
                </div>
              )}
            </div>

            {/* Quick Prompts */}
            <div className="px-4 py-2 bg-surface-container-low border-t border-surface-container-high/60 flex items-center gap-1.5 overflow-x-auto text-[11px]">
              <span className="text-on-surface-variant font-bold text-[10px] uppercase shrink-0">Quick Ask:</span>
              <button
                onClick={() => handleSendChat('Overall project status aur schedule health kya hai?')}
                className="px-2.5 py-1 bg-surface-container hover:bg-surface-container-high rounded-full border border-surface-container-high whitespace-nowrap"
              >
                Project Status Summary
              </button>
              <button
                onClick={() => handleSendChat('Line 24 ka schedule and progress breakdown batao')}
                className="px-2.5 py-1 bg-surface-container hover:bg-surface-container-high rounded-full border border-surface-container-high whitespace-nowrap"
              >
                Line 24 Deep-Dive
              </button>
              <button
                onClick={() => handleSendChat('Kaha delay ho raha hai aur contractual risk kya hai?')}
                className="px-2.5 py-1 bg-surface-container hover:bg-surface-container-high rounded-full border border-surface-container-high whitespace-nowrap"
              >
                Delays & FIDIC Risks
              </button>
            </div>

            {/* Input Form */}
            <div className="p-3 bg-surface-container border-t border-surface-container-high flex gap-2">
              <input
                type="text"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleSendChat()}
                placeholder="Ask Gemini in Hindi, English or Hinglish (e.g. 'Critical path activities me kya delay hai?')..."
                className="flex-1 p-2.5 bg-surface-container-low text-xs text-on-surface rounded-DEFAULT border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary"
              />
              <button
                onClick={() => handleSendChat()}
                disabled={isLoading || !query.trim()}
                className="px-4 bg-primary hover:bg-primary-container text-on-primary rounded-DEFAULT text-xs font-bold flex items-center gap-1 disabled:opacity-50"
              >
                <span className="material-symbols-outlined text-[16px]">send</span>
                <span>Ask</span>
              </button>
            </div>
          </div>
        )}

        {/* Tab 2: Field Speech/Text Linking */}
        {activeTab === 'NLP_TEST' && (
          <div className="flex-1 p-5 overflow-y-auto flex flex-col gap-4">
            <div className="p-3 bg-surface-container-low rounded-DEFAULT border border-surface-container-high text-xs text-on-surface-variant flex items-start gap-2">
              <span className="material-symbols-outlined text-primary text-[18px] shrink-0 mt-0.5">translate</span>
              <span>
                Enter informal site notes, WhatsApp audio transcript, or Hindi field memos. Gemini Brain extracts metrics, detects delays, and matches to the exact Primavera P6 activity code.
              </span>
            </div>

            <div className="flex flex-col gap-2">
              <label className="text-[11px] font-bold uppercase text-on-surface-variant">
                Raw Site Observation / Voice Note Transcript:
              </label>
              <textarea
                rows={3}
                value={nlpInput}
                onChange={(e) => setNlpInput(e.target.value)}
                className="w-full p-3 bg-surface-container-low text-xs text-on-surface rounded-DEFAULT border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary font-medium"
              />
              <div className="flex justify-between items-center">
                <div className="flex gap-2">
                  <button
                    onClick={() => setNlpInput('Line 24 ka pipe welding start ho gaya hai, 45 meter ready hai lekin 2 joints me NDT backlog hai.')}
                    className="text-[10px] text-primary hover:underline"
                  >
                    Sample 1: Line 24 Hindi
                  </button>
                  <span>•</span>
                  <button
                    onClick={() => setNlpInput('Pier 12 foundation pour completed 120 cubic meters concrete, heavy rain stopped pump.')}
                    className="text-[10px] text-primary hover:underline"
                  >
                    Sample 2: Civil Foundation
                  </button>
                </div>

                <button
                  onClick={handleRunNlpTest}
                  disabled={isLoading}
                  className="px-4 py-2 bg-primary hover:bg-primary-container text-on-primary font-bold text-xs rounded-DEFAULT shadow-sm flex items-center gap-1.5"
                >
                  <span className="material-symbols-outlined text-[16px]">psychology</span>
                  <span>{isLoading ? 'Processing...' : 'Run Gemini Linking Engine'}</span>
                </button>
              </div>
            </div>

            {nlpResult && (
              <div className="p-4 bg-surface-container-low rounded-DEFAULT border border-primary/40 flex flex-col gap-3 animate-fade-in shadow-sm">
                <div className="flex items-center justify-between border-b border-surface-container-high pb-2">
                  <div className="flex items-center gap-2">
                    <span className="px-2 py-0.5 bg-primary text-on-primary font-mono text-[10px] font-bold rounded-sm">
                      {nlpResult.matchedActivityCode}
                    </span>
                    <span className="font-bold text-xs text-on-surface">{nlpResult.activityName}</span>
                  </div>
                  <span className="text-tertiary font-mono text-xs font-bold bg-tertiary/10 px-2 py-0.5 rounded-sm border border-tertiary/20">
                    Confidence: {nlpResult.confidenceScore}%
                  </span>
                </div>

                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs">
                  <div className="p-2 bg-surface-container rounded-sm">
                    <span className="text-[10px] text-on-surface-variant block uppercase">Quantity</span>
                    <strong className="text-primary font-mono">{nlpResult.extractedQuantity} {nlpResult.unit}</strong>
                  </div>
                  <div className="p-2 bg-surface-container rounded-sm">
                    <span className="text-[10px] text-on-surface-variant block uppercase">Discipline</span>
                    <strong>{nlpResult.discipline}</strong>
                  </div>
                  <div className="p-2 bg-surface-container rounded-sm">
                    <span className="text-[10px] text-on-surface-variant block uppercase">Detected Delay</span>
                    <strong className={nlpResult.detectedDelay ? 'text-error' : 'text-on-surface-variant'}>
                      {nlpResult.detectedDelay || 'None'}
                    </strong>
                  </div>
                  <div className="p-2 bg-surface-container rounded-sm">
                    <span className="text-[10px] text-on-surface-variant block uppercase">Contractual Clause</span>
                    <strong className="text-secondary font-mono text-[10px]">{nlpResult.fidicClauseApplicable}</strong>
                  </div>
                </div>

                <div className="text-xs bg-surface-container-lowest p-3 rounded-sm border border-surface-container-high">
                  <span className="text-[10px] uppercase font-bold text-on-surface-variant block mb-1">Gemini AI Reasoning:</span>
                  <p className="text-on-surface-variant leading-relaxed">{nlpResult.aiReasoning}</p>
                </div>

                <div className="text-xs bg-primary/10 p-3 rounded-sm border border-primary/20">
                  <span className="text-[10px] uppercase font-bold text-primary block mb-1">Recommended Action:</span>
                  <p className="text-on-surface font-semibold">{nlpResult.suggestedAction}</p>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Tab 3: Configuration */}
        {activeTab === 'CONFIG' && (
          <div className="flex-1 p-5 overflow-y-auto flex flex-col gap-4 max-w-lg mx-auto w-full">
            <div className="p-4 bg-surface-container-low rounded-DEFAULT border border-surface-container-high flex flex-col gap-2">
              <span className="text-xs uppercase font-bold text-primary font-mono flex items-center gap-1.5">
                <span className="material-symbols-outlined text-[16px]">smart_toy</span>
                Google Gemini 2.0 Flash / Pro Integration
              </span>
              <p className="text-xs text-on-surface-variant leading-relaxed">
                Nirmaan OS uses a dual-engine architecture:
                <br />
                1. <strong>Local Deterministic Engine:</strong> 100% offline, zero-latency heuristic AI built-in.
                <br />
                2. <strong>Gemini 2.0 Cloud Brain:</strong> Enter your Google Gemini API key below to enable live multimodal audio transcript parsing and deep FIDIC contract analysis.
              </p>
            </div>

            <div className="flex flex-col gap-2">
              <label className="text-[11px] font-bold uppercase text-on-surface-variant">
                Google Gemini API Key (Optional)
              </label>
              <input
                type="password"
                value={apiKeyInput}
                onChange={(e) => setApiKeyInput(e.target.value)}
                placeholder="AIzaSy..."
                className="w-full p-2.5 bg-surface-container text-xs text-on-surface rounded-DEFAULT border border-surface-container-high font-mono"
              />
              <button
                onClick={handleSaveApiKey}
                className="self-end px-5 py-2 bg-primary hover:bg-primary-container text-on-primary font-bold text-xs rounded-DEFAULT shadow-sm flex items-center gap-1.5"
              >
                <span className="material-symbols-outlined text-[16px]">save</span>
                <span>{isKeySaved ? 'API Key Active ✓' : 'Save & Activate Key'}</span>
              </button>
            </div>

            <div className="p-3 bg-surface-container-lowest rounded-DEFAULT border border-surface-container-high text-[11px] text-on-surface-variant font-mono space-y-1">
              <div>• Model: <strong>gemini-2.0-flash</strong> (Low Latency / High Throughput)</div>
              <div>• Parallel Queue: Asynchronous background worker (Zero UI lockup)</div>
              <div>• Privacy: Project data never cached outside active session</div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
