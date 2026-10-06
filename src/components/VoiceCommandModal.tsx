'use client';

import React, { useState } from 'react';
import { extractEntitiesFromFieldText, matchEntitiesToActivities, MatchResult } from '../lib/linkingEngine';
import { ScheduleActivity } from '../types';

interface VoiceCommandModalProps {
  isOpen: boolean;
  onClose: () => void;
  activities: ScheduleActivity[];
  onConfirmUpdate: (activityCode: string, progress: number, delayReason?: string, rawText?: string) => void;
}

export const VoiceCommandModal: React.FC<VoiceCommandModalProps> = ({
  isOpen,
  onClose,
  activities,
  onConfirmUpdate,
}) => {
  const [inputText, setInputText] = useState('');
  const [isRecording, setIsRecording] = useState(false);
  const [recordingSeconds, setRecordingSeconds] = useState(0);
  const [selectedDialect, setSelectedDialect] = useState<'HINGLISH' | 'HINDI' | 'ENGLISH' | 'ASSAMESE' | 'BENGALI'>('HINGLISH');
  const [matchResult, setMatchResult] = useState<MatchResult | null>(null);
  const [extractedData, setExtractedData] = useState<ReturnType<typeof extractEntitiesFromFieldText> | null>(null);
  const [isHistoryExpanded, setIsHistoryExpanded] = useState(true);

  // Past Voice Updates History
  const [voiceHistory, setVoiceHistory] = useState([
    {
      id: 'VOICE-REC-4019',
      transcript: 'Pier 24 caisson well sinking reached -48.5m with 78% progress, high river current delay',
      activityCode: 'PIP-L5-024',
      activityName: 'Substructure Well Sinking (P1-P24)',
      progress: 78,
      delayReason: 'High river current / monsoon water level rise',
      time: 'Today, 10:14 AM',
      dialect: 'Hinglish',
    },
    {
      id: 'VOICE-REC-3982',
      transcript: 'M60 HPC Pier Cap rebar binding 85 percent complete, pre-pour QA cube test passed',
      activityCode: 'PIP-L5-024',
      activityName: 'M60 HPC Pier Cap Structural Concrete Pour',
      progress: 85,
      delayReason: 'None',
      time: 'Yesterday, 04:30 PM',
      dialect: 'English',
    },
    {
      id: 'VOICE-REC-3741',
      transcript: 'Stay cable strand tensioning on Pier 24 completed 42%, zero relaxation confirmed',
      activityCode: 'ACT-3088',
      activityName: 'Stay Cable Strand Tensioning & Anchor Locking',
      progress: 42,
      delayReason: 'None',
      time: '04 Oct, 02:15 PM',
      dialect: 'Hinglish',
    },
  ]);

  if (!isOpen) return null;

  const quickExamples = [
    {
      text: 'Pier 24 caisson well sinking reached -48.5m with 78% progress, high river current delay',
      label: 'Bridge Well Sinking (P-24)',
    },
    {
      text: 'M60 HPC Pier Cap concrete pour 85 percent complete, 7-day cube strength passed',
      label: 'M60 HPC Pier Cap',
    },
    {
      text: 'Stay cable strand tensioning on Pier 24 completed 42%, zero relaxation confirmed',
      label: '1860 MPa Stay Cables',
    },
    {
      text: 'Line 24 ka pipe installation 68 percent update karo and reason material delay add karo',
      label: 'Line 24 Pipeline',
    },
  ];

  const handleProcessText = (text: string) => {
    setInputText(text);
    const entities = extractEntitiesFromFieldText(text);
    setExtractedData(entities);
    const matches = matchEntitiesToActivities(entities, activities);
    if (matches.length > 0) {
      setMatchResult(matches[0]);
    } else {
      setMatchResult(null);
    }
  };

  const handleToggleVoice = () => {
    if (!isRecording) {
      setIsRecording(true);
      setRecordingSeconds(0);
      const interval = setInterval(() => {
        setRecordingSeconds((prev) => prev + 1);
      }, 1000);

      // Simulate live recording speech recognition intake
      setTimeout(() => {
        clearInterval(interval);
        setIsRecording(false);
        const sampleText =
          selectedDialect === 'HINDI'
            ? 'पियर 24 का वेल सिंकिंग 78 प्रतिशत पूरा हुआ, नदी में तेज बहाव के कारण विलंब'
            : selectedDialect === 'ASSAMESE'
            ? 'পিয়াৰ ২৪ ৰ ৱেল চিংকিং ৭৮ শতাংশ সম্পূৰ্ণ, ব্ৰহ্মপুত্ৰৰ পানী বৃদ্ধিৰ বাবে পলম'
            : 'Pier 24 caisson well sinking reached -48.5m with 78% progress, high river current delay';
        handleProcessText(sampleText);
      }, 2500);
    } else {
      setIsRecording(false);
    }
  };

  const handleConfirm = () => {
    if (matchResult && extractedData) {
      const progress = extractedData.progressPercentage || matchResult.activity.contractorReportedProgress;
      onConfirmUpdate(matchResult.activity.activityCode, progress, extractedData.delayReason, inputText);

      // Add to local history log
      const newRecord = {
        id: `VOICE-REC-${Math.floor(1000 + Math.random() * 9000)}`,
        transcript: inputText,
        activityCode: matchResult.activity.activityCode,
        activityName: matchResult.activity.name,
        progress: progress,
        delayReason: extractedData.delayReason || 'None',
        time: 'Just Now',
        dialect: selectedDialect,
      };
      setVoiceHistory([newRecord, ...voiceHistory]);

      onClose();
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-background/80 backdrop-blur-md animate-fade-in overflow-y-auto">
      <div className="relative w-full max-w-2xl bg-surface-container-lowest border border-surface-container-high rounded-2xl shadow-2xl overflow-hidden flex flex-col my-8">
        {/* Header */}
        <div className="p-4 sm:p-5 bg-surface-container flex items-center justify-between border-b border-surface-container-high">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-primary/15 border border-primary/30 flex items-center justify-center text-primary">
              <span className="material-symbols-outlined text-[22px]">mic</span>
            </div>
            <div>
              <h2 className="font-bold text-sm text-white flex items-center gap-2">
                <span>Voice-to-Project Updater & P6 Schedule Sync</span>
                <span className="px-2 py-0.5 rounded-full bg-tertiary/15 text-tertiary text-[10px] font-mono font-bold">
                  AI Entity Extraction
                </span>
              </h2>
              <p className="text-[11px] text-on-surface-variant">
                Hands-Free Daily Progress Logging (Hindi, Hinglish, Assamese, Bengali, English)
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 flex items-center justify-center text-on-surface-variant hover:text-white rounded-lg hover:bg-surface-container-high transition-colors"
          >
            <span className="material-symbols-outlined text-[20px]">close</span>
          </button>
        </div>

        {/* Content Body */}
        <div className="p-5 flex flex-col gap-4 max-h-[75vh] overflow-y-auto">
          {/* Dialect Selector Banner */}
          <div className="flex flex-wrap items-center justify-between gap-2 p-2.5 bg-surface-container-low rounded-xl border border-surface-container-high">
            <span className="text-[11px] font-bold text-on-surface-variant uppercase tracking-wider">
              Speech Dialect Model:
            </span>
            <div className="flex items-center gap-1 overflow-x-auto text-xs">
              {[
                { id: 'HINGLISH', label: 'Hinglish' },
                { id: 'HINDI', label: 'हिन्दी' },
                { id: 'ENGLISH', label: 'English' },
                { id: 'ASSAMESE', label: 'অসমীয়া' },
                { id: 'BENGALI', label: 'বাংলা' },
              ].map((d) => (
                <button
                  key={d.id}
                  onClick={() => setSelectedDialect(d.id as any)}
                  className={`px-2.5 py-1 rounded-md text-[11px] font-bold transition-colors ${
                    selectedDialect === d.id
                      ? 'bg-primary text-white'
                      : 'bg-surface-container text-on-surface-variant hover:text-white'
                  }`}
                >
                  {d.label}
                </button>
              ))}
            </div>
          </div>

          {/* Quick Bridge & Industrial Prompts */}
          <div className="flex flex-col gap-1.5">
            <span className="text-[11px] uppercase font-bold text-on-surface-variant tracking-wider">
              Quick Voice Presets (Tap to Test Engine):
            </span>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
              {quickExamples.map((ex, idx) => (
                <button
                  key={idx}
                  onClick={() => handleProcessText(ex.text)}
                  className="p-2.5 text-left bg-surface-container-low hover:bg-surface-container text-on-surface hover:text-white rounded-xl text-[11px] border border-surface-container-high transition-all flex flex-col gap-1"
                >
                  <span className="text-primary font-bold text-[10px] uppercase font-mono">{ex.label}</span>
                  <span className="text-on-surface-variant truncate">"{ex.text}"</span>
                </button>
              ))}
            </div>
          </div>

          {/* Voice Input Textarea & Live Animated Record Button */}
          <div className="flex flex-col gap-2">
            <div className="relative">
              <textarea
                value={inputText}
                onChange={(e) => handleProcessText(e.target.value)}
                placeholder="Speak or type your update (e.g. Pier 24 well sinking 78 percent update karo and reason high river current add karo...)"
                rows={3}
                className="w-full p-3.5 bg-surface-container-low text-white text-xs rounded-xl border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary placeholder:text-on-surface-variant/60 font-medium resize-none leading-relaxed"
              />
              <button
                onClick={handleToggleVoice}
                className={`absolute right-3 bottom-3 h-9 px-3.5 rounded-lg font-bold text-xs flex items-center gap-2 transition-all shadow-sm ${
                  isRecording
                    ? 'bg-red-500 text-white animate-pulse'
                    : 'bg-primary text-white hover:bg-primary-container'
                }`}
              >
                <span className="material-symbols-outlined text-[16px]">
                  {isRecording ? 'graphic_eq' : 'mic'}
                </span>
                <span>{isRecording ? `Listening (00:0${recordingSeconds})...` : 'Voice Record'}</span>
              </button>
            </div>

            {/* Live Audio Equalizer Waveform Animation */}
            {isRecording && (
              <div className="p-3 bg-red-500/10 border border-red-500/30 rounded-xl flex items-center justify-between gap-3 animate-fade-in">
                <div className="flex items-center gap-2 text-red-400 text-xs font-mono">
                  <span className="w-2 h-2 rounded-full bg-red-500 animate-ping" />
                  <span>Acoustic Neural Stream: Active ({selectedDialect})</span>
                </div>
                {/* 10 Animated Bars */}
                <div className="flex items-center gap-1 h-6">
                  {[12, 22, 16, 24, 10, 18, 20, 14, 22, 10].map((h, i) => (
                    <div
                      key={i}
                      className="w-1 bg-red-400 rounded-full animate-bounce"
                      style={{ height: `${h}px`, animationDelay: `${i * 90}ms` }}
                    />
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* AI NLP Extracted Entities Breakdown */}
          {extractedData && (
            <div className="p-3.5 bg-surface-container-low rounded-xl border border-surface-container-high flex flex-col gap-2">
              <span className="text-[11px] uppercase font-bold text-on-surface-variant tracking-wider">
                AI Extracted Structural Entities
              </span>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs font-mono">
                <div className="p-2 bg-surface-container rounded-lg">
                  <span className="text-[10px] text-on-surface-variant block uppercase">Discipline</span>
                  <span className="text-primary font-bold">{extractedData.discipline || 'CIVIL'}</span>
                </div>
                <div className="p-2 bg-surface-container rounded-lg">
                  <span className="text-[10px] text-on-surface-variant block uppercase">Line / Pier Tag</span>
                  <span className="text-secondary font-bold">{extractedData.lineOrTag || 'Pier P-24'}</span>
                </div>
                <div className="p-2 bg-surface-container rounded-lg">
                  <span className="text-[10px] text-on-surface-variant block uppercase">Progress</span>
                  <span className="text-tertiary font-bold">
                    {extractedData.progressPercentage ? `${extractedData.progressPercentage}%` : 'N/A'}
                  </span>
                </div>
                <div className="p-2 bg-surface-container rounded-lg">
                  <span className="text-[10px] text-on-surface-variant block uppercase">Quantity</span>
                  <span className="text-white font-bold">
                    {extractedData.quantity ? `${extractedData.quantity} ${extractedData.unit || ''}` : '-48.5m MSL'}
                  </span>
                </div>
              </div>
              {extractedData.delayReason && (
                <div className="p-2 bg-secondary/10 border border-secondary/20 rounded-lg text-secondary text-xs flex items-center gap-2">
                  <span className="material-symbols-outlined text-[16px]">report_problem</span>
                  <span>Delay Factor Logged: {extractedData.delayReason}</span>
                </div>
              )}
            </div>
          )}

          {/* Matched L5/L6 Schedule Activity */}
          {matchResult ? (
            <div className="p-3.5 bg-surface-container-low border border-primary/40 rounded-xl flex flex-col gap-2">
              <div className="flex items-center justify-between">
                <span className="text-[11px] uppercase font-bold text-primary tracking-wider flex items-center gap-1.5">
                  <span className="material-symbols-outlined text-[16px]">link</span>
                  <span>Matched Schedule Activity (Confidence: {Math.round(matchResult.confidenceScore * 100)}%)</span>
                </span>
                <span className="font-mono text-xs font-bold px-2 py-0.5 rounded-full bg-primary/20 text-primary">
                  {matchResult.activity.activityCode}
                </span>
              </div>
              <div className="flex flex-col">
                <span className="text-xs font-bold text-white">{matchResult.activity.name}</span>
                <span className="text-[11px] text-on-surface-variant font-mono">
                  WBS: {matchResult.activity.wbsCode} · Current Baseline: {matchResult.activity.plannedProgress}%
                </span>
              </div>

              {matchResult.isOutOfSequence && (
                <div className="p-2 bg-red-500/10 border border-red-500/30 rounded-lg text-red-400 text-xs flex items-start gap-1.5">
                  <span className="material-symbols-outlined text-[16px] flex-shrink-0 mt-0.5">warning</span>
                  <span>{matchResult.outOfSequenceWarning}</span>
                </div>
              )}
            </div>
          ) : inputText.length > 5 ? (
            <div className="p-3 bg-surface-container-low border border-surface-container-high rounded-xl text-xs text-on-surface-variant text-center">
              Direct L5/L6 match pending. You can still confirm to link to current active activity.
            </div>
          ) : null}

          {/* INLINE EXPANDABLE VOICE UPDATE HISTORY SECTION RIGHT BELOW */}
          <div className="p-3.5 bg-surface-container-low rounded-xl border border-surface-container-high flex flex-col gap-2.5">
            <div
              onClick={() => setIsHistoryExpanded(!isHistoryExpanded)}
              className="flex items-center justify-between cursor-pointer select-none"
            >
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-primary text-[18px]">history</span>
                <h4 className="text-xs font-bold uppercase tracking-wider text-white flex items-center gap-2">
                  <span>Voice Update History & P6 Synchronized Entries</span>
                  <span className="px-2 py-0.5 rounded-full bg-primary/20 text-primary text-[10px] font-mono">
                    {voiceHistory.length} Recorded
                  </span>
                </h4>
              </div>
              <span className="material-symbols-outlined text-on-surface-variant text-[18px]">
                {isHistoryExpanded ? 'expand_less' : 'expand_more'}
              </span>
            </div>

            {isHistoryExpanded && (
              <div className="flex flex-col gap-2 pt-2 border-t border-surface-container-high/60 animate-fade-in">
                {voiceHistory.map((item) => (
                  <div
                    key={item.id}
                    className="p-2.5 bg-surface-container rounded-lg border border-surface-container-high/70 flex flex-col gap-1 text-xs"
                  >
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-white text-[11px]">{item.activityName}</span>
                      <span className="px-1.5 py-0.2 rounded bg-tertiary/15 text-tertiary font-mono font-bold text-[10px]">
                        {item.progress}% Progress
                      </span>
                    </div>
                    <p className="text-[11px] text-on-surface-variant italic">"{item.transcript}"</p>
                    <div className="flex items-center justify-between text-[10px] text-outline font-mono pt-0.5">
                      <span>
                        Dialect: {item.dialect} · Delay: {item.delayReason}
                      </span>
                      <span>{item.time}</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Action Footer */}
        <div className="p-4 bg-surface-container border-t border-surface-container-high flex items-center justify-between">
          <button
            onClick={onClose}
            className="px-4 py-2 text-xs font-semibold text-on-surface-variant hover:text-white rounded-lg transition-colors"
          >
            Cancel
          </button>
          <button
            disabled={!matchResult}
            onClick={handleConfirm}
            className="px-5 py-2.5 text-xs font-bold bg-primary text-white hover:bg-primary-container disabled:opacity-40 disabled:pointer-events-none rounded-xl transition-all shadow-sm flex items-center gap-2"
          >
            <span className="material-symbols-outlined text-[16px]">check_circle</span>
            <span>Confirm Link & Sync to DPR / P6</span>
          </button>
        </div>
      </div>
    </div>
  );
};
