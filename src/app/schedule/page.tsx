'use client';

import React, { useState } from 'react';
import { Sidebar } from '../../components/Sidebar';
import { Header } from '../../components/Header';
import { GanttScheduleView } from '../../components/GanttScheduleView';
import { LoginGateway } from '../../components/LoginGateway';
import { ProjectOnboardModal } from '../../components/ProjectOnboardModal';
import { GeminiBrainModal } from '../../components/GeminiBrainModal';
import { VoiceCommandModal } from '../../components/VoiceCommandModal';
import { useWorkspace } from '../../context/WorkspaceContext';

export default function SchedulePage() {
  const workspace = useWorkspace();
  const { user, isAuthenticated, currentProject, activities, conflicts, submitVoiceUpdate, refreshData, sidebarCollapsed } = workspace;
  const [selectedActCode, setSelectedActCode] = useState<string>(activities[0]?.activityCode || '');
  const [isOnboardOpen, setIsOnboardOpen] = useState(false);
  const [isGeminiOpen, setIsGeminiOpen] = useState(false);
  const [isVoiceOpen, setIsVoiceOpen] = useState(false);

  if (!isAuthenticated) {
    return <LoginGateway onLoginSuccess={() => refreshData()} />;
  }

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
          <span className="font-bold text-sm text-on-surface">Nirmaan OS — Primavera P6 Schedule Matrix</span>
          <button
            onClick={() => setIsOnboardOpen(true)}
            className="px-4 py-2 bg-primary text-on-primary font-bold text-xs rounded-DEFAULT"
          >
            + Import P6 Schedule
          </button>
        </header>
      )}

      {currentProject && (
        <Sidebar
          project={currentProject}
          activeConflictsCount={conflicts.filter(c => c.status === 'OPEN').length}
        />
      )}

      <main className={`${currentProject ? (sidebarCollapsed ? 'pl-[72px]' : 'pl-72') : 'pl-0'} pt-16 min-h-screen p-space-lg transition-all duration-300 ease-in-out`}>
        {!currentProject || activities.length === 0 ? (
          <div className="max-w-2xl mx-auto py-16 text-center flex flex-col items-center gap-4">
            <div className="w-16 h-16 rounded-full bg-surface-container-high flex items-center justify-center text-primary">
              <span className="material-symbols-outlined text-[32px]">calendar_month</span>
            </div>
            <h2 className="text-xl font-black text-on-surface">No Schedule Activities Found</h2>
            <p className="text-xs text-on-surface-variant max-w-md">
              Upload your Primavera P6 (.xml / .xer) or MS Project schedule to populate WBS L1–L6 activities, critical path, and float metrics.
            </p>
            <div className="flex gap-2 mt-2">
              <button
                onClick={() => setIsOnboardOpen(true)}
                className="px-5 py-2.5 bg-primary text-on-primary font-bold text-xs rounded-DEFAULT shadow-sm flex items-center gap-2"
              >
                <span className="material-symbols-outlined text-[16px]">upload_file</span>
                <span>Import Primavera P6 / CSV</span>
              </button>
              <button
                onClick={() => workspace.loadBenchmark()}
                className="px-5 py-2.5 bg-surface-container text-on-surface font-bold text-xs rounded-DEFAULT border border-surface-container-high"
              >
                Load Oil India Benchmark
              </button>
            </div>
          </div>
        ) : (
          <div className="flex flex-col gap-4">
            <div className="flex items-center justify-between bg-surface-container-low p-4 rounded-DEFAULT border border-surface-container-high">
              <div>
                <h1 className="text-base font-black text-on-surface">
                  Primavera P6 & MS Project Schedule Master
                </h1>
                <p className="text-xs text-on-surface-variant font-mono">
                  Project: {currentProject.name} ({activities.length} WBS Activities · {activities.filter(a => a.isCriticalPath).length} Critical Path)
                </p>
              </div>

              <div className="flex gap-2">
                <button
                  onClick={() => setIsGeminiOpen(true)}
                  className="px-3 py-1.5 bg-gradient-to-r from-primary/20 to-tertiary/20 text-on-surface border border-tertiary/40 font-semibold text-xs rounded-DEFAULT flex items-center gap-1.5"
                >
                  <span className="material-symbols-outlined text-[16px] text-tertiary">psychology</span>
                  <span>Gemini Float Audit</span>
                </button>
                <button
                  onClick={() => setIsOnboardOpen(true)}
                  className="px-3.5 py-1.5 bg-primary text-on-primary font-bold text-xs rounded-DEFAULT flex items-center gap-1.5 shadow-sm"
                >
                  <span className="material-symbols-outlined text-[16px]">upload_file</span>
                  <span>Import / Append Schedule</span>
                </button>
              </div>
            </div>

            <GanttScheduleView
              activities={activities}
              wbsNodes={[]}
              selectedActivityCode={selectedActCode || activities[0].activityCode}
              onSelectActivity={(code) => setSelectedActCode(code)}
            />
          </div>
        )}
      </main>

      <ProjectOnboardModal
        isOpen={isOnboardOpen}
        onClose={() => setIsOnboardOpen(false)}
        onProjectCreated={() => refreshData()}
        onWipeData={() => workspace.wipeAllData()}
        onLoadBenchmark={() => workspace.loadBenchmark()}
      />

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
    </div>
  );
}
