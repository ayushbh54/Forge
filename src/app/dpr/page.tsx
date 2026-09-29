'use client';

import React, { useState } from 'react';
import { Sidebar } from '../../components/Sidebar';
import { Header } from '../../components/Header';
import { InteractiveDprView } from '../../components/InteractiveDprView';
import { GeminiBrainModal } from '../../components/GeminiBrainModal';
import { VoiceCommandModal } from '../../components/VoiceCommandModal';
import { ProjectOnboardModal } from '../../components/ProjectOnboardModal';
import { useWorkspace } from '../../context/WorkspaceContext';

export default function DprPage() {
  const workspace = useWorkspace();
  const { user, currentProject, activities, conflicts, submitDpr, submitVoiceUpdate, refreshData } = workspace;
  const [isGeminiOpen, setIsGeminiOpen] = useState(false);
  const [isVoiceOpen, setIsVoiceOpen] = useState(false);
  const [isOnboardOpen, setIsOnboardOpen] = useState(false);

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
          <span className="font-bold text-sm text-on-surface">Nirmaan OS — Daily Construction Log (DPR)</span>
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

      <main className={`${currentProject ? 'pl-72' : 'pl-0'} pt-16 min-h-screen p-space-lg`}>
        {!currentProject || activities.length === 0 ? (
          <div className="max-w-xl mx-auto py-16 text-center flex flex-col items-center gap-4">
            <div className="w-16 h-16 rounded-full bg-surface-container-high flex items-center justify-center text-primary">
              <span className="material-symbols-outlined text-[32px]">history_edu</span>
            </div>
            <h2 className="text-xl font-black text-on-surface">No Active Project for DPR Entry</h2>
            <p className="text-xs text-on-surface-variant">
              Please onboard a project or load the official Oil India benchmark to start logging daily construction progress and contractor field slips.
            </p>
            <button
              onClick={() => setIsOnboardOpen(true)}
              className="px-5 py-2.5 bg-primary text-on-primary font-bold text-xs rounded-DEFAULT"
            >
              + Onboard Project / Import P6
            </button>
          </div>
        ) : (
          <InteractiveDprView
            activities={activities}
            onSubmitDpr={(actCode, qty, unit, delay, notes) => {
              submitDpr(actCode, qty, unit, delay, notes);
            }}
          />
        )}
      </main>

      <GeminiBrainModal
        isOpen={isGeminiOpen}
        onClose={() => setIsGeminiOpen(false)}
      />

      <VoiceCommandModal
        isOpen={isVoiceOpen}
        onClose={() => setIsVoiceOpen(false)}
        activities={activities}
        onConfirmUpdate={(actCode, prog, delay) => submitVoiceUpdate(actCode, prog, delay)}
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
