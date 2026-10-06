'use client';

import React, { useState } from 'react';
import { Sidebar } from '../../components/Sidebar';
import { Header } from '../../components/Header';
import { LoginGateway } from '../../components/LoginGateway';
import { GeminiBrainModal } from '../../components/GeminiBrainModal';
import { ProjectOnboardModal } from '../../components/ProjectOnboardModal';
import { useWorkspace } from '../../context/WorkspaceContext';

export default function EquipmentPage() {
  const workspace = useWorkspace();
  const {
    user,
    isAuthenticated,
    currentProject,
    conflicts,
    equipment: workspaceEquipment,
    recordEquipmentBreakdown,
    refreshData,
    sidebarCollapsed,
    showToast,
  } = workspace;

  const [isGeminiOpen, setIsGeminiOpen] = useState(false);
  const [isOnboardOpen, setIsOnboardOpen] = useState(false);
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'STANDBY' | 'BREAKDOWN'>('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [isHistoryExpanded, setIsHistoryExpanded] = useState(true);

  // Breakdown Reporting Modal State
  const [showBreakdownModal, setShowBreakdownModal] = useState(false);
  const [selectedEqId, setSelectedEqId] = useState('');
  const [breakdownReason, setBreakdownReason] = useState('Hydraulic Hose Rupture on Boom Ram');
  const [downtimeHours, setDowntimeHours] = useState(6);
  const [notes, setNotes] = useState('Requires emergency field technician and 3/4" high pressure hose replacement.');
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (!isAuthenticated) {
    return <LoginGateway onLoginSuccess={() => refreshData()} />;
  }

  // Fallback to active fleet items if database has empty list
  const fleetList = workspaceEquipment && workspaceEquipment.length > 0 ? workspaceEquipment : [];

  const filteredFleet = fleetList.filter((eq) => {
    const matchesFilter =
      statusFilter === 'ALL' ||
      (statusFilter === 'ACTIVE' && (eq.status === 'ACTIVE' || eq.status === 'ACTIVE_DEPLOYED')) ||
      (statusFilter === 'STANDBY' && eq.status === 'STANDBY') ||
      (statusFilter === 'BREAKDOWN' && (eq.status === 'BREAKDOWN' || eq.status === 'MAINTENANCE'));

    if (!matchesFilter) return false;
    if (!searchQuery.trim()) return true;
    const q = searchQuery.toLowerCase();
    return (
      eq.id.toLowerCase().includes(q) ||
      eq.name.toLowerCase().includes(q) ||
      (eq.tag && eq.tag.toLowerCase().includes(q)) ||
      (eq.operator && eq.operator.toLowerCase().includes(q))
    );
  });

  // History: any equipment that has had a breakdown recorded
  const breakdownHistory = fleetList.filter(
    (eq) => eq.lastBreakdownReason || eq.status === 'BREAKDOWN' || eq.status === 'MAINTENANCE'
  );

  const handleOpenBreakdown = (eqId?: string) => {
    setSelectedEqId(eqId || (fleetList[0]?.id ?? 'EQ-CRANE-04'));
    setShowBreakdownModal(true);
  };

  const handleSubmitBreakdown = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedEqId) {
      showToast('Please select a piece of equipment');
      return;
    }
    setIsSubmitting(true);
    try {
      const ok = await recordEquipmentBreakdown(selectedEqId, breakdownReason, downtimeHours, notes);
      if (ok) {
        setShowBreakdownModal(false);
      }
    } finally {
      setIsSubmitting(false);
    }
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
          <span className="font-bold text-sm text-on-surface">Heavy Machinery & Equipment Telemetry</span>
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
        {/* Banner with Metrics & Quick Breakdown Action */}
        <div className="p-5 bg-surface-container-low border border-surface-container-high rounded-xl flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-primary text-[24px]">precision_manufacturing</span>
              <h1 className="text-base font-bold text-on-surface">
                Heavy Plant & Machinery Telematics Hub
              </h1>
            </div>
            <p className="text-xs text-on-surface-variant font-mono mt-0.5">
              Live IoT Sensors, Fuel Telemetry, Maintenance Windows & Downtime Logs · {currentProject?.name || 'Workspace'}
            </p>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            <button
              onClick={() => handleOpenBreakdown()}
              className="px-3.5 py-2 bg-error text-on-error hover:bg-error/90 font-bold text-xs rounded-lg flex items-center gap-1.5 shadow-sm transition-all"
            >
              <span className="material-symbols-outlined text-[16px]">report_problem</span>
              <span>Report Plant Breakdown</span>
            </button>

            <button
              onClick={() => setIsGeminiOpen(true)}
              className="px-3 py-2 bg-surface-container hover:bg-surface-container-high text-on-surface border border-surface-container-high font-semibold text-xs rounded-lg flex items-center gap-1.5 transition-all"
            >
              <span className="material-symbols-outlined text-[16px] text-tertiary">psychology</span>
              <span>Gemini Telematics Audit</span>
            </button>
          </div>
        </div>

        {/* Fleet KPI Row */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <div className="p-3.5 bg-surface-container-lowest rounded-xl border border-surface-container-high shadow-sm">
            <span className="text-[11px] font-bold text-on-surface-variant uppercase">Total Fleet</span>
            <div className="mt-1 text-2xl font-black font-mono text-on-surface">{fleetList.length}</div>
            <span className="text-[10px] text-on-surface-variant mt-0.5 block">Monitored Assets</span>
          </div>

          <div className="p-3.5 bg-surface-container-lowest rounded-xl border border-surface-container-high shadow-sm">
            <span className="text-[11px] font-bold text-tertiary uppercase">Active Deployed</span>
            <div className="mt-1 text-2xl font-black font-mono text-tertiary">
              {fleetList.filter((e) => e.status === 'ACTIVE' || e.status === 'ACTIVE_DEPLOYED').length}
            </div>
            <span className="text-[10px] text-tertiary font-mono mt-0.5 block">Operating on Alignment</span>
          </div>

          <div className="p-3.5 bg-surface-container-lowest rounded-xl border border-surface-container-high shadow-sm">
            <span className="text-[11px] font-bold text-primary uppercase">Standby Available</span>
            <div className="mt-1 text-2xl font-black font-mono text-primary">
              {fleetList.filter((e) => e.status === 'STANDBY').length}
            </div>
            <span className="text-[10px] text-on-surface-variant mt-0.5 block">Ready for Mobilization</span>
          </div>

          <div className="p-3.5 bg-surface-container-lowest rounded-xl border border-error/40 shadow-sm">
            <span className="text-[11px] font-bold text-error uppercase">Breakdown / Down</span>
            <div className="mt-1 text-2xl font-black font-mono text-error">
              {fleetList.filter((e) => e.status === 'BREAKDOWN' || e.status === 'MAINTENANCE').length}
            </div>
            <span className="text-[10px] text-error font-mono mt-0.5 block">Impact on Critical Path</span>
          </div>
        </div>

        {/* Filter Pills & Search */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-surface-container-low p-3 rounded-xl border border-surface-container-high">
          <div className="flex bg-surface-container rounded-lg p-0.5 border border-surface-container-high text-xs">
            <button
              onClick={() => setStatusFilter('ALL')}
              className={`px-3 py-1 rounded font-semibold transition-all ${
                statusFilter === 'ALL'
                  ? 'bg-primary text-on-primary shadow-sm'
                  : 'text-on-surface-variant hover:text-on-surface'
              }`}
            >
              All Assets ({fleetList.length})
            </button>
            <button
              onClick={() => setStatusFilter('ACTIVE')}
              className={`px-3 py-1 rounded font-semibold transition-all ${
                statusFilter === 'ACTIVE'
                  ? 'bg-tertiary text-on-tertiary shadow-sm'
                  : 'text-on-surface-variant hover:text-on-surface'
              }`}
            >
              Active
            </button>
            <button
              onClick={() => setStatusFilter('STANDBY')}
              className={`px-3 py-1 rounded font-semibold transition-all ${
                statusFilter === 'STANDBY'
                  ? 'bg-primary text-on-primary shadow-sm'
                  : 'text-on-surface-variant hover:text-on-surface'
              }`}
            >
              Standby
            </button>
            <button
              onClick={() => setStatusFilter('BREAKDOWN')}
              className={`px-3 py-1 rounded font-semibold transition-all ${
                statusFilter === 'BREAKDOWN'
                  ? 'bg-error text-on-error shadow-sm'
                  : 'text-on-surface-variant hover:text-on-surface'
              }`}
            >
              Breakdown ({fleetList.filter((e) => e.status === 'BREAKDOWN' || e.status === 'MAINTENANCE').length})
            </button>
          </div>

          <div className="relative">
            <span className="material-symbols-outlined absolute left-2.5 top-2 text-[14px] text-on-surface-variant">
              search
            </span>
            <input
              type="text"
              placeholder="Search machinery, operator, tag..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-8 pr-3 py-1.5 text-xs bg-surface-container-lowest text-on-surface rounded-lg border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary w-full sm:w-64"
            />
          </div>
        </div>

        {/* Equipment Fleet Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {filteredFleet.map((eq) => {
            const isDown = eq.status === 'BREAKDOWN' || eq.status === 'MAINTENANCE';

            return (
              <div
                key={eq.id}
                className={`p-4 bg-surface-container-lowest rounded-xl border shadow-sm flex flex-col justify-between transition-all hover:border-surface-container-highest ${
                  isDown ? 'border-error/40 bg-error/5' : 'border-surface-container-high'
                }`}
              >
                <div>
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-primary font-bold text-xs">{eq.id}</span>
                        <span className="text-[11px] text-on-surface-variant font-semibold">· {eq.tag}</span>
                      </div>
                      <h3 className="font-bold text-sm text-on-surface mt-0.5">{eq.name}</h3>
                    </div>
                    <span
                      className={`px-2.5 py-0.5 rounded-full font-mono font-bold text-[10px] whitespace-nowrap ${
                        eq.status === 'ACTIVE_DEPLOYED' || eq.status === 'ACTIVE'
                          ? 'bg-tertiary/20 text-tertiary'
                          : eq.status === 'STANDBY'
                          ? 'bg-primary/20 text-primary'
                          : 'bg-error-container text-on-error-container'
                      }`}
                    >
                      {eq.status}
                    </span>
                  </div>

                  <div className="grid grid-cols-3 gap-2 text-xs py-3 my-3 border-y border-surface-container-high/60">
                    <div>
                      <span className="text-[10px] text-on-surface-variant block uppercase font-mono">Operator</span>
                      <span className="font-semibold text-on-surface truncate block">{eq.operator || 'Assigned'}</span>
                    </div>
                    <div>
                      <span className="text-[10px] text-on-surface-variant block uppercase font-mono">Running Hrs</span>
                      <span className="font-mono font-bold text-on-surface">{eq.operatingHours || '1,200 hrs'}</span>
                    </div>
                    <div>
                      <span className="text-[10px] text-on-surface-variant block uppercase font-mono">Fuel Level</span>
                      <span className="font-mono font-bold text-tertiary">
                        {typeof eq.fuelLevel === 'number' ? `${eq.fuelLevel}%` : eq.fuelLevel || '75%'}
                      </span>
                    </div>
                  </div>

                  <div className="flex flex-wrap items-center justify-between text-xs text-on-surface-variant gap-2">
                    <span className="truncate max-w-[200px]">Loc: {eq.location || 'Alignment Corridor'}</span>
                    <span className={`font-mono text-[11px] ${isDown ? 'text-error font-bold' : 'text-on-surface-variant'}`}>
                      {eq.maintenanceDue || 'Routine check OK'}
                    </span>
                  </div>

                  {eq.lastBreakdownReason && (
                    <div className="mt-2.5 p-2 bg-error/10 border border-error/20 rounded-lg text-xs text-error flex items-start gap-1.5">
                      <span className="material-symbols-outlined text-[15px] shrink-0 mt-0.5">error</span>
                      <span>
                        <strong>Reported Stoppage:</strong> {eq.lastBreakdownReason}
                      </span>
                    </div>
                  )}
                </div>

                <div className="mt-4 pt-3 border-t border-surface-container-high flex items-center justify-between">
                  <span className="text-[11px] text-on-surface-variant font-mono">
                    Activity: {eq.associatedAct || 'PIP-L5-024'}
                  </span>
                  <button
                    onClick={() => handleOpenBreakdown(eq.id)}
                    className="px-3 py-1 bg-surface-container hover:bg-surface-container-high text-on-surface text-xs font-semibold rounded-lg flex items-center gap-1 transition-colors"
                  >
                    <span className="material-symbols-outlined text-[14px] text-error">build</span>
                    <span>Log Stoppage</span>
                  </button>
                </div>
              </div>
            );
          })}
        </div>

        {/* Inline Structured Breakdown & Downtime History Log (Right below Grid) */}
        <div className="border border-surface-container-high rounded-xl bg-surface-container-lowest overflow-hidden shadow-sm">
          <div className="p-4 bg-surface-container-low/70 flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-surface-container-high">
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-lg bg-error/10 flex items-center justify-center text-error">
                <span className="material-symbols-outlined text-[18px]">engineering</span>
              </div>
              <div>
                <h3 className="text-sm font-bold text-on-surface flex items-center gap-2">
                  Plant Breakdown & Downtime History Log
                  <span className="px-2 py-0.5 rounded-full bg-error/15 text-error text-[10px] font-mono font-bold">
                    {breakdownHistory.length} Downtime Records
                  </span>
                </h3>
                <p className="text-[11px] text-on-surface-variant">
                  Historical machinery stoppages synchronized with DPR delays and FIDIC Cl. 8.4 claims
                </p>
              </div>
            </div>

            <button
              onClick={() => setIsHistoryExpanded(!isHistoryExpanded)}
              className="px-3 py-1.5 bg-surface-container hover:bg-surface-container-high text-on-surface rounded-lg text-xs font-semibold flex items-center gap-1 transition-colors self-end sm:self-center"
            >
              <span className="material-symbols-outlined text-[16px]">
                {isHistoryExpanded ? 'expand_less' : 'expand_more'}
              </span>
              <span>{isHistoryExpanded ? 'Collapse' : 'Show All'}</span>
            </button>
          </div>

          {isHistoryExpanded && (
            <div className="p-4">
              {breakdownHistory.length === 0 ? (
                <div className="py-8 text-center text-on-surface-variant text-xs">
                  No breakdown incidents recorded for this fleet. All machinery running nominally.
                </div>
              ) : (
                <div className="flex flex-col gap-3">
                  {breakdownHistory.map((item) => (
                    <div
                      key={item.id}
                      className="p-3.5 rounded-lg bg-surface-container-low border border-surface-container-high flex flex-col sm:flex-row sm:items-center justify-between gap-3"
                    >
                      <div className="flex items-start gap-3">
                        <div className="w-8 h-8 rounded-lg bg-error/20 flex items-center justify-center text-error shrink-0 mt-0.5">
                          <span className="material-symbols-outlined text-[18px]">build_circle</span>
                        </div>
                        <div>
                          <div className="flex flex-wrap items-center gap-2">
                            <span className="text-xs font-bold text-on-surface">{item.name}</span>
                            <span className="font-mono text-primary font-bold text-[10px] bg-primary/10 px-2 py-0.5 rounded">
                              {item.id}
                            </span>
                            <span className="px-2 py-0.5 rounded text-[10px] font-mono bg-error/20 text-error font-bold">
                              {item.status}
                            </span>
                          </div>
                          <p className="text-xs text-on-surface-variant mt-1">
                            <strong>Reason:</strong> {item.lastBreakdownReason || 'Hydraulic system failure'}
                          </p>
                          <div className="mt-1.5 flex flex-wrap items-center gap-3 text-[11px] text-on-surface-variant font-mono">
                            <span>Operator: {item.operator || 'Plant Foreman'}</span>
                            <span>•</span>
                            <span>Location: {item.location || 'Alignment'}</span>
                            <span>•</span>
                            <span className="text-error font-bold">
                              Recorded: {item.lastBreakdownAt || 'Today'}
                            </span>
                          </div>
                        </div>
                      </div>

                      <div className="self-end sm:self-center shrink-0 text-right">
                        <span className="text-[10px] font-mono text-on-surface-variant block uppercase">Activity Impact</span>
                        <span className="text-xs font-mono font-bold text-secondary">
                          {item.associatedAct || 'PIP-L5-024'}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>
      </main>

      {/* Report Breakdown Modal */}
      {showBreakdownModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-background/80 backdrop-blur-sm animate-fadeIn">
          <div className="w-full max-w-md bg-surface-container-lowest border border-surface-container-high rounded-xl p-5 shadow-2xl flex flex-col gap-4">
            <div className="flex items-center justify-between border-b border-surface-container-high pb-3">
              <h3 className="font-bold text-sm text-on-surface flex items-center gap-2">
                <span className="material-symbols-outlined text-error text-[18px]">report_problem</span>
                Report Heavy Machinery Stoppage
              </h3>
              <button
                onClick={() => setShowBreakdownModal(false)}
                className="text-on-surface-variant hover:text-on-surface text-sm"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleSubmitBreakdown} className="flex flex-col gap-3 text-xs">
              <div>
                <label className="text-on-surface-variant block mb-1 font-medium">Select Equipment</label>
                <select
                  value={selectedEqId}
                  onChange={(e) => setSelectedEqId(e.target.value)}
                  className="w-full p-2.5 bg-surface-container-low border border-surface-container-high rounded-lg text-on-surface focus:outline-none focus:ring-1 focus:ring-primary"
                >
                  {fleetList.map((eq) => (
                    <option key={eq.id} value={eq.id}>
                      {eq.id} - {eq.name} ({eq.status})
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="text-on-surface-variant block mb-1 font-medium">Breakdown Reason / Cause</label>
                <input
                  type="text"
                  value={breakdownReason}
                  onChange={(e) => setBreakdownReason(e.target.value)}
                  className="w-full p-2.5 bg-surface-container-low border border-surface-container-high rounded-lg text-on-surface focus:outline-none focus:ring-1 focus:ring-primary"
                  placeholder="e.g. Hydraulic failure, Engine overheating"
                  required
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="text-on-surface-variant block mb-1 font-medium">Estimated Downtime (Hours)</label>
                  <input
                    type="number"
                    min="1"
                    max="72"
                    value={downtimeHours}
                    onChange={(e) => setDowntimeHours(Number(e.target.value))}
                    className="w-full p-2.5 bg-surface-container-low border border-surface-container-high rounded-lg text-on-surface focus:outline-none focus:ring-1 focus:ring-primary"
                  />
                </div>
                <div>
                  <label className="text-on-surface-variant block mb-1 font-medium">Reported By</label>
                  <input
                    type="text"
                    value={user.name}
                    readOnly
                    className="w-full p-2.5 bg-surface-container border border-surface-container-high rounded-lg text-on-surface-variant cursor-not-allowed"
                  />
                </div>
              </div>

              <div>
                <label className="text-on-surface-variant block mb-1 font-medium">Mechanic & Action Notes</label>
                <textarea
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  rows={2}
                  className="w-full p-2.5 bg-surface-container-low border border-surface-container-high rounded-lg text-on-surface focus:outline-none focus:ring-1 focus:ring-primary"
                  placeholder="Repair gang dispatched, spares required..."
                />
              </div>

              <div className="flex justify-end gap-2 mt-2 pt-2 border-t border-surface-container-high">
                <button
                  type="button"
                  onClick={() => setShowBreakdownModal(false)}
                  className="px-4 py-2 text-on-surface-variant hover:text-on-surface rounded-lg"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-4 py-2 bg-error text-on-error font-bold rounded-lg shadow-sm hover:brightness-110 flex items-center gap-1.5"
                >
                  {isSubmitting ? (
                    'Recording...'
                  ) : (
                    <>
                      <span className="material-symbols-outlined text-[16px]">save</span>
                      <span>Commit Stoppage to SQLite</span>
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

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
