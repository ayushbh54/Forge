'use client';

import React, { useState } from 'react';
import { ScheduleActivity, DPRRecord } from '../types';
import { useWorkspace } from '../context/WorkspaceContext';

interface InteractiveDprViewProps {
  activities: ScheduleActivity[];
  onSubmitDpr: (activityCode: string, quantity: number, unit: string, delayReason: string, notes: string) => void;
  dprLogs?: DPRRecord[];
}

export const InteractiveDprView: React.FC<InteractiveDprViewProps> = ({
  activities,
  onSubmitDpr,
  dprLogs: propDprLogs,
}) => {
  const workspace = useWorkspace();
  const dprLogs = propDprLogs || workspace.dprLogs || [];

  const [selectedAct, setSelectedAct] = useState(activities[0]?.activityCode || 'PIP-L5-024');
  const [quantity, setQuantity] = useState(45);
  const [unit, setUnit] = useState('meters');
  const [delayReason, setDelayReason] = useState('None');
  const [notes, setNotes] = useState('Completed 6G downhill orbital welding on joints #W24-01 through #W24-06. NDT scheduled for evening shift.');
  const [isSuccess, setIsSuccess] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterDelay, setFilterDelay] = useState<string>('ALL');
  const [isHistoryExpanded, setIsHistoryExpanded] = useState(true);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmitDpr(selectedAct, quantity, unit, delayReason, notes);
    setIsSuccess(true);
    setTimeout(() => setIsSuccess(false), 3000);
  };

  // Filter historical DPR logs
  const filteredLogs = dprLogs.filter(log => {
    const matchesSearch = 
      !searchQuery ||
      (log.activityCode && log.activityCode.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (log.notes && log.notes.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (log.reportedBy && log.reportedBy.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (log.delayReason && log.delayReason.toLowerCase().includes(searchQuery.toLowerCase()));

    const matchesDelay = 
      filterDelay === 'ALL' ||
      (filterDelay === 'WITH_DELAY' && log.delayReason && log.delayReason !== 'None') ||
      (filterDelay === 'ON_TRACK' && (!log.delayReason || log.delayReason === 'None'));

    return matchesSearch && matchesDelay;
  });

  return (
    <div className="flex flex-col gap-6">
      {/* 1. Main Daily Construction Log Form */}
      <div className="bg-surface-container-lowest p-5 sm:p-6 rounded-2xl border border-surface-container-high shadow-sm flex flex-col gap-5">
        {/* Header */}
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-surface-container-high/60 pb-4">
          <div>
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-primary/10 border border-primary/30 flex items-center justify-center text-primary">
                <span className="material-symbols-outlined text-[20px]">history_edu</span>
              </div>
              <h2 className="text-base font-bold text-white tracking-tight">
                Daily Construction Progress Report (DPR)
              </h2>
            </div>
            <p className="text-xs text-on-surface-variant mt-0.5">
              Direct field execution logger synchronized with SQLite & P6 WBS activities
            </p>
          </div>
          <div className="flex items-center gap-2">
            <span className="px-3 py-1 rounded-full bg-tertiary/15 text-tertiary border border-tertiary/30 text-xs font-mono font-bold flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-tertiary animate-pulse" />
              Day Shift (07:00 – 17:30)
            </span>
            <span className="px-3 py-1 rounded-full bg-surface-container text-on-surface-variant text-xs font-mono">
              28°C / Dry Weather
            </span>
          </div>
        </div>

        {isSuccess && (
          <div className="p-3.5 bg-tertiary/10 border border-tertiary/40 rounded-xl text-tertiary text-xs flex items-center gap-2.5 animate-fade-in">
            <span className="material-symbols-outlined text-[20px]">verified</span>
            <span className="font-semibold">
              Daily Progress Report successfully recorded, timestamped, and appended to persistent history!
            </span>
          </div>
        )}

        {/* DPR Submission Form */}
        <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-5">
          {/* Left Column */}
          <div className="flex flex-col gap-3.5">
            <div>
              <label className="text-xs font-bold text-on-surface-variant uppercase tracking-wider block mb-1.5">
                Select Schedule Activity (P6 L5/L6)
              </label>
              <select
                value={selectedAct}
                onChange={(e) => setSelectedAct(e.target.value)}
                className="w-full p-3 bg-surface-container-low text-on-surface text-xs rounded-xl border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary font-medium"
              >
                {activities.map((a) => (
                  <option key={a.id} value={a.activityCode} className="bg-surface-container">
                    [{a.activityCode}] {a.name}
                  </option>
                ))}
              </select>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-bold text-on-surface-variant uppercase tracking-wider block mb-1.5">
                  Installed Today
                </label>
                <input
                  type="number"
                  value={quantity}
                  onChange={(e) => setQuantity(Number(e.target.value))}
                  className="w-full p-3 bg-surface-container-low text-white text-xs font-mono font-bold rounded-xl border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary"
                />
              </div>
              <div>
                <label className="text-xs font-bold text-on-surface-variant uppercase tracking-wider block mb-1.5">
                  Unit of Measure
                </label>
                <input
                  type="text"
                  value={unit}
                  onChange={(e) => setUnit(e.target.value)}
                  className="w-full p-3 bg-surface-container-low text-on-surface text-xs font-mono rounded-xl border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary"
                />
              </div>
            </div>

            <div>
              <label className="text-xs font-bold text-on-surface-variant uppercase tracking-wider block mb-1.5">
                Delay Reason (If Any)
              </label>
              <select
                value={delayReason}
                onChange={(e) => setDelayReason(e.target.value)}
                className="w-full p-3 bg-surface-container-low text-on-surface text-xs rounded-xl border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary font-medium"
              >
                <option value="None">None (Work Proceeding as Scheduled)</option>
                <option value="Material Spool Delay">Material Spool Delay from Store B</option>
                <option value="Equipment Downtime">Equipment Downtime (Crane / Generator)</option>
                <option value="Inclement Weather">Inclement Weather / Heavy Rain</option>
                <option value="Workforce / Gang Shortage">Workforce / Gang Shortage</option>
                <option value="Engineering RFI Pending">Engineering RFI Clarification Pending</option>
              </select>
            </div>
          </div>

          {/* Right Column */}
          <div className="flex flex-col gap-3.5">
            <div>
              <label className="text-xs font-bold text-on-surface-variant uppercase tracking-wider block mb-1.5">
                Shift Diary & Detailed Progress Notes
              </label>
              <textarea
                rows={4}
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                className="w-full p-3 bg-surface-container-low text-on-surface text-xs rounded-xl border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary resize-none leading-relaxed"
                placeholder="Enter field supervisor observations, crew details, joint numbers..."
              />
            </div>

            {/* Photo & GPS Geo-Tag Preview */}
            <div className="p-3 bg-surface-container-low rounded-xl border border-dashed border-surface-container-high flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <span className="material-symbols-outlined text-primary text-[22px]">add_a_photo</span>
                <div className="flex flex-col">
                  <span className="text-xs font-semibold text-white">Site Photo #IMG-2026-0929-01.jpg</span>
                  <span className="text-[10px] text-tertiary font-mono">Geo: 27.3512° N, 95.3124° E (Assam Trench)</span>
                </div>
              </div>
              <span className="px-2 py-0.5 rounded bg-tertiary/20 text-tertiary text-[10px] font-mono font-bold">
                GPS Verified
              </span>
            </div>

            <div className="flex justify-end gap-2 mt-auto">
              <button
                type="submit"
                className="h-11 px-6 bg-primary-container hover:bg-blue-600 text-white font-bold text-xs rounded-xl flex items-center gap-2 transition-all shadow-lg shadow-primary-container/20 active:scale-95"
              >
                <span className="material-symbols-outlined text-[18px]">publish</span>
                <span>Submit & Append to History</span>
              </button>
            </div>
          </div>
        </form>
      </div>

      {/* 2. INLINE STRUCTURED HISTORY SECTION (Always visible, tap-to-toggle option) */}
      <div className="bg-surface-container-lowest p-5 sm:p-6 rounded-2xl border border-surface-container-high shadow-sm flex flex-col gap-4">
        {/* History Header Strip */}
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-surface-container-high/60 pb-3">
          <div className="flex items-center gap-2.5">
            <span className="material-symbols-outlined text-primary text-[22px]">manage_history</span>
            <div>
              <h3 className="text-sm font-bold text-white uppercase tracking-wider flex items-center gap-2">
                <span>DPR Submission History</span>
                <span className="px-2 py-0.5 rounded-full bg-primary/20 text-primary text-[10px] font-mono font-bold">
                  {filteredLogs.length} Records
                </span>
              </h3>
              <p className="text-xs text-on-surface-variant">
                Live, structured, chronological audit log of all shift progress entries stored in SQLite
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setIsHistoryExpanded(!isHistoryExpanded)}
              className="px-3 py-1.5 rounded-lg bg-surface-container hover:bg-surface-container-high text-xs font-semibold text-on-surface flex items-center gap-1.5 transition-colors border border-surface-container-high"
            >
              <span className="material-symbols-outlined text-[16px]">
                {isHistoryExpanded ? 'unfold_less' : 'unfold_more'}
              </span>
              <span>{isHistoryExpanded ? 'Collapse History' : 'Expand History'}</span>
            </button>
          </div>
        </div>

        {isHistoryExpanded && (
          <div className="flex flex-col gap-4 animate-fade-in">
            {/* Search & Filter Toolbar */}
            <div className="flex flex-col sm:flex-row items-center justify-between gap-3 bg-surface-container-low p-3 rounded-xl border border-surface-container-high">
              <div className="relative w-full sm:w-72">
                <span className="material-symbols-outlined absolute left-3 top-2.5 text-on-surface-variant text-[18px]">
                  search
                </span>
                <input
                  type="text"
                  placeholder="Search logs by activity, note..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-9 pr-3 py-1.5 bg-surface-container text-white text-xs rounded-lg border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary placeholder:text-on-surface-variant/60"
                />
              </div>

              {/* Filter Pills */}
              <div className="flex items-center gap-1.5 w-full sm:w-auto overflow-x-auto text-xs">
                <button
                  onClick={() => setFilterDelay('ALL')}
                  className={`px-3 py-1 rounded-md font-semibold transition-colors whitespace-nowrap ${
                    filterDelay === 'ALL'
                      ? 'bg-primary-container text-white font-bold'
                      : 'bg-surface-container text-on-surface-variant hover:text-white'
                  }`}
                >
                  All ({dprLogs.length})
                </button>
                <button
                  onClick={() => setFilterDelay('ON_TRACK')}
                  className={`px-3 py-1 rounded-md font-semibold transition-colors whitespace-nowrap ${
                    filterDelay === 'ON_TRACK'
                      ? 'bg-tertiary-container text-tertiary font-bold'
                      : 'bg-surface-container text-on-surface-variant hover:text-white'
                  }`}
                >
                  Nominal (No Delay)
                </button>
                <button
                  onClick={() => setFilterDelay('WITH_DELAY')}
                  className={`px-3 py-1 rounded-md font-semibold transition-colors whitespace-nowrap ${
                    filterDelay === 'WITH_DELAY'
                      ? 'bg-secondary/30 text-secondary font-bold'
                      : 'bg-surface-container text-on-surface-variant hover:text-white'
                  }`}
                >
                  With Delays
                </button>
              </div>
            </div>

            {/* History Records Cards */}
            {filteredLogs.length === 0 ? (
              <div className="py-12 text-center flex flex-col items-center justify-center gap-2 bg-surface-container-low/50 rounded-xl border border-surface-container-high border-dashed">
                <span className="material-symbols-outlined text-[36px] text-on-surface-variant">
                  history_toggle_off
                </span>
                <p className="text-xs font-semibold text-on-surface">No DPR history matches your filter</p>
                <span className="text-[11px] text-on-surface-variant">Submit a new progress entry above to generate live records.</span>
              </div>
            ) : (
              <div className="flex flex-col gap-3">
                {filteredLogs.map((log) => {
                  const hasDelay = log.delayReason && log.delayReason !== 'None';
                  const matchedAct = activities.find(a => a.activityCode === log.activityCode);

                  return (
                    <div
                      key={log.id}
                      className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high/80 hover:border-primary/40 transition-all flex flex-col gap-2.5 shadow-sm"
                    >
                      {/* Top Bar: Date, Shift, Activity Code, Status */}
                      <div className="flex flex-wrap items-center justify-between gap-2">
                        <div className="flex items-center gap-2">
                          <span className="px-2.5 py-0.5 rounded-md bg-surface-container text-white font-mono text-[11px] font-bold border border-surface-container-high">
                            {log.reportDate || 'Today'}
                          </span>
                          <span className="px-2 py-0.5 rounded bg-primary/20 text-primary font-mono text-[10px] font-bold">
                            {log.activityCode || 'GENERAL'}
                          </span>
                          <span className="text-xs font-bold text-white">
                            {matchedAct?.name || 'Site Operation'}
                          </span>
                        </div>

                        <div className="flex items-center gap-2">
                          {hasDelay ? (
                            <span className="px-2.5 py-0.5 rounded-full bg-secondary/20 text-secondary border border-secondary/30 text-[10px] font-bold font-mono flex items-center gap-1">
                              <span className="material-symbols-outlined text-[12px]">warning</span>
                              <span>Delay: {log.delayReason}</span>
                            </span>
                          ) : (
                            <span className="px-2.5 py-0.5 rounded-full bg-tertiary/20 text-tertiary border border-tertiary/30 text-[10px] font-bold font-mono flex items-center gap-1">
                              <span className="material-symbols-outlined text-[12px]">check_circle</span>
                              <span>Nominal Execution</span>
                            </span>
                          )}
                          <span className="text-[10px] text-tertiary font-mono bg-surface-container px-2 py-0.5 rounded border border-surface-container-high">
                            VERIFIED & LINKED
                          </span>
                        </div>
                      </div>

                      {/* Middle: Installed Quantity & Notes */}
                      <div className="flex flex-col sm:flex-row sm:items-baseline justify-between gap-2 pt-1 border-t border-surface-container-high/40">
                        <div className="flex items-baseline gap-2">
                          <span className="text-xs font-semibold text-on-surface-variant">Quantity Installed:</span>
                          <span className="text-base font-black font-mono text-tertiary">
                            +{log.completedQuantity} {log.unit || 'units'}
                          </span>
                        </div>

                        <div className="text-[11px] text-on-surface-variant flex items-center gap-1 font-mono">
                          <span className="material-symbols-outlined text-[14px] text-tertiary">pin_drop</span>
                          <span>Reported by: <strong className="text-white">{log.reportedBy || 'Supervisor'}</strong> ({log.supervisorRole || 'Site In-Charge'})</span>
                        </div>
                      </div>

                      {/* Shift Notes */}
                      {log.notes && (
                        <div className="p-2.5 rounded-lg bg-surface-container/60 border border-surface-container-high/60 text-xs text-on-surface-variant leading-relaxed">
                          "{log.notes}"
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

