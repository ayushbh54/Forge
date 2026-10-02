'use client';

import React, { useState } from 'react';
import { Sidebar } from '../../components/Sidebar';
import { Header } from '../../components/Header';
import { GeminiBrainModal } from '../../components/GeminiBrainModal';
import { ProjectOnboardModal } from '../../components/ProjectOnboardModal';
import { useWorkspace } from '../../context/WorkspaceContext';

const QUALITY_TESTS = [
  {
    id: 'LAB-2024-881',
    testType: 'ASTM C39 / C40-50 Concrete Compressive Strength',
    sampleBatch: 'Batch #LB-2024-881 (Pier 24 Cap)',
    specRequirement: '40.0 MPa at 28 Days',
    currentResult: '32.4 MPa at 7 Days (Pending 28-day break test)',
    status: 'PENDING_LAB',
    severity: 'CRITICAL',
  },
  {
    id: 'NDT-RT-044',
    testType: 'API 1104 / ASME B31.4 Radiographic Examination (RT)',
    sampleBatch: 'Joints #W24-01 to #W24-04 (Line 24)',
    specRequirement: '100% RT Coverage, Zero Crack / Lack of Penetration',
    currentResult: 'Passed (Films cleared by Level-II Inspector)',
    status: 'PASSED',
    severity: 'SAFE',
  },
  {
    id: 'NDT-RT-045',
    testType: 'API 1104 Radiographic Examination (RT)',
    sampleBatch: 'Joints #W24-05 & #W24-06 (Line 24)',
    specRequirement: '100% RT Coverage',
    currentResult: 'Hold Point Active: Darkroom film exposure queued',
    status: 'HOLD_POINT',
    severity: 'WARNING',
  },
];

const HSE_PERMITS = [
  {
    id: 'PTW-HOT-092',
    type: 'Hot Work Permit (Welding & Cutting)',
    location: 'Line 24 Trench Corridor (Chainage 14+300)',
    issuedTo: 'Tapan Das & Pipe Welding Gang',
    validTill: 'Today, 18:00 IST',
    status: 'ACTIVE_APPROVED',
  },
  {
    id: 'PTW-CONF-014',
    type: 'Confined Space & Deep Trenching Permit',
    location: 'Chainage 14+200 Deep Cut',
    issuedTo: 'Civil Trenching Team',
    validTill: 'Today, 17:00 IST',
    status: 'ACTIVE_APPROVED',
  },
];

export default function QualityHsePage() {
  const workspace = useWorkspace();
  const { user, currentProject, conflicts, showToast, refreshData, sidebarCollapsed } = workspace;
  const [tests, setTests] = useState(QUALITY_TESTS);
  const [isGeminiOpen, setIsGeminiOpen] = useState(false);
  const [isOnboardOpen, setIsOnboardOpen] = useState(false);

  const handleExpedite = (testId: string) => {
    showToast(`Expedite Notice sent to NABL Accredited Materials Testing Laboratory for [${testId}].`);
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
          <span className="font-bold text-sm text-on-surface">QA/QC & HSE Compliance</span>
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

      <main className={`${currentProject ? (sidebarCollapsed ? 'pl-[72px]' : 'pl-72') : 'pl-0'} pt-16 min-h-screen p-space-lg flex flex-col gap-5 transition-all duration-300 ease-in-out`}>
        {/* Banner */}
        <div className="p-5 bg-surface-container-low border border-surface-container-high rounded-DEFAULT flex items-center justify-between">
          <div>
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-primary text-[22px]">fact_check</span>
              <h1 className="text-base font-bold uppercase tracking-wider text-on-surface">
                QA/QC Inspection Protocols & HSE Compliance
              </h1>
            </div>
            <p className="text-xs text-on-surface-variant font-mono mt-0.5">
              ASTM / API / ISO Inspection Test Plans (ITP) & Safety Permits to Work (PTW) · {currentProject?.name || 'Project'}
            </p>
          </div>

          <div className="flex items-center gap-3">
            <span className="px-3 py-1 rounded-full bg-tertiary/20 text-tertiary font-mono text-xs font-bold">
              Zero Lost Time Incidents (LTI) · 412 Days
            </span>
            <button
              onClick={() => setIsGeminiOpen(true)}
              className="px-3 py-1.5 bg-gradient-to-r from-primary/20 to-tertiary/20 text-on-surface border border-tertiary/40 font-semibold text-xs rounded-DEFAULT flex items-center gap-1.5"
            >
              <span className="material-symbols-outlined text-[16px] text-tertiary">psychology</span>
              <span>Gemini QA Audit</span>
            </button>
          </div>
        </div>

        {/* Quality Lab Tests Section */}
        <div className="bg-surface-container-lowest p-5 rounded-DEFAULT border border-surface-container-high shadow-sm flex flex-col gap-3">
          <span className="text-xs font-bold uppercase tracking-wider text-on-surface font-mono">
            Active Quality Hold Points & NDT Test Certificates
          </span>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="border-b border-surface-container-high text-on-surface-variant font-mono uppercase text-[11px]">
                  <th className="py-2.5 px-3">Test Batch</th>
                  <th className="py-2.5 px-3">Test Standard</th>
                  <th className="py-2.5 px-3">Location / Scope</th>
                  <th className="py-2.5 px-3">Spec Requirement</th>
                  <th className="py-2.5 px-3">Observed Status</th>
                  <th className="py-2.5 px-3 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-container-high/40">
                {tests.map((t) => (
                  <tr key={t.id} className="hover:bg-surface-container transition-colors">
                    <td className="py-3 px-3 font-mono font-bold text-primary">{t.id}</td>
                    <td className="py-3 px-3 font-semibold text-on-surface">{t.testType}</td>
                    <td className="py-3 px-3 text-on-surface-variant">{t.sampleBatch}</td>
                    <td className="py-3 px-3 font-mono text-[11px] text-on-surface-variant">{t.specRequirement}</td>
                    <td className="py-3 px-3">
                      <span className={`px-2 py-0.5 rounded-sm font-mono font-bold text-[10px] ${
                        t.status === 'PASSED'
                          ? 'bg-tertiary/20 text-tertiary'
                          : t.status === 'HOLD_POINT'
                          ? 'bg-error/20 text-error'
                          : 'bg-primary/20 text-primary'
                      }`}>
                        {t.status}
                      </span>
                    </td>
                    <td className="py-3 px-3 text-right">
                      {t.status !== 'PASSED' && (
                        <button
                          onClick={() => handleExpedite(t.id)}
                          className="px-2.5 py-1 bg-surface-container hover:bg-surface-container-high text-primary border border-surface-container-high rounded-sm text-[11px] font-bold"
                        >
                          Expedite Lab
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* HSE Permits Section */}
        <div className="bg-surface-container-lowest p-5 rounded-DEFAULT border border-surface-container-high shadow-sm flex flex-col gap-3">
          <span className="text-xs font-bold uppercase tracking-wider text-on-surface font-mono">
            Safety Permits to Work (PTW) Live Gateway
          </span>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {HSE_PERMITS.map((p) => (
              <div key={p.id} className="p-3.5 bg-surface-container-low rounded-DEFAULT border border-surface-container-high flex flex-col gap-1">
                <div className="flex items-center justify-between">
                  <span className="font-mono text-primary font-bold text-xs">{p.id}</span>
                  <span className="px-2 py-0.5 rounded-sm bg-tertiary/20 text-tertiary font-mono text-[10px] font-bold">
                    {p.status}
                  </span>
                </div>
                <strong className="text-xs text-on-surface">{p.type}</strong>
                <span className="text-[11px] text-on-surface-variant">Location: {p.location}</span>
                <span className="text-[11px] text-on-surface-variant">Issued to: {p.issuedTo} (Valid till: {p.validTill})</span>
              </div>
            ))}
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
