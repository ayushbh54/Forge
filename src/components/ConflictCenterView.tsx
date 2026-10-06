'use client';

import React, { useState } from 'react';
import { ConflictItem } from '../types';

interface ConflictCenterViewProps {
  conflicts: ConflictItem[];
  onResolve: (conflictId: string, notes: string) => void;
  onInvestigate: (activityCode: string) => void;
}

export const ConflictCenterView: React.FC<ConflictCenterViewProps> = ({
  conflicts,
  onResolve,
  onInvestigate,
}) => {
  const [resolvingId, setResolvingId] = useState<string | null>(null);
  const [resolutionNote, setResolutionNote] = useState('');
  const [severityFilter, setSeverityFilter] = useState<'ALL' | 'CRITICAL' | 'WARNING'>('ALL');
  const [historySearch, setHistorySearch] = useState('');
  const [isHistoryExpanded, setIsHistoryExpanded] = useState(true);

  const activeConflicts = conflicts.filter((c) => c.status !== 'RESOLVED');
  const resolvedConflicts = conflicts.filter((c) => c.status === 'RESOLVED');

  const filteredActive = activeConflicts.filter((c) => {
    if (severityFilter === 'ALL') return true;
    if (severityFilter === 'CRITICAL') return c.severity === 'CRITICAL';
    if (severityFilter === 'WARNING') return c.severity === 'HIGH' || c.severity === 'MEDIUM';
    return true;
  });

  const filteredHistory = resolvedConflicts.filter((c) => {
    if (!historySearch.trim()) return true;
    const q = historySearch.toLowerCase();
    return (
      c.title.toLowerCase().includes(q) ||
      c.activityCode.toLowerCase().includes(q) ||
      c.description.toLowerCase().includes(q) ||
      (c.specOrClause && c.specOrClause.toLowerCase().includes(q))
    );
  });

  const handleConfirmResolve = (id: string) => {
    onResolve(id, resolutionNote || 'Reconciled during joint field walk with Engineer Representative.');
    setResolvingId(null);
    setResolutionNote('');
  };

  return (
    <div className="flex flex-col gap-6">
      {/* Top Bar with Metrics & Filters */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-3 bg-surface-container-low p-4 rounded-xl border border-surface-container-high">
        <div>
          <h2 className="text-base font-bold text-on-surface flex items-center gap-2">
            <span className="material-symbols-outlined text-error text-[20px]">warning</span>
            Active Discrepancies & Silent Risks
          </h2>
          <p className="text-xs text-on-surface-variant">
            Triangulated against Primavera P6 baseline, LiDAR scans, and QA lab test reports
          </p>
        </div>

        <div className="flex items-center gap-2">
          {/* Severity Pills */}
          <div className="flex bg-surface-container p-1 rounded-lg border border-surface-container-high text-xs">
            <button
              onClick={() => setSeverityFilter('ALL')}
              className={`px-3 py-1 rounded font-medium transition-all ${
                severityFilter === 'ALL'
                  ? 'bg-primary text-on-primary shadow-sm font-bold'
                  : 'text-on-surface-variant hover:text-on-surface'
              }`}
            >
              All ({activeConflicts.length})
            </button>
            <button
              onClick={() => setSeverityFilter('CRITICAL')}
              className={`px-3 py-1 rounded font-medium transition-all ${
                severityFilter === 'CRITICAL'
                  ? 'bg-error text-on-error shadow-sm font-bold'
                  : 'text-on-surface-variant hover:text-on-surface'
              }`}
            >
              Critical ({activeConflicts.filter((c) => c.severity === 'CRITICAL').length})
            </button>
            <button
              onClick={() => setSeverityFilter('WARNING')}
              className={`px-3 py-1 rounded font-medium transition-all ${
                severityFilter === 'WARNING'
                  ? 'bg-secondary text-on-secondary shadow-sm font-bold'
                  : 'text-on-surface-variant hover:text-on-surface'
              }`}
            >
              Warnings ({activeConflicts.filter((c) => c.severity !== 'CRITICAL').length})
            </button>
          </div>
        </div>
      </div>

      {/* Active Conflicts Grid */}
      {filteredActive.length === 0 ? (
        <div className="p-8 text-center bg-surface-container-low rounded-xl border border-surface-container-high flex flex-col items-center gap-2">
          <span className="material-symbols-outlined text-tertiary text-[40px]">check_circle</span>
          <p className="text-sm font-bold text-on-surface">No Active Conflicts in this Filter</p>
          <p className="text-xs text-on-surface-variant">
            All physical measurements and field reports are currently within contract tolerances.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {filteredActive.map((conf) => {
            const isCritical = conf.severity === 'CRITICAL';

            return (
              <div
                key={conf.id}
                className="p-4 rounded-xl border border-surface-container-high bg-surface-container-lowest relative overflow-hidden flex flex-col justify-between shadow-sm hover:border-surface-container-highest transition-all"
              >
                {/* Left Accent Stripe */}
                <div
                  className={`absolute left-0 top-0 bottom-0 w-1.5 ${
                    isCritical ? 'bg-error' : 'bg-secondary'
                  }`}
                />

                <div className="pl-2">
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex items-center gap-2">
                      <span
                        className={`material-symbols-outlined text-[20px] ${
                          isCritical ? 'text-error' : 'text-secondary'
                        }`}
                      >
                        {isCritical ? 'difference' : 'warning'}
                      </span>
                      <h3 className="font-semibold text-sm text-on-surface leading-snug">
                        {conf.title}
                      </h3>
                    </div>
                    <span
                      className={`px-2.5 py-0.5 rounded-full font-mono text-[10px] font-bold whitespace-nowrap ${
                        isCritical
                          ? 'bg-error-container text-on-error-container'
                          : 'bg-secondary/20 text-secondary'
                      }`}
                    >
                      {conf.varianceValue || conf.severity}
                    </span>
                  </div>

                  <p className="text-xs text-on-surface mt-2 leading-relaxed">
                    {conf.description}
                  </p>

                  <div className="mt-3 flex flex-wrap items-center gap-2 text-[11px] text-on-surface-variant font-mono">
                    <span className="bg-surface-container px-2 py-0.5 rounded">Act: {conf.activityCode}</span>
                    <span>•</span>
                    <span>{conf.specOrClause}</span>
                    <span>•</span>
                    <span>{conf.timestamp}</span>
                  </div>
                </div>

                {/* Actions */}
                <div className="mt-4 pl-2 pt-3 border-t border-surface-container-high/60 flex flex-wrap items-center justify-between gap-2">
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => onInvestigate(conf.activityCode)}
                      className="h-8 px-3 bg-surface-container hover:bg-surface-container-high text-on-surface rounded-lg text-xs font-medium flex items-center gap-1.5 transition-colors"
                    >
                      <span className="material-symbols-outlined text-[16px]">account_tree</span>
                      <span>Investigate</span>
                    </button>
                    <button
                      onClick={() => setResolvingId(conf.id)}
                      className="h-8 px-3 bg-primary text-on-primary hover:bg-primary/90 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors shadow-sm"
                    >
                      <span className="material-symbols-outlined text-[16px]">done_all</span>
                      <span>Resolve Conflict</span>
                    </button>
                  </div>
                  {conf.claimedValue && (
                    <span className="text-[11px] text-on-surface-variant font-mono bg-surface-container-low px-2 py-1 rounded">
                      Claimed: {conf.claimedValue} vs Verified: {conf.verifiedValue}
                    </span>
                  )}
                </div>

                {/* Quick Resolve Input Drawer */}
                {resolvingId === conf.id && (
                  <div className="mt-3 p-3.5 bg-surface-container rounded-lg border border-surface-container-high flex flex-col gap-2.5 animate-fadeIn">
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold text-on-surface">Enter Resolution Rationale (FIDIC Audit Trail):</span>
                      <button onClick={() => setResolvingId(null)} className="text-on-surface-variant hover:text-on-surface text-xs">
                        ✕
                      </button>
                    </div>
                    <input
                      type="text"
                      value={resolutionNote}
                      onChange={(e) => setResolutionNote(e.target.value)}
                      placeholder="e.g. Joint walk confirmed 304m lower-in. Rebar NDT clearance received."
                      className="p-2 text-xs bg-surface-container-lowest text-on-surface rounded-md border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary"
                    />
                    <div className="flex justify-end gap-2">
                      <button
                        onClick={() => setResolvingId(null)}
                        className="px-3 py-1.5 text-xs text-on-surface-variant hover:text-on-surface rounded"
                      >
                        Cancel
                      </button>
                      <button
                        onClick={() => handleConfirmResolve(conf.id)}
                        className="px-4 py-1.5 bg-tertiary text-on-tertiary font-bold text-xs rounded-md shadow-sm hover:brightness-110"
                      >
                        Confirm Resolution
                      </button>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* Structured Resolution History Section (Right Below Active Conflicts) */}
      <div className="mt-4 border border-surface-container-high rounded-xl bg-surface-container-low overflow-hidden">
        <div className="p-4 bg-surface-container/60 flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-surface-container-high">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-tertiary/20 flex items-center justify-center text-tertiary">
              <span className="material-symbols-outlined text-[18px]">history</span>
            </div>
            <div>
              <h3 className="text-sm font-bold text-on-surface flex items-center gap-2">
                Conflict Resolution & Closed Issues History
                <span className="px-2 py-0.5 rounded-full bg-tertiary/20 text-tertiary text-[10px] font-mono font-bold">
                  {resolvedConflicts.length} Resolved
                </span>
              </h3>
              <p className="text-[11px] text-on-surface-variant">
                Permanent immutable FIDIC ledger of reconciled variances and signed off exceptions
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <div className="relative">
              <span className="material-symbols-outlined absolute left-2.5 top-2 text-[14px] text-on-surface-variant">
                search
              </span>
              <input
                type="text"
                placeholder="Search resolved history..."
                value={historySearch}
                onChange={(e) => setHistorySearch(e.target.value)}
                className="pl-8 pr-3 py-1.5 text-xs bg-surface-container-lowest text-on-surface rounded-lg border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary w-48 sm:w-64"
              />
            </div>
            <button
              onClick={() => setIsHistoryExpanded(!isHistoryExpanded)}
              className="px-3 py-1.5 bg-surface-container hover:bg-surface-container-high text-on-surface rounded-lg text-xs font-semibold flex items-center gap-1 transition-colors"
            >
              <span className="material-symbols-outlined text-[16px]">
                {isHistoryExpanded ? 'expand_less' : 'expand_more'}
              </span>
              <span>{isHistoryExpanded ? 'Collapse' : 'Show All'}</span>
            </button>
          </div>
        </div>

        {isHistoryExpanded && (
          <div className="p-4">
            {filteredHistory.length === 0 ? (
              <div className="py-8 text-center text-on-surface-variant text-xs">
                {historySearch ? 'No resolved conflicts match your search query.' : 'No conflicts have been marked as resolved yet.'}
              </div>
            ) : (
              <div className="flex flex-col gap-3">
                {filteredHistory.map((item) => (
                  <div
                    key={item.id}
                    className="p-3.5 rounded-lg bg-surface-container-lowest border border-surface-container-high flex flex-col md:flex-row md:items-center justify-between gap-3 hover:border-tertiary/40 transition-all"
                  >
                    <div className="flex items-start gap-3">
                      <div className="w-7 h-7 rounded-full bg-tertiary/20 flex items-center justify-center text-tertiary shrink-0 mt-0.5">
                        <span className="material-symbols-outlined text-[16px]">check</span>
                      </div>
                      <div>
                        <div className="flex flex-wrap items-center gap-2">
                          <span className="text-xs font-bold text-on-surface">{item.title}</span>
                          <span className="px-2 py-0.5 rounded text-[10px] font-mono bg-tertiary/20 text-tertiary font-bold">
                            RESOLVED
                          </span>
                          <span className="text-[10px] font-mono bg-surface-container px-2 py-0.5 rounded text-on-surface-variant">
                            Act: {item.activityCode}
                          </span>
                        </div>
                        <p className="text-xs text-on-surface-variant mt-1 leading-relaxed">
                          {item.description}
                        </p>
                        <div className="mt-2 flex flex-wrap items-center gap-3 text-[11px] text-tertiary font-mono">
                          <span className="flex items-center gap-1">
                            <span className="material-symbols-outlined text-[13px]">verified</span>
                            <span>{item.specOrClause || 'FIDIC Cl. 8.4'}</span>
                          </span>
                          {item.claimedValue && (
                            <span className="text-on-surface-variant">
                              Variance settled: {item.claimedValue} ➔ {item.verifiedValue}
                            </span>
                          )}
                          <span className="text-on-surface-variant/80">
                            Reconciled: {item.timestamp}
                          </span>
                        </div>
                      </div>
                    </div>

                    <button
                      onClick={() => onInvestigate(item.activityCode)}
                      className="self-end md:self-center px-3 py-1.5 bg-surface-container hover:bg-surface-container-high text-on-surface rounded text-xs font-medium flex items-center gap-1 shrink-0"
                    >
                      <span className="material-symbols-outlined text-[14px]">visibility</span>
                      <span>Audit Trail</span>
                    </button>
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
