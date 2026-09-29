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

  const handleConfirmResolve = (id: string) => {
    onResolve(id, resolutionNote || 'Reconciled during joint field walk with Engineer Representative.');
    setResolvingId(null);
    setResolutionNote('');
  };

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-sm font-bold uppercase tracking-wider text-on-surface">
            Conflict & Silent Risk Center
          </h2>
          <p className="text-xs text-on-surface-variant">
            Automated detection of tolerance breaches, unverified structural tests, and hidden supply-chain bottlenecks
          </p>
        </div>
        <span className="px-2.5 py-0.5 rounded-full bg-error-container text-on-error-container text-xs font-mono font-bold">
          {conflicts.filter(c => c.status === 'OPEN').length} Active Flags
        </span>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-space-md">
        {conflicts.map((conf) => {
          const isCritical = conf.severity === 'CRITICAL';
          const isResolved = conf.status === 'RESOLVED';

          return (
            <div
              key={conf.id}
              className={`p-4 rounded-DEFAULT border relative overflow-hidden flex flex-col justify-between shadow-sm transition-all ${
                isResolved 
                  ? 'bg-surface-container/40 border-surface-container-high opacity-70'
                  : 'bg-surface-container-lowest border-surface-container-high'
              }`}
            >
              {/* Left Accent Stripe */}
              <div
                className={`absolute left-0 top-0 bottom-0 w-1.5 ${
                  isResolved 
                    ? 'bg-tertiary' 
                    : isCritical 
                    ? 'bg-error' 
                    : 'bg-secondary'
                }`}
              ></div>

              <div className="pl-2">
                <div className="flex items-start justify-between gap-2">
                  <div className="flex items-center gap-1.5">
                    <span
                      className={`material-symbols-outlined text-[19px] ${
                        isResolved ? 'text-tertiary' : isCritical ? 'text-error' : 'text-secondary'
                      }`}
                    >
                      {isResolved ? 'check_circle' : isCritical ? 'difference' : 'warning'}
                    </span>
                    <h3 className="font-semibold text-xs sm:text-sm text-on-surface leading-snug">
                      {conf.title}
                    </h3>
                  </div>
                  <span
                    className={`px-2 py-0.5 rounded-sm font-mono text-[10px] font-bold whitespace-nowrap ${
                      isResolved 
                        ? 'bg-tertiary/20 text-tertiary' 
                        : isCritical 
                        ? 'bg-error-container text-on-error-container' 
                        : 'bg-secondary/20 text-secondary'
                    }`}
                  >
                    {isResolved ? 'RESOLVED' : conf.varianceValue || conf.severity}
                  </span>
                </div>

                <p className="text-xs text-on-surface mt-2 leading-relaxed">
                  {conf.description}
                </p>

                <div className="mt-3 flex flex-wrap items-center gap-2 text-[11px] text-on-surface-variant font-mono">
                  <span className="bg-surface-container px-1.5 py-0.5 rounded-sm">Act: {conf.activityCode}</span>
                  <span>•</span>
                  <span>{conf.specOrClause}</span>
                  <span>•</span>
                  <span>{conf.timestamp}</span>
                </div>
              </div>

              {/* Actions */}
              <div className="mt-4 pl-2 pt-2 border-t border-surface-container-high/60 flex flex-wrap items-center justify-between gap-2">
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => onInvestigate(conf.activityCode)}
                    className="h-8 px-3 bg-surface-container hover:bg-surface-container-high text-on-surface rounded-sm text-xs font-medium flex items-center gap-1 transition-colors"
                  >
                    <span className="material-symbols-outlined text-[15px]">account_tree</span>
                    <span>Investigate</span>
                  </button>
                  {!isResolved && (
                    <button
                      onClick={() => setResolvingId(conf.id)}
                      className="h-8 px-3 bg-primary text-on-primary hover:bg-primary-container rounded-sm text-xs font-semibold flex items-center gap-1 transition-colors"
                    >
                      <span className="material-symbols-outlined text-[15px]">done_all</span>
                      <span>Resolve</span>
                    </button>
                  )}
                </div>
                {conf.claimedValue && (
                  <span className="text-[11px] text-on-surface-variant font-mono">
                    {conf.claimedValue} vs {conf.verifiedValue}
                  </span>
                )}
              </div>

              {/* Quick Resolve Input Drawer */}
              {resolvingId === conf.id && (
                <div className="mt-3 p-3 bg-surface-container rounded-sm border border-surface-container-high flex flex-col gap-2">
                  <span className="text-[11px] font-semibold text-on-surface">Enter Resolution Rationale (FIDIC Audit Trail):</span>
                  <input
                    type="text"
                    value={resolutionNote}
                    onChange={(e) => setResolutionNote(e.target.value)}
                    placeholder="e.g. Joint walk confirmed 304m lower-in. Rebar NDT clearance received."
                    className="p-2 text-xs bg-surface-container-low text-on-surface rounded-sm border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary"
                  />
                  <div className="flex justify-end gap-2">
                    <button onClick={() => setResolvingId(null)} className="px-2.5 py-1 text-xs text-on-surface-variant">Cancel</button>
                    <button onClick={() => handleConfirmResolve(conf.id)} className="px-3 py-1 bg-tertiary text-on-tertiary font-bold text-xs rounded-sm">Confirm Resolution</button>
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
};
