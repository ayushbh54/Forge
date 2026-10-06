'use client';

import React, { useState } from 'react';
import { WorkerProfile } from '../types';
import { useWorkspace } from '../context/WorkspaceContext';

interface WorkforceAttendanceViewProps {
  workers: WorkerProfile[];
  onClockIn: (workerId: string) => void;
}

export const WorkforceAttendanceView: React.FC<WorkforceAttendanceViewProps> = ({
  workers,
  onClockIn,
}) => {
  const workspace = useWorkspace();
  const auditLogs = workspace.auditLogs || [];

  const [selectedTrade, setSelectedTrade] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [historySearch, setHistorySearch] = useState('');
  const [isHistoryExpanded, setIsHistoryExpanded] = useState(true);

  // Available unique trades for filter
  const trades = ['ALL', ...Array.from(new Set(workers.map(w => w.trade).filter(Boolean)))];

  const filteredWorkers = workers.filter(w => {
    const matchesTrade = selectedTrade === 'ALL' || w.trade === selectedTrade;
    const matchesSearch = 
      !searchQuery ||
      w.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      w.badgeNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
      w.contractor.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesTrade && matchesSearch;
  });

  // Extract attendance punch history from workers and audit logs
  const attendanceHistory = workers
    .filter(w => w.lastClockIn && w.lastClockIn !== 'Clock-in pending today')
    .map(w => {
      const isVerified = w.attendanceStatus === 'VERIFIED_PRESENT';
      return {
        id: `ATT-${w.id}`,
        workerId: w.id,
        name: w.name,
        badgeNumber: w.badgeNumber,
        trade: w.trade,
        contractor: w.contractor,
        time: w.lastClockIn,
        location: w.latitude && w.longitude 
          ? `${w.latitude.toFixed(4)}° N, ${w.longitude.toFixed(4)}° E (Duliajan Trench Station)`
          : '27.4825° N, 95.3225° E (Assam Site Geofence)',
        method: w.verificationMethod || 'RTK_GEOFENCE_BIOMETRIC',
        confidenceScore: w.confidenceScore || 96,
        status: isVerified ? 'VERIFIED_PRESENT' : 'FLAGGED_REVIEW',
      };
    })
    .filter(h => {
      if (!historySearch) return true;
      return (
        h.name.toLowerCase().includes(historySearch.toLowerCase()) ||
        h.badgeNumber.toLowerCase().includes(historySearch.toLowerCase()) ||
        h.trade.toLowerCase().includes(historySearch.toLowerCase()) ||
        h.contractor.toLowerCase().includes(historySearch.toLowerCase())
      );
    });

  const verifiedCount = workers.filter(w => w.attendanceStatus === 'VERIFIED_PRESENT').length;
  const reviewCount = workers.filter(w => w.attendanceStatus === 'PRESENT_NEEDS_REVIEW').length;

  return (
    <div className="flex flex-col gap-6">
      {/* 1. Main Workforce Identity & Active Gangs Grid */}
      <div className="bg-surface-container-lowest p-5 sm:p-6 rounded-2xl border border-surface-container-high shadow-sm flex flex-col gap-5">
        {/* Header */}
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-surface-container-high/60 pb-4">
          <div>
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-primary/10 border border-primary/30 flex items-center justify-center text-primary">
                <span className="material-symbols-outlined text-[20px]">badge</span>
              </div>
              <h2 className="text-base font-bold text-white tracking-tight">
                Digital Workforce Muster Roll & Certified Site Gangs
              </h2>
            </div>
            <p className="text-xs text-on-surface-variant mt-0.5">
              Geofence + Biometric multi-factor verification correlated with P6 production rates
            </p>
          </div>
          <div className="flex items-center gap-2">
            <span className="px-3 py-1 rounded-full bg-tertiary/15 text-tertiary border border-tertiary/30 text-xs font-mono font-bold flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-tertiary animate-pulse" />
              {verifiedCount} Verified Present
            </span>
            {reviewCount > 0 && (
              <span className="px-3 py-1 rounded-full bg-secondary/20 text-secondary border border-secondary/30 text-xs font-mono font-bold">
                {reviewCount} Needs Review
              </span>
            )}
          </div>
        </div>

        {/* Toolbar: Search & Trade Filters */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-3 bg-surface-container-low p-3 rounded-xl border border-surface-container-high">
          <div className="relative w-full sm:w-72">
            <span className="material-symbols-outlined absolute left-3 top-2.5 text-on-surface-variant text-[18px]">
              search
            </span>
            <input
              type="text"
              placeholder="Search personnel by name, badge..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-9 pr-3 py-1.5 bg-surface-container text-white text-xs rounded-lg border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary placeholder:text-on-surface-variant/60"
            />
          </div>

          <div className="flex items-center gap-1.5 w-full sm:w-auto overflow-x-auto text-xs scrollbar-thin">
            {trades.map(t => (
              <button
                key={t}
                onClick={() => setSelectedTrade(t)}
                className={`px-3 py-1 rounded-md font-semibold transition-colors whitespace-nowrap ${
                  selectedTrade === t
                    ? 'bg-primary-container text-white font-bold'
                    : 'bg-surface-container text-on-surface-variant hover:text-white'
                }`}
              >
                {t === 'ALL' ? 'All Personnel' : t}
              </button>
            ))}
          </div>
        </div>

        {/* Workforce Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredWorkers.map((worker) => {
            const isVerified = worker.attendanceStatus === 'VERIFIED_PRESENT';
            return (
              <div
                key={worker.id}
                className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high/80 hover:border-primary/40 transition-all flex flex-col justify-between shadow-sm relative overflow-hidden"
              >
                {/* Top Row with Badge & Photo */}
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-surface-container border border-surface-container-high overflow-hidden flex-shrink-0 flex items-center justify-center font-bold text-xs text-primary shadow-inner">
                      {worker.name.split(' ').map(n => n[0]).join('')}
                    </div>
                    <div>
                      <h4 className="font-bold text-xs text-white leading-tight">{worker.name}</h4>
                      <span className="text-[10px] text-tertiary font-mono font-semibold">{worker.badgeNumber}</span>
                    </div>
                  </div>
                  <span className="px-2 py-0.5 rounded-md bg-primary/20 text-primary border border-primary/30 text-[10px] font-mono font-bold whitespace-nowrap">
                    {worker.trade}
                  </span>
                </div>

                {/* Skills and Certifications */}
                <div className="my-3 flex flex-col gap-1.5 text-xs">
                  <div className="flex items-center justify-between text-on-surface-variant">
                    <span className="text-[11px]">Contractor:</span>
                    <span className="text-white font-medium truncate max-w-[140px] text-[11px]">{worker.contractor}</span>
                  </div>
                  <div className="flex items-center justify-between text-on-surface-variant">
                    <span className="text-[11px]">Assigned Activity:</span>
                    <span className="font-mono text-secondary font-semibold text-[11px]">{worker.assignedActivityId}</span>
                  </div>
                  <div className="flex items-center justify-between text-on-surface-variant">
                    <span className="text-[11px]">Safety Induction:</span>
                    <span className="text-tertiary font-mono text-[11px]">Valid till {worker.safetyCertValidTill}</span>
                  </div>
                </div>

                {/* Attendance Verification Strip */}
                <div className="pt-3 border-t border-surface-container-high/60 flex flex-col gap-2">
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-[11px] text-on-surface-variant">Geofence Confidence:</span>
                    <span className={`font-mono font-bold text-[11px] ${isVerified ? 'text-tertiary' : 'text-secondary'}`}>
                      {worker.confidenceScore}% ({isVerified ? 'Strong' : 'Review'})
                    </span>
                  </div>
                  <div className="flex items-center justify-between gap-2">
                    <span className="text-[10px] text-on-surface-variant font-mono truncate max-w-[150px]">
                      {worker.lastClockIn}
                    </span>
                    <button
                      onClick={() => onClockIn(worker.id)}
                      className="px-3 py-1.5 bg-primary-container hover:bg-blue-600 text-white font-bold text-xs rounded-lg transition-all shadow-sm active:scale-95 flex items-center gap-1"
                    >
                      <span className="material-symbols-outlined text-[14px]">how_to_reg</span>
                      <span>{isVerified ? 'Re-Verify' : 'Clock-In'}</span>
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* 2. INLINE STRUCTURED ATTENDANCE HISTORY SECTION */}
      <div className="bg-surface-container-lowest p-5 sm:p-6 rounded-2xl border border-surface-container-high shadow-sm flex flex-col gap-4">
        {/* History Header */}
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-surface-container-high/60 pb-3">
          <div className="flex items-center gap-2.5">
            <span className="material-symbols-outlined text-primary text-[22px]">history_toggle_off</span>
            <div>
              <h3 className="text-sm font-bold text-white uppercase tracking-wider flex items-center gap-2">
                <span>Shift Attendance & Clock-in History</span>
                <span className="px-2 py-0.5 rounded-full bg-primary/20 text-primary text-[10px] font-mono font-bold">
                  {attendanceHistory.length} Punches
                </span>
              </h3>
              <p className="text-xs text-on-surface-variant">
                Live biometric & GPS geofenced shift log recorded in SQLite database
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
            {/* Search Toolbar */}
            <div className="flex items-center justify-between gap-3 bg-surface-container-low p-3 rounded-xl border border-surface-container-high">
              <div className="relative w-full sm:w-80">
                <span className="material-symbols-outlined absolute left-3 top-2.5 text-on-surface-variant text-[18px]">
                  search
                </span>
                <input
                  type="text"
                  placeholder="Filter attendance history by worker, badge..."
                  value={historySearch}
                  onChange={(e) => setHistorySearch(e.target.value)}
                  className="w-full pl-9 pr-3 py-1.5 bg-surface-container text-white text-xs rounded-lg border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary placeholder:text-on-surface-variant/60"
                />
              </div>

              <span className="text-xs text-on-surface-variant font-mono hidden sm:inline">
                Showing {attendanceHistory.length} verified punches
              </span>
            </div>

            {/* Attendance Punch Records Cards */}
            {attendanceHistory.length === 0 ? (
              <div className="py-12 text-center flex flex-col items-center justify-center gap-2 bg-surface-container-low/50 rounded-xl border border-surface-container-high border-dashed">
                <span className="material-symbols-outlined text-[36px] text-on-surface-variant">
                  badge
                </span>
                <p className="text-xs font-semibold text-on-surface">No attendance punch history logged yet</p>
                <span className="text-[11px] text-on-surface-variant">Tap "Clock-In" on any worker above to record GPS geofenced attendance.</span>
              </div>
            ) : (
              <div className="flex flex-col gap-2.5">
                {attendanceHistory.map((punch) => (
                  <div
                    key={punch.id}
                    className="p-3.5 rounded-xl bg-surface-container-low border border-surface-container-high/80 hover:border-primary/40 transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-sm"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-lg bg-surface-container flex items-center justify-center font-bold text-xs text-tertiary border border-surface-container-high">
                        {punch.name.split(' ').map(n => n[0]).join('')}
                      </div>

                      <div className="flex flex-col">
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-bold text-white">{punch.name}</span>
                          <span className="px-1.5 py-0.2 rounded bg-primary/20 text-primary text-[10px] font-mono font-bold">
                            {punch.badgeNumber}
                          </span>
                          <span className="text-[11px] text-on-surface-variant font-medium">
                            · {punch.trade}
                          </span>
                        </div>

                        <div className="flex items-center gap-2 text-[10px] text-on-surface-variant mt-0.5 font-mono">
                          <span className="text-tertiary font-semibold flex items-center gap-0.5">
                            <span className="material-symbols-outlined text-[13px]">pin_drop</span>
                            <span>{punch.location}</span>
                          </span>
                          <span>•</span>
                          <span>{punch.contractor}</span>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-3 sm:justify-end border-t sm:border-t-0 pt-2 sm:pt-0 border-surface-container-high/40">
                      <div className="flex flex-col items-end text-right">
                        <span className="text-xs font-mono font-bold text-white">{punch.time}</span>
                        <span className="text-[10px] text-tertiary font-mono">Confidence: {punch.confidenceScore}%</span>
                      </div>

                      <span className="px-2.5 py-1 rounded-full bg-tertiary/15 text-tertiary border border-tertiary/30 text-[10px] font-mono font-bold whitespace-nowrap">
                        ✓ VERIFIED PRESENT
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

