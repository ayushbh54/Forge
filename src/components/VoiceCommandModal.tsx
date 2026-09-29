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
  const [matchResult, setMatchResult] = useState<MatchResult | null>(null);
  const [extractedData, setExtractedData] = useState<ReturnType<typeof extractEntitiesFromFieldText> | null>(null);

  if (!isOpen) return null;

  const quickExamples = [
    'Line 24 ka pipe installation 68 percent update karo and reason material delay add karo',
    'Pier 24 cap rebar 85 percent complete, pre-pour QA inspection passed',
    'Line 24 trench excavation 100 percent complete, ready for lower-in',
    'Substation cable laying started, 15 percent complete with 2 stations',
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
      // Simulate live recording audio intake
      setTimeout(() => {
        setIsRecording(false);
        handleProcessText('Line 24 ka pipe installation 68 percent update karo and reason material delay add karo');
      }, 2500);
    } else {
      setIsRecording(false);
    }
  };

  const handleConfirm = () => {
    if (matchResult && extractedData) {
      const progress = extractedData.progressPercentage || matchResult.activity.contractorReportedProgress;
      onConfirmUpdate(matchResult.activity.activityCode, progress, extractedData.delayReason, inputText);
      onClose();
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-background/80 backdrop-blur-sm animate-fade-in">
      <div className="relative w-full max-w-2xl bg-surface-container-lowest border border-surface-container-high rounded-lg shadow-2xl overflow-hidden flex flex-col">
        {/* Header */}
        <div className="p-4 bg-surface-container flex items-center justify-between border-b border-surface-container-high">
          <div className="flex items-center gap-2">
            <span className="w-8 h-8 rounded-DEFAULT bg-primary-container flex items-center justify-center text-white">
              <span className="material-symbols-outlined text-[18px]">mic</span>
            </span>
            <div>
              <h2 className="font-semibold text-sm text-on-surface">Intelligent Schedule-Linking Layer</h2>
              <p className="text-[11px] text-on-surface-variant">SIH26122 Voice & Multi-Modal Field Capture (Hindi / English)</p>
            </div>
          </div>
          <button 
            onClick={onClose}
            className="w-8 h-8 flex items-center justify-center text-on-surface-variant hover:text-on-surface rounded-DEFAULT hover:bg-surface-container-high transition-colors"
          >
            <span className="material-symbols-outlined text-[18px]">close</span>
          </button>
        </div>

        {/* Content Body */}
        <div className="p-5 flex flex-col gap-4">
          {/* Quick Prompts */}
          <div className="flex flex-col gap-1.5">
            <span className="text-[11px] uppercase font-bold text-on-surface-variant tracking-wider">Quick Site Updates (Tap to test):</span>
            <div className="flex flex-wrap gap-1.5">
              {quickExamples.map((ex, idx) => (
                <button
                  key={idx}
                  onClick={() => handleProcessText(ex)}
                  className="px-2.5 py-1 text-left bg-surface-container hover:bg-surface-container-high text-on-surface-variant hover:text-on-surface rounded-DEFAULT text-[11px] border border-surface-container-high transition-all"
                >
                  "{ex.slice(0, 48)}..."
                </button>
              ))}
            </div>
          </div>

          {/* Voice Input Textarea & Record Button */}
          <div className="flex flex-col gap-2">
            <div className="relative">
              <textarea
                value={inputText}
                onChange={(e) => handleProcessText(e.target.value)}
                placeholder="Bolkar ya likhkar update karein (e.g. Line 24 ka pipe installation 68 percent update karo...)"
                rows={3}
                className="w-full p-3 bg-surface-container-low text-on-surface text-sm rounded-DEFAULT border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary placeholder:text-outline-variant font-medium resize-none"
              />
              <button
                onClick={handleToggleVoice}
                className={`absolute right-3 bottom-3 h-9 px-3 rounded-DEFAULT font-semibold text-xs flex items-center gap-1.5 transition-all shadow-sm ${
                  isRecording 
                    ? 'bg-error text-white animate-pulse' 
                    : 'bg-primary text-on-primary hover:bg-primary-container'
                }`}
              >
                <span className="material-symbols-outlined text-[16px]">
                  {isRecording ? 'graphic_eq' : 'mic'}
                </span>
                <span>{isRecording ? 'Listening...' : 'Voice Record'}</span>
              </button>
            </div>
            {isRecording && (
              <div className="flex items-center gap-2 p-2 bg-error-container/20 rounded-DEFAULT text-error text-xs">
                <span className="w-2 h-2 rounded-full bg-error animate-ping"></span>
                <span>Listening in Hindi & English audio stream... बोलिए, हम सुन रहे हैं।</span>
              </div>
            )}
          </div>

          {/* NLP Extraction Preview */}
          {extractedData && (
            <div className="p-3 bg-surface-container-low rounded-DEFAULT border border-surface-container-high flex flex-col gap-2">
              <span className="text-[11px] uppercase font-bold text-on-surface-variant tracking-wider">AI Extracted Entities</span>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs font-mono">
                <div className="p-2 bg-surface-container rounded-sm">
                  <span className="text-[10px] text-on-surface-variant block uppercase">Discipline</span>
                  <span className="text-primary font-bold">{extractedData.discipline || 'Undetected'}</span>
                </div>
                <div className="p-2 bg-surface-container rounded-sm">
                  <span className="text-[10px] text-on-surface-variant block uppercase">Line / Tag</span>
                  <span className="text-secondary font-bold">{extractedData.lineOrTag || 'General'}</span>
                </div>
                <div className="p-2 bg-surface-container rounded-sm">
                  <span className="text-[10px] text-on-surface-variant block uppercase">Progress</span>
                  <span className="text-tertiary font-bold">{extractedData.progressPercentage ? `${extractedData.progressPercentage}%` : 'N/A'}</span>
                </div>
                <div className="p-2 bg-surface-container rounded-sm">
                  <span className="text-[10px] text-on-surface-variant block uppercase">Quantity</span>
                  <span className="text-on-surface font-bold">{extractedData.quantity ? `${extractedData.quantity} ${extractedData.unit || ''}` : 'N/A'}</span>
                </div>
              </div>
              {extractedData.delayReason && (
                <div className="p-2 bg-secondary/10 border border-secondary/20 rounded-sm text-secondary text-xs flex items-center gap-1.5">
                  <span className="material-symbols-outlined text-[16px]">report_problem</span>
                  <span>Delay Flag: {extractedData.delayReason}</span>
                </div>
              )}
            </div>
          )}

          {/* Matched L5/L6 Schedule Activity */}
          {matchResult ? (
            <div className="p-3 bg-surface-container-low border border-primary/30 rounded-DEFAULT flex flex-col gap-2">
              <div className="flex items-center justify-between">
                <span className="text-[11px] uppercase font-bold text-primary tracking-wider flex items-center gap-1">
                  <span className="material-symbols-outlined text-[16px]">link</span>
                  Matched Schedule Activity (Confidence: {Math.round(matchResult.confidenceScore * 100)}%)
                </span>
                <span className="font-mono text-xs font-bold px-2 py-0.5 rounded-full bg-primary/20 text-primary">
                  {matchResult.activity.activityCode}
                </span>
              </div>
              <div className="flex flex-col">
                <span className="text-sm font-semibold text-on-surface">{matchResult.activity.name}</span>
                <span className="text-xs text-on-surface-variant">WBS: {matchResult.activity.wbsCode} · Baseline: {matchResult.activity.plannedProgress}%</span>
              </div>

              {/* Out-of-Sequence Warning Check (P6 feature) */}
              {matchResult.isOutOfSequence && (
                <div className="p-2 bg-error-container/20 border border-error/30 rounded-sm text-error text-xs flex items-start gap-1.5">
                  <span className="material-symbols-outlined text-[16px] flex-shrink-0 mt-0.5">warning</span>
                  <span>{matchResult.outOfSequenceWarning}</span>
                </div>
              )}
            </div>
          ) : inputText.length > 5 ? (
            <div className="p-3 bg-surface-container-low border border-surface-container-high rounded-DEFAULT text-xs text-on-surface-variant text-center">
              No direct L5/L6 activity match found with high confidence. You can select an activity manually.
            </div>
          ) : null}
        </div>

        {/* Action Footer */}
        <div className="p-4 bg-surface-container border-t border-surface-container-high flex items-center justify-between">
          <button
            onClick={onClose}
            className="px-4 py-2 text-xs font-semibold text-on-surface-variant hover:text-on-surface rounded-DEFAULT transition-colors"
          >
            Cancel
          </button>
          <button
            disabled={!matchResult}
            onClick={handleConfirm}
            className="px-5 py-2 text-xs font-bold bg-primary text-on-primary hover:bg-primary-container disabled:opacity-40 disabled:pointer-events-none rounded-DEFAULT transition-all shadow-sm flex items-center gap-1.5"
          >
            <span className="material-symbols-outlined text-[16px]">check_circle</span>
            <span>Confirm Link & Update Progress</span>
          </button>
        </div>
      </div>
    </div>
  );
};
