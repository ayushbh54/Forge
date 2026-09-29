'use client';

import React, { useState } from 'react';
import { ScheduleActivity, WBSNode } from '../types';

interface GanttScheduleViewProps {
  activities: ScheduleActivity[];
  wbsNodes: WBSNode[];
  selectedActivityCode: string;
  onSelectActivity: (code: string) => void;
}

export const GanttScheduleView: React.FC<GanttScheduleViewProps> = ({
  activities,
  wbsNodes,
  selectedActivityCode,
  onSelectActivity,
}) => {
  const [selectedDiscipline, setSelectedDiscipline] = useState<string>('ALL');
  const [showCriticalOnly, setShowCriticalOnly] = useState(false);

  const filteredActivities = activities.filter(act => {
    if (selectedDiscipline !== 'ALL' && act.discipline !== selectedDiscipline) return false;
    if (showCriticalOnly && !act.isCriticalPath) return false;
    return true;
  });

  return (
    <div className="bg-surface-container-lowest p-5 rounded-DEFAULT border border-surface-container-high shadow-sm flex flex-col gap-4">
      {/* Header and Controls */}
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-surface-container-high/60 pb-3">
        <div>
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-primary text-[20px]">calendar_month</span>
            <h2 className="text-sm font-bold uppercase tracking-wider text-on-surface">
              Primavera P6 & MS Project Master Schedule (L1–L6)
            </h2>
          </div>
          <p className="text-xs text-on-surface-variant">
            Critical Path Analysis, Floats, Step Weights & Real-time Field Reconciliation
          </p>
        </div>

        {/* Filter Toolbar */}
        <div className="flex flex-wrap items-center gap-2">
          {/* Discipline Filter */}
          <div className="flex items-center gap-1 bg-surface-container px-2 py-1 rounded-sm border border-surface-container-high text-xs">
            <span className="text-on-surface-variant text-[11px]">Discipline:</span>
            <select
              value={selectedDiscipline}
              onChange={(e) => setSelectedDiscipline(e.target.value)}
              className="bg-transparent text-on-surface font-semibold focus:outline-none cursor-pointer"
            >
              <option value="ALL" className="bg-surface-container">All Disciplines</option>
              <option value="PIPING" className="bg-surface-container">Piping</option>
              <option value="CIVIL" className="bg-surface-container">Civil</option>
              <option value="ELECTRICAL" className="bg-surface-container">Electrical</option>
            </select>
          </div>

          {/* Critical Path Toggle */}
          <button
            onClick={() => setShowCriticalOnly(!showCriticalOnly)}
            className={`px-2.5 py-1 text-xs rounded-sm font-semibold border flex items-center gap-1 transition-all ${
              showCriticalOnly 
                ? 'bg-error-container text-on-error-container border-error/40' 
                : 'bg-surface-container text-on-surface-variant border-surface-container-high hover:text-on-surface'
            }`}
          >
            <span className="material-symbols-outlined text-[15px]">crisis_alert</span>
            <span>Critical Path Only</span>
          </button>

          {/* P6 Import/Export */}
          <button
            onClick={() => alert('P6 XML / XER schema exported for Primavera P6 EPPM / Professional v22.12')}
            className="px-2.5 py-1 text-xs bg-surface-container hover:bg-surface-container-high text-primary font-semibold border border-surface-container-high rounded-sm flex items-center gap-1 transition-all"
          >
            <span className="material-symbols-outlined text-[15px]">download</span>
            <span>Export P6 XML</span>
          </button>
        </div>
      </div>

      {/* Schedule Table & Gantt View */}
      <div className="overflow-x-auto">
        <table className="w-full text-left text-xs border-collapse">
          <thead>
            <tr className="border-b border-surface-container-high text-on-surface-variant font-mono uppercase text-[11px]">
              <th className="py-2.5 px-3">Act ID</th>
              <th className="py-2.5 px-3">WBS</th>
              <th className="py-2.5 px-3">Activity Description</th>
              <th className="py-2.5 px-3 text-center">Dur</th>
              <th className="py-2.5 px-3 text-center">Float</th>
              <th className="py-2.5 px-3">Planned vs Reality</th>
              <th className="py-2.5 px-3 text-right">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-surface-container-high/40">
            {filteredActivities.map((act) => {
              const isSelected = selectedActivityCode === act.activityCode;
              return (
                <tr
                  key={act.id}
                  onClick={() => onSelectActivity(act.activityCode)}
                  className={`cursor-pointer transition-all hover:bg-surface-container ${
                    isSelected ? 'bg-primary/10 border-l-2 border-primary font-medium' : ''
                  }`}
                >
                  <td className="py-3 px-3 font-mono font-bold text-primary whitespace-nowrap">
                    {act.activityCode}
                  </td>
                  <td className="py-3 px-3 font-mono text-on-surface-variant whitespace-nowrap">
                    {act.wbsCode}
                  </td>
                  <td className="py-3 px-3 text-on-surface max-w-xs truncate">
                    <div className="flex items-center gap-1.5">
                      {act.isCriticalPath && (
                        <span className="w-2 h-2 rounded-full bg-error" title="Critical Path Activity"></span>
                      )}
                      <span className="font-semibold text-xs">{act.name}</span>
                    </div>
                    <span className="text-[11px] text-on-surface-variant block truncate">
                      {act.description}
                    </span>
                  </td>
                  <td className="py-3 px-3 font-mono text-center text-on-surface-variant">
                    {act.durationDays}d
                  </td>
                  <td className="py-3 px-3 font-mono text-center">
                    <span className={act.totalFloatDays === 0 ? 'text-error font-bold' : 'text-on-surface-variant'}>
                      {act.totalFloatDays}d
                    </span>
                  </td>
                  <td className="py-3 px-3 min-w-[200px]">
                    <div className="flex flex-col gap-1">
                      <div className="flex items-center justify-between text-[11px] font-mono">
                        <span className="text-on-surface-variant">Plan: {act.plannedProgress}%</span>
                        <span className="text-primary font-bold">Consensus: {act.validatedConsensusProgress}%</span>
                      </div>
                      <div className="w-full bg-surface-container h-2 rounded-full overflow-hidden flex">
                        <div
                          className="bg-primary h-full transition-all"
                          style={{ width: `${act.validatedConsensusProgress}%` }}
                        ></div>
                        {act.contractorReportedProgress > act.validatedConsensusProgress && (
                          <div
                            className="bg-secondary-container h-full transition-all"
                            style={{ width: `${act.contractorReportedProgress - act.validatedConsensusProgress}%` }}
                          ></div>
                        )}
                      </div>
                    </div>
                  </td>
                  <td className="py-3 px-3 text-right whitespace-nowrap">
                    {act.toleranceExceeded ? (
                      <span className="px-2 py-0.5 rounded-full bg-error-container text-on-error-container font-mono text-[10px] font-bold">
                        Variance Alert (+{act.deltaVsConsensus}%)
                      </span>
                    ) : act.validatedConsensusProgress === 100 ? (
                      <span className="px-2 py-0.5 rounded-full bg-tertiary-container/20 text-tertiary font-mono text-[10px] font-bold">
                        Completed
                      </span>
                    ) : (
                      <span className="px-2 py-0.5 rounded-full bg-primary/20 text-primary font-mono text-[10px] font-bold">
                        Active Lookahead
                      </span>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {/* Steps Breakdown for Selected Activity (P6 Feature) */}
      {selectedActivityCode && (
        <div className="p-4 bg-surface-container-low rounded-DEFAULT border border-surface-container-high flex flex-col gap-2">
          <div className="flex items-center justify-between">
            <span className="text-xs uppercase font-bold text-on-surface font-mono">
              Activity Steps Breakdown (Primavera P6 Milestone Weights)
            </span>
            <span className="text-[11px] text-primary font-mono font-semibold">
              Selected: {selectedActivityCode}
            </span>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-5 gap-2 text-xs">
            {activities.find(a => a.activityCode === selectedActivityCode)?.steps?.map((step) => (
              <div
                key={step.id}
                className={`p-2.5 rounded-sm border flex flex-col justify-between ${
                  step.completed 
                    ? 'bg-tertiary-container/10 border-tertiary/30 text-on-surface' 
                    : 'bg-surface-container border-surface-container-high text-on-surface-variant'
                }`}
              >
                <div className="flex items-center justify-between">
                  <span className="font-mono text-[10px] font-bold text-primary">{step.weight}% Wt</span>
                  <span className={`material-symbols-outlined text-[16px] ${step.completed ? 'text-tertiary' : 'text-outline'}`}>
                    {step.completed ? 'check_circle' : 'radio_button_unchecked'}
                  </span>
                </div>
                <span className="font-medium text-[11px] mt-1 leading-snug">{step.name}</span>
                <span className="text-[10px] text-on-surface-variant font-mono mt-1">
                  {step.completed ? `Done (${step.completionDate || 'Verified'})` : 'In Progress'}
                </span>
              </div>
            )) || (
              <span className="text-xs text-on-surface-variant col-span-full">No granular sub-steps defined for this activity.</span>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
