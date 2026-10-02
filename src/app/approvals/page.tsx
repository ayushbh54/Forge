'use client';

import React, { useState } from 'react';
import { Sidebar } from '../../components/Sidebar';
import { Header } from '../../components/Header';
import { GeminiBrainModal } from '../../components/GeminiBrainModal';
import { ProjectOnboardModal } from '../../components/ProjectOnboardModal';
import { useWorkspace } from '../../context/WorkspaceContext';

const INITIAL_APPROVALS = [
  {
    id: 'APP-DPR-044',
    title: 'Daily Construction Log Sign-off (DPR #44)',
    type: 'DPR_VERIFICATION',
    submittedBy: 'Vikram Joshi (Site Supervisor)',
    date: 'Today, 11:00 AM',
    scope: 'Trunk Line 24: 45m welding recorded, joints #W24-01 to #W24-06',
    status: 'PENDING',
  },
  {
    id: 'APP-VAR-012',
    title: 'Variation Request: Heavy Wall Elbow Spool Substitution',
    type: 'CONTRACT_VARIATION',
    submittedBy: 'Central Viaduct JV',
    date: 'Yesterday, 16:30 PM',
    scope: 'Substitute Grade X52 forged elbows with equivalent schedule 80 units under FIDIC 13.1',
    status: 'PENDING',
  },
  {
    id: 'APP-GIN-812',
    title: 'Goods Issue Note (GIN-2026-812) Clearance',
    type: 'STORES_ISSUE',
    submittedBy: 'Pranab Deka (Stores Controller)',
    date: 'Today, 09:15 AM',
    scope: '60m seamless line pipe issued to field trench gang',
    status: 'APPROVED',
  },
  {
    id: 'APP-EOT-004',
    title: 'Notice of Delay & EOT Claim under FIDIC 8.4',
    type: 'TIME_EXTENSION',
    submittedBy: 'Commercial Manager',
    date: '2 days ago',
    scope: '4-day float impact due to 3rd-party lab testing hold point',
    status: 'UNDER_REVIEW',
  },
];

export default function ApprovalsPage() {
  const workspace = useWorkspace();
  const { user, currentProject, conflicts, showToast, refreshData, sidebarCollapsed } = workspace;
  const [approvals, setApprovals] = useState(INITIAL_APPROVALS);
  const [isGeminiOpen, setIsGeminiOpen] = useState(false);
  const [isOnboardOpen, setIsOnboardOpen] = useState(false);

  const handleAction = (id: string, action: 'APPROVED' | 'REJECTED') => {
    setApprovals(prev => prev.map(a => a.id === id ? { ...a, status: action } : a));
    showToast(`Item [${id}] has been ${action} by ${user.name} (${user.fidicDesignation || user.role}). Recorded in audit ledger.`);
  };

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
          <span className="font-bold text-sm text-on-surface">Contractual Approvals Center</span>
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
        {/* Banner */}
        <div className="p-5 bg-surface-container-low border border-surface-container-high rounded-DEFAULT flex items-center justify-between">
          <div>
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-primary text-[22px]">assignment_turned_in</span>
              <h1 className="text-base font-bold uppercase tracking-wider text-on-surface">
                Engineering Governance & Contractual Approvals
              </h1>
            </div>
            <p className="text-xs text-on-surface-variant font-mono mt-0.5">
              FIDIC Clause 3.1 & 8.4 Authorized Workflow Gatekeeper · {currentProject?.name || 'Project'}
            </p>
          </div>

          <div className="flex items-center gap-3">
            <span className="px-3 py-1 rounded-full bg-primary/20 text-primary font-mono text-xs font-bold">
              {approvals.filter(a => a.status === 'PENDING').length} Pending Review
            </span>
            <button
              onClick={() => setIsGeminiOpen(true)}
              className="px-3 py-1.5 bg-gradient-to-r from-primary/20 to-tertiary/20 text-on-surface border border-tertiary/40 font-semibold text-xs rounded-DEFAULT flex items-center gap-1.5"
            >
              <span className="material-symbols-outlined text-[16px] text-tertiary">psychology</span>
              <span>Gemini Claim Check</span>
            </button>
          </div>
        </div>

        {/* Approvals Table */}
        <div className="bg-surface-container-lowest p-5 rounded-DEFAULT border border-surface-container-high shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="border-b border-surface-container-high text-on-surface-variant font-mono uppercase text-[11px]">
                  <th className="py-2.5 px-3">Reference ID</th>
                  <th className="py-2.5 px-3">Subject / Request</th>
                  <th className="py-2.5 px-3">Category</th>
                  <th className="py-2.5 px-3">Originator</th>
                  <th className="py-2.5 px-3">Date</th>
                  <th className="py-2.5 px-3">Status</th>
                  <th className="py-2.5 px-3 text-right">Engineer Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-container-high/40">
                {approvals.map((a) => (
                  <tr key={a.id} className="hover:bg-surface-container transition-colors">
                    <td className="py-3 px-3 font-mono font-bold text-primary">{a.id}</td>
                    <td className="py-3 px-3">
                      <div className="flex flex-col">
                        <span className="font-bold text-on-surface">{a.title}</span>
                        <span className="text-[11px] text-on-surface-variant max-w-md">{a.scope}</span>
                      </div>
                    </td>
                    <td className="py-3 px-3">
                      <span className="px-2 py-0.5 rounded-sm bg-surface-container text-on-surface font-mono text-[10px] uppercase">
                        {a.type}
                      </span>
                    </td>
                    <td className="py-3 px-3 text-on-surface-variant">{a.submittedBy}</td>
                    <td className="py-3 px-3 font-mono text-[11px] text-on-surface-variant whitespace-nowrap">{a.date}</td>
                    <td className="py-3 px-3">
                      <span className={`px-2 py-0.5 rounded-sm font-mono font-bold text-[10px] ${
                        a.status === 'APPROVED'
                          ? 'bg-tertiary/20 text-tertiary'
                          : a.status === 'REJECTED'
                          ? 'bg-error/20 text-error'
                          : 'bg-primary/20 text-primary'
                      }`}>
                        {a.status}
                      </span>
                    </td>
                    <td className="py-3 px-3 text-right whitespace-nowrap">
                      {a.status === 'PENDING' ? (
                        <div className="flex items-center justify-end gap-1.5">
                          <button
                            onClick={() => handleAction(a.id, 'APPROVED')}
                            className="px-2.5 py-1 bg-tertiary hover:bg-tertiary-container text-on-tertiary font-bold text-[11px] rounded-sm shadow-sm"
                          >
                            Approve
                          </button>
                          <button
                            onClick={() => handleAction(a.id, 'REJECTED')}
                            className="px-2.5 py-1 bg-error hover:bg-error-container text-on-error font-bold text-[11px] rounded-sm"
                          >
                            Reject
                          </button>
                        </div>
                      ) : (
                        <span className="text-[11px] font-mono text-on-surface-variant">Closed</span>
                      )}
                    </td>
                  </tr>
                ))}
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
