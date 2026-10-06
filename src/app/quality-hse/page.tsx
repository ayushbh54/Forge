'use client';

import React, { useState } from 'react';
import { Sidebar } from '../../components/Sidebar';
import { Header } from '../../components/Header';
import { LoginGateway } from '../../components/LoginGateway';
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
    testedAt: '2026-10-04 14:30',
    labName: 'NABL Accredited Material Test Lab Guwahati',
  },
  {
    id: 'NDT-RT-044',
    testType: 'API 1104 / ASME B31.4 Radiographic Examination (RT)',
    sampleBatch: 'Joints #W24-01 to #W24-04 (Line 24)',
    specRequirement: '100% RT Coverage, Zero Crack / Lack of Penetration',
    currentResult: 'Passed (Films cleared by Level-II Inspector)',
    status: 'PASSED',
    severity: 'SAFE',
    testedAt: '2026-10-05 11:15',
    labName: 'TUV Rheinland Industrial NDT Mobile Unit',
  },
  {
    id: 'NDT-RT-045',
    testType: 'API 1104 Radiographic Examination (RT)',
    sampleBatch: 'Joints #W24-05 & #W24-06 (Line 24)',
    specRequirement: '100% RT Coverage',
    currentResult: 'Hold Point Active: Darkroom film exposure queued',
    status: 'HOLD_POINT',
    severity: 'WARNING',
    testedAt: '2026-10-05 16:40',
    labName: 'TUV Rheinland Industrial NDT Mobile Unit',
  },
  {
    id: 'GEO-SPT-012',
    testType: 'IS 2131 Standard Penetration Test (SPT)',
    sampleBatch: 'Borehole BH-08 (River Crossing Bank)',
    specRequirement: 'N-Value > 28 for Pier Foundation Bearing',
    currentResult: 'N = 31 (Refusal achieved at -14.2m)',
    status: 'PASSED',
    severity: 'SAFE',
    testedAt: '2026-10-02 09:30',
    labName: 'Central Geotechnical Services Digboi',
  },
  {
    id: 'MPI-WELD-039',
    testType: 'ASME Sec V Art 7 Magnetic Particle Inspection (MPI)',
    sampleBatch: 'Fillet Welds on Compressor Skids #3 & #4',
    specRequirement: 'Zero linear indications or undercut > 0.5mm',
    currentResult: 'Passed (Visual and AC Yoke clearance)',
    status: 'PASSED',
    severity: 'SAFE',
    testedAt: '2026-10-03 15:10',
    labName: 'Site QAQC Inspection Agency',
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
  {
    id: 'PTW-LIFT-028',
    type: 'Critical Tandem Heavy Lift Permit (>20T)',
    location: 'River Crossing Approach Pier 24',
    issuedTo: 'Heavy Rigging Gang (Biren Chetia)',
    validTill: 'Yesterday, 19:00 IST',
    status: 'CLOSED_COMPLETED',
  },
];

export default function QualityHsePage() {
  const workspace = useWorkspace();
  const { user, isAuthenticated, currentProject, conflicts, weather, showToast, refreshData, sidebarCollapsed } = workspace;
  const [tests, setTests] = useState(QUALITY_TESTS);
  const [isGeminiOpen, setIsGeminiOpen] = useState(false);
  const [isOnboardOpen, setIsOnboardOpen] = useState(false);
  const [testSearch, setTestSearch] = useState('');
  const [testFilter, setTestFilter] = useState<'ALL' | 'HOLD_POINT' | 'PASSED' | 'PENDING'>('ALL');
  const [isWeatherHistoryExpanded, setIsWeatherHistoryExpanded] = useState(true);

  if (!isAuthenticated) {
    return <LoginGateway onLoginSuccess={() => refreshData()} />;
  }

  const handleExpedite = (testId: string) => {
    showToast(`Expedite Notice sent to NABL Accredited Materials Testing Laboratory for [${testId}].`);
  };

  const filteredTests = tests.filter((t) => {
    if (testFilter === 'HOLD_POINT' && t.status !== 'HOLD_POINT') return false;
    if (testFilter === 'PASSED' && t.status !== 'PASSED') return false;
    if (testFilter === 'PENDING' && t.status !== 'PENDING_LAB') return false;
    if (!testSearch.trim()) return true;
    const q = testSearch.toLowerCase();
    return (
      t.id.toLowerCase().includes(q) ||
      t.testType.toLowerCase().includes(q) ||
      t.sampleBatch.toLowerCase().includes(q) ||
      t.labName.toLowerCase().includes(q)
    );
  });

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
          activeConflictsCount={conflicts.filter((c) => c.status === 'OPEN').length}
        />
      )}

      <main
        className={`${
          currentProject ? (sidebarCollapsed ? 'pl-[72px]' : 'pl-72') : 'pl-0'
        } pt-16 min-h-screen p-space-lg flex flex-col gap-6 transition-all duration-300 ease-in-out`}
      >
        {/* Banner with Safety Metric */}
        <div className="p-5 bg-surface-container-low border border-surface-container-high rounded-xl flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-primary text-[24px]">fact_check</span>
              <h1 className="text-base font-bold text-on-surface">
                QA/QC Inspection Protocols & HSE Compliance
              </h1>
            </div>
            <p className="text-xs text-on-surface-variant font-mono mt-0.5">
              ASTM / API / ISO Inspection Test Plans (ITP) & Safety Permits to Work (PTW) · {currentProject?.name || 'Project'}
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2 shrink-0">
            <span className="px-3.5 py-1.5 rounded-lg bg-tertiary/20 text-tertiary font-mono text-xs font-bold border border-tertiary/30">
              Zero Lost Time Incidents (LTI) · 412 Days
            </span>
            <button
              onClick={() => setIsGeminiOpen(true)}
              className="px-3.5 py-1.5 bg-surface-container hover:bg-surface-container-high text-on-surface border border-surface-container-high font-semibold text-xs rounded-lg flex items-center gap-1.5 transition-all"
            >
              <span className="material-symbols-outlined text-[16px] text-tertiary">psychology</span>
              <span>Gemini QA Audit</span>
            </button>
          </div>
        </div>

        {/* Quality Lab Tests Section with Inline Filter & History */}
        <div className="bg-surface-container-lowest p-5 rounded-xl border border-surface-container-high shadow-sm flex flex-col gap-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-surface-container-high pb-3">
            <div>
              <h3 className="text-sm font-bold text-on-surface flex items-center gap-2">
                <span className="material-symbols-outlined text-primary text-[18px]">biotech</span>
                Active Quality Hold Points & Lab Test Certificates
              </h3>
              <p className="text-xs text-on-surface-variant">
                Mandatory NDT clearance and compressive break tests required before activity sign-off
              </p>
            </div>

            <div className="flex flex-wrap items-center gap-2">
              <div className="flex bg-surface-container rounded-lg p-0.5 border border-surface-container-high text-xs">
                <button
                  onClick={() => setTestFilter('ALL')}
                  className={`px-3 py-1 rounded font-semibold transition-all ${
                    testFilter === 'ALL'
                      ? 'bg-primary text-on-primary shadow-sm'
                      : 'text-on-surface-variant hover:text-on-surface'
                  }`}
                >
                  All ({tests.length})
                </button>
                <button
                  onClick={() => setTestFilter('HOLD_POINT')}
                  className={`px-3 py-1 rounded font-semibold transition-all ${
                    testFilter === 'HOLD_POINT'
                      ? 'bg-error text-on-error shadow-sm'
                      : 'text-on-surface-variant hover:text-on-surface'
                  }`}
                >
                  Hold Points
                </button>
                <button
                  onClick={() => setTestFilter('PASSED')}
                  className={`px-3 py-1 rounded font-semibold transition-all ${
                    testFilter === 'PASSED'
                      ? 'bg-tertiary text-on-tertiary shadow-sm'
                      : 'text-on-surface-variant hover:text-on-surface'
                  }`}
                >
                  Passed
                </button>
              </div>

              <div className="relative">
                <span className="material-symbols-outlined absolute left-2.5 top-2 text-[14px] text-on-surface-variant">
                  search
                </span>
                <input
                  type="text"
                  placeholder="Filter tests by ID / batch..."
                  value={testSearch}
                  onChange={(e) => setTestSearch(e.target.value)}
                  className="pl-8 pr-3 py-1.5 text-xs bg-surface-container-low text-on-surface rounded-lg border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary w-44 sm:w-56"
                />
              </div>
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="border-b border-surface-container-high text-on-surface-variant font-mono uppercase text-[11px] bg-surface-container-low/50">
                  <th className="py-2.5 px-3">Test Batch</th>
                  <th className="py-2.5 px-3">Test Standard</th>
                  <th className="py-2.5 px-3">Location / Scope</th>
                  <th className="py-2.5 px-3">Spec Requirement</th>
                  <th className="py-2.5 px-3">Observed Status</th>
                  <th className="py-2.5 px-3">Tested Date & Lab</th>
                  <th className="py-2.5 px-3 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-container-high/40">
                {filteredTests.map((t) => (
                  <tr key={t.id} className="hover:bg-surface-container-low transition-colors">
                    <td className="py-3 px-3 font-mono font-bold text-primary">{t.id}</td>
                    <td className="py-3 px-3 font-semibold text-on-surface">{t.testType}</td>
                    <td className="py-3 px-3 text-on-surface-variant">{t.sampleBatch}</td>
                    <td className="py-3 px-3 font-mono text-[11px] text-on-surface-variant">{t.specRequirement}</td>
                    <td className="py-3 px-3">
                      <span
                        className={`px-2 py-0.5 rounded font-mono font-bold text-[10px] ${
                          t.status === 'PASSED'
                            ? 'bg-tertiary/20 text-tertiary border border-tertiary/30'
                            : t.status === 'HOLD_POINT'
                            ? 'bg-error/20 text-error border border-error/30'
                            : 'bg-primary/20 text-primary border border-primary/30'
                        }`}
                      >
                        {t.status}
                      </span>
                    </td>
                    <td className="py-3 px-3 text-on-surface-variant font-mono text-[11px]">
                      <div>{t.testedAt}</div>
                      <div className="text-[10px] text-on-surface-variant/70 truncate max-w-[150px]">{t.labName}</div>
                    </td>
                    <td className="py-3 px-3 text-right">
                      {t.status !== 'PASSED' ? (
                        <button
                          onClick={() => handleExpedite(t.id)}
                          className="px-2.5 py-1 bg-surface-container hover:bg-surface-container-high text-primary border border-surface-container-high rounded text-[11px] font-bold"
                        >
                          Expedite Lab
                        </button>
                      ) : (
                        <span className="text-tertiary font-mono text-[11px]">✓ Cleared</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Safety Permits Section */}
        <div className="bg-surface-container-lowest p-5 rounded-xl border border-surface-container-high shadow-sm flex flex-col gap-3">
          <div className="flex items-center justify-between border-b border-surface-container-high pb-3">
            <span className="text-xs font-bold uppercase tracking-wider text-on-surface font-mono flex items-center gap-1.5">
              <span className="material-symbols-outlined text-tertiary text-[18px]">verified_user</span>
              Safety Permits to Work (PTW) Live Gateway
            </span>
            <span className="text-xs text-on-surface-variant font-mono">3 Active Permits Valid Today</span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            {HSE_PERMITS.map((p) => (
              <div
                key={p.id}
                className="p-3.5 bg-surface-container-low rounded-xl border border-surface-container-high flex flex-col justify-between gap-2"
              >
                <div>
                  <div className="flex items-center justify-between">
                    <span className="font-mono text-primary font-bold text-xs">{p.id}</span>
                    <span
                      className={`px-2 py-0.5 rounded font-mono text-[10px] font-bold ${
                        p.status.includes('ACTIVE')
                          ? 'bg-tertiary/20 text-tertiary'
                          : 'bg-surface-container text-on-surface-variant'
                      }`}
                    >
                      {p.status}
                    </span>
                  </div>
                  <strong className="text-xs text-on-surface block mt-1">{p.type}</strong>
                  <span className="text-[11px] text-on-surface-variant block mt-0.5">Loc: {p.location}</span>
                </div>
                <div className="text-[11px] text-on-surface-variant pt-2 border-t border-surface-container-high/60 font-mono">
                  Issued to: {p.issuedTo}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Inline Structured FIDIC Cl. 8.4(c) Extreme Weather Stoppage & Monsoon Delay History */}
        <div className="border border-surface-container-high rounded-xl bg-surface-container-lowest overflow-hidden shadow-sm">
          <div className="p-4 bg-surface-container-low/70 flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-surface-container-high">
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-lg bg-secondary/15 flex items-center justify-center text-secondary">
                <span className="material-symbols-outlined text-[18px]">cloud</span>
              </div>
              <div>
                <h3 className="text-sm font-bold text-on-surface flex items-center gap-2">
                  FIDIC Cl. 8.4(c) Weather Stoppage & Monsoon Delay History
                  <span className="px-2 py-0.5 rounded-full bg-secondary/20 text-secondary text-[10px] font-mono font-bold">
                    Telemetry Verified
                  </span>
                </h3>
                <p className="text-[11px] text-on-surface-variant">
                  Contractual evidentiary trail for Extension of Time (EoT) claims under adverse climatic conditions
                </p>
              </div>
            </div>

            <button
              onClick={() => setIsWeatherHistoryExpanded(!isWeatherHistoryExpanded)}
              className="px-3 py-1.5 bg-surface-container hover:bg-surface-container-high text-on-surface rounded-lg text-xs font-semibold flex items-center gap-1 transition-colors self-end sm:self-center"
            >
              <span className="material-symbols-outlined text-[16px]">
                {isWeatherHistoryExpanded ? 'expand_less' : 'expand_more'}
              </span>
              <span>{isWeatherHistoryExpanded ? 'Collapse' : 'Show All'}</span>
            </button>
          </div>

          {isWeatherHistoryExpanded && (
            <div className="p-4 flex flex-col gap-4">
              {/* Telemetry Current Readings */}
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 bg-surface-container-low p-3.5 rounded-xl border border-surface-container-high">
                <div>
                  <span className="text-[10px] uppercase font-mono text-on-surface-variant block">Station Sensor</span>
                  <span className="text-xs font-bold text-on-surface">Oil India Duliajan (27.48°N, 95.32°E)</span>
                </div>
                <div>
                  <span className="text-[10px] uppercase font-mono text-on-surface-variant block">24h Rainfall</span>
                  <span className="text-xs font-mono font-bold text-error">45.0 mm (Exceeds 25mm Threshold)</span>
                </div>
                <div>
                  <span className="text-[10px] uppercase font-mono text-on-surface-variant block">EoT Days Entitled</span>
                  <span className="text-xs font-mono font-bold text-tertiary">+8 Calendar Days (FIDIC 8.4c)</span>
                </div>
                <div>
                  <span className="text-[10px] uppercase font-mono text-on-surface-variant block">Contract Status</span>
                  <span className="text-xs font-bold text-secondary">Active Force Majeure Window</span>
                </div>
              </div>

              {/* Suspended Activities History Table */}
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs border-collapse">
                  <thead>
                    <tr className="border-b border-surface-container-high bg-surface-container-low/40 text-on-surface-variant font-mono uppercase text-[11px]">
                      <th className="py-2.5 px-3">Activity Code</th>
                      <th className="py-2.5 px-3">Name & Chainage</th>
                      <th className="py-2.5 px-3">Stoppage Trigger</th>
                      <th className="py-2.5 px-3">Crew Size</th>
                      <th className="py-2.5 px-3">Slippage Impact</th>
                      <th className="py-2.5 px-3">Mitigation / Protective Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-surface-container-high/40">
                    <tr className="hover:bg-surface-container-low transition-colors">
                      <td className="py-3 px-3 font-mono font-bold text-primary">PIP-L5-024</td>
                      <td className="py-3 px-3 font-semibold text-on-surface">Piping Line 24 (Welding & Laying) · Station 14+200</td>
                      <td className="py-3 px-3 text-error font-medium">Precipitation &gt;15mm/hr safety cutoff</td>
                      <td className="py-3 px-3 font-mono">38 Welders/Riggers</td>
                      <td className="py-3 px-3 font-mono font-bold text-error">1.0 Day</td>
                      <td className="py-3 px-3 text-on-surface-variant text-[11px]">Hydrostatic end caps installed; gang shifted to shop bay</td>
                    </tr>
                    <tr className="hover:bg-surface-container-low transition-colors">
                      <td className="py-3 px-3 font-mono font-bold text-primary">CIV-L5-019</td>
                      <td className="py-3 px-3 font-semibold text-on-surface">Foundation Pours & Micro-Piles · Compressor Bay Unit 3</td>
                      <td className="py-3 px-3 text-error font-medium">Water-cement ratio wash risk & trench flooding</td>
                      <td className="py-3 px-3 font-mono">24 Workers</td>
                      <td className="py-3 px-3 font-mono font-bold text-error">1.5 Days</td>
                      <td className="py-3 px-3 text-on-surface-variant text-[11px]">Mixers rerouted; curing tarps deployed; dewatering pumps on</td>
                    </tr>
                    <tr className="hover:bg-surface-container-low transition-colors">
                      <td className="py-3 px-3 font-mono font-bold text-primary">NDT-L6-044</td>
                      <td className="py-3 px-3 font-semibold text-on-surface">Crane Erection & RT Girth Weld Inspection · Area 1</td>
                      <td className="py-3 px-3 text-secondary font-medium">Lightning hazard within 15km; ground bearing loss</td>
                      <td className="py-3 px-3 font-mono">12 Riggers</td>
                      <td className="py-3 px-3 font-mono text-secondary">0.5 Day</td>
                      <td className="py-3 px-3 text-on-surface-variant text-[11px]">Boom lowered to 15° storm cradle; outrigger mats secured</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          )}
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
