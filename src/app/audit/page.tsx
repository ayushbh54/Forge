'use client';

import React, { useState } from 'react';
import { Sidebar } from '../../components/Sidebar';
import { Header } from '../../components/Header';
import { GeminiBrainModal } from '../../components/GeminiBrainModal';
import { ProjectOnboardModal } from '../../components/ProjectOnboardModal';
import { useWorkspace } from '../../context/WorkspaceContext';

export default function AuditPage() {
  const workspace = useWorkspace();
  const { user, currentProject, auditLogs, conflicts, refreshData } = workspace;
  const [isGeminiOpen, setIsGeminiOpen] = useState(false);
  const [isOnboardOpen, setIsOnboardOpen] = useState(false);

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
          <span className="font-bold text-sm text-on-surface">Deterministic Audit Ledger</span>
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
        <div className="p-5 bg-surface-container-low border border-surface-container-high rounded-DEFAULT flex items-center justify-between">
          <div>
            <h1 className="text-base font-bold uppercase tracking-wider text-on-surface">
              Deterministic Tamper-Proof Audit Trail (SQLite Ledger)
            </h1>
            <p className="text-xs text-on-surface-variant font-mono mt-0.5">
              Permanent immutable transaction history of progress triangulation, voice notes, GRN/GIN & approvals · {currentProject?.name || 'Workspace'}
            </p>
          </div>
          <span className="px-3 py-1 rounded-full bg-tertiary/20 text-tertiary font-mono text-xs font-bold">
            SHA-256 Verified ({auditLogs.length} Records)
          </span>
        </div>

        <div className="bg-surface-container-lowest p-5 rounded-DEFAULT border border-surface-container-high shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="border-b border-surface-container-high text-on-surface-variant font-mono uppercase text-[11px]">
                  <th className="py-2.5 px-3">Timestamp</th>
                  <th className="py-2.5 px-3">Actor & Role</th>
                  <th className="py-2.5 px-3">Action</th>
                  <th className="py-2.5 px-3">Entity ID</th>
                  <th className="py-2.5 px-3">State Transition</th>
                  <th className="py-2.5 px-3">Reason & Context</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-container-high/40">
                {auditLogs.map((log) => (
                  <tr key={log.id} className="hover:bg-surface-container transition-colors">
                    <td className="py-3 px-3 font-mono text-[11px] text-on-surface-variant whitespace-nowrap">
                      {log.timestamp}
                    </td>
                    <td className="py-3 px-3">
                      <div className="flex flex-col">
                        <span className="font-bold text-on-surface">{log.actorName}</span>
                        <span className="text-[10px] text-on-surface-variant">{log.actorRole}</span>
                      </div>
                    </td>
                    <td className="py-3 px-3">
                      <span className="px-2 py-0.5 rounded-sm bg-primary/10 text-primary font-mono font-bold text-[10px]">
                        {log.action}
                      </span>
                    </td>
                    <td className="py-3 px-3 font-mono text-secondary font-bold">
                      {log.entityId}
                    </td>
                    <td className="py-3 px-3">
                      <div className="flex items-center gap-1 font-mono text-[11px]">
                        {log.previousValue && (
                          <>
                            <span className="text-on-surface-variant line-through">{log.previousValue}</span>
                            <span>→</span>
                          </>
                        )}
                        <span className="text-tertiary font-bold">{log.newValue}</span>
                      </div>
                    </td>
                    <td className="py-3 px-3 text-on-surface-variant leading-relaxed max-w-xs">
                      {log.reason}
                    </td>
                  </tr>
                ))}
                {auditLogs.length === 0 && (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-on-surface-variant">
                      No audit transactions recorded in SQLite yet.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
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
