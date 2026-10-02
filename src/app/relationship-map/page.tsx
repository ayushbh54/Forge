'use client';

import React, { useState } from 'react';
import { Sidebar } from '../../components/Sidebar';
import { Header } from '../../components/Header';
import { RelationshipGraph } from '../../components/RelationshipGraph';
import { GeminiBrainModal } from '../../components/GeminiBrainModal';
import { ProjectOnboardModal } from '../../components/ProjectOnboardModal';
import { useWorkspace } from '../../context/WorkspaceContext';

export default function RelationshipMapPage() {
  const workspace = useWorkspace();
  const { user, currentProject, activities, conflicts, refreshData, sidebarCollapsed } = workspace;
  const [isGeminiOpen, setIsGeminiOpen] = useState(false);
  const [isOnboardOpen, setIsOnboardOpen] = useState(false);
  const [selectedCode, setSelectedCode] = useState(activities[0]?.activityCode || '');

  const activeActivity = activities.find(a => a.activityCode === selectedCode) || activities[0];

  return (
    <div className="min-h-screen bg-background text-on-surface">
      {currentProject ? (
        <Header
          user={user}
          project={currentProject}
          onOpenVoiceModal={() => {}}
          onOpenGeminiBrain={() => setIsGeminiOpen(true)}
          isMobileHUD={false}
          onToggleMobileHUD={() => {}}
        />
      ) : (
        <header className="fixed top-0 left-0 right-0 h-16 bg-surface-container border-b border-surface-container-high px-6 z-40 flex items-center justify-between">
          <span className="font-bold text-sm text-on-surface">Universal Work ID (UWID) Topology</span>
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

      <main className={`${currentProject ? (sidebarCollapsed ? 'pl-[72px]' : 'pl-72') : 'pl-0'} pt-16 min-h-screen p-space-lg flex flex-col gap-4 transition-all duration-300 ease-in-out`}>
        {!currentProject || !activeActivity ? (
          <div className="max-w-xl mx-auto py-16 text-center flex flex-col items-center gap-4">
            <div className="w-16 h-16 rounded-full bg-surface-container-high flex items-center justify-center text-primary">
              <span className="material-symbols-outlined text-[32px]">hub</span>
            </div>
            <h2 className="text-xl font-black text-on-surface">No Activity Semantic Graph Available</h2>
            <p className="text-xs text-on-surface-variant">
              Please onboard a project or load the official Oil India benchmark to explore the 9-node semantic topology.
            </p>
            <button
              onClick={() => setIsOnboardOpen(true)}
              className="px-5 py-2.5 bg-primary text-on-primary font-bold text-xs rounded-DEFAULT"
            >
              + Onboard Project / Connect ID
            </button>
          </div>
        ) : (
          <div className="flex flex-col gap-4">
            <div className="flex items-center justify-between bg-surface-container-low p-4 rounded-DEFAULT border border-surface-container-high">
              <div>
                <h1 className="text-base font-black text-on-surface">
                  Universal Work ID (UWID) 9-Node Semantic Topology
                </h1>
                <p className="text-xs text-on-surface-variant font-mono">
                  {currentProject.name} · Selected Node: {activeActivity.activityCode} ({activeActivity.name})
                </p>
              </div>

              {activities.length > 1 && (
                <select
                  value={activeActivity.activityCode}
                  onChange={(e) => setSelectedCode(e.target.value)}
                  className="p-2 bg-surface-container text-xs text-on-surface rounded-DEFAULT border border-surface-container-high"
                >
                  {activities.map((a) => (
                    <option key={a.activityCode} value={a.activityCode}>
                      {a.activityCode} - {a.name}
                    </option>
                  ))}
                </select>
              )}
            </div>

            <RelationshipGraph activity={activeActivity} />
          </div>
        )}
      </main>

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
