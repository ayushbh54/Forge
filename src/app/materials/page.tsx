'use client';

import React, { useState } from 'react';
import { Sidebar } from '../../components/Sidebar';
import { Header } from '../../components/Header';
import { MaterialsStoresView } from '../../components/MaterialsStoresView';
import { LoginGateway } from '../../components/LoginGateway';
import { GeminiBrainModal } from '../../components/GeminiBrainModal';
import { ProjectOnboardModal } from '../../components/ProjectOnboardModal';
import { useWorkspace } from '../../context/WorkspaceContext';

export default function MaterialsPage() {
  const workspace = useWorkspace();
  const { user, isAuthenticated, currentProject, materials, conflicts, createMaterialTx, refreshData, sidebarCollapsed } = workspace;
  const [isGeminiOpen, setIsGeminiOpen] = useState(false);
  const [isOnboardOpen, setIsOnboardOpen] = useState(false);

  if (!isAuthenticated) {
    return <LoginGateway onLoginSuccess={() => refreshData()} />;
  }

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
          <span className="font-bold text-sm text-on-surface">Nirmaan OS — Materials & Stores Management</span>
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

      <main className={`${currentProject ? (sidebarCollapsed ? 'pl-[72px]' : 'pl-72') : 'pl-0'} pt-16 min-h-screen p-space-lg transition-all duration-300 ease-in-out`}>
        {!currentProject ? (
          <div className="max-w-xl mx-auto py-16 text-center flex flex-col items-center gap-4">
            <div className="w-16 h-16 rounded-full bg-surface-container-high flex items-center justify-center text-primary">
              <span className="material-symbols-outlined text-[32px]">inventory_2</span>
            </div>
            <h2 className="text-xl font-black text-on-surface">No Project Connected</h2>
            <p className="text-xs text-on-surface-variant">
              Please connect to a project workspace to manage Goods Receipt Notes (GRN) and Goods Issue Notes (GIN).
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
                  Central Stores Ledger & Pipe Spool Dispatch
                </h1>
                <p className="text-xs text-on-surface-variant font-mono">
                  Project: {currentProject.name} ({materials.length} Inward / Outward Ledger Records)
                </p>
              </div>

              <button
                onClick={() => setIsGeminiOpen(true)}
                className="px-3 py-1.5 bg-gradient-to-r from-primary/20 to-tertiary/20 text-on-surface border border-tertiary/40 font-semibold text-xs rounded-DEFAULT flex items-center gap-1.5"
              >
                <span className="material-symbols-outlined text-[16px] text-tertiary">psychology</span>
                <span>Gemini Spool Shortage Audit</span>
              </button>
            </div>

            <MaterialsStoresView
              materials={materials}
              onCreateTransaction={(tx) => {
                createMaterialTx(tx);
              }}
            />
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
