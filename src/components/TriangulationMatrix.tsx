'use client';

import React, { useState } from 'react';
import { ScheduleActivity } from '../types';

interface TriangulationMatrixProps {
  activity: ScheduleActivity;
  onOpenAuditLog: () => void;
  onRequestLabExpedite: () => void;
}

export const TriangulationMatrix: React.FC<TriangulationMatrixProps> = ({
  activity,
  onOpenAuditLog,
  onRequestLabExpedite,
}) => {
  const [showWeightModal, setShowWeightModal] = useState(false);
  const [droneWeight, setDroneWeight] = useState(30);
  const [qsWeight, setQsWeight] = useState(35);
  const [qcWeight, setQcWeight] = useState(35);
  const [showDifferenceDrawer, setShowDifferenceDrawer] = useState(false);

  // Dynamic consensus calculation based on weights
  const totalWeight = droneWeight + qsWeight + qcWeight;
  const calculatedConsensus = Math.round(
    ((activity.droneLidarProgress * droneWeight) +
     (activity.quantitySurveyProgress * qsWeight) +
     (activity.qcPassedProgress * qcWeight)) / totalWeight * 10
  ) / 10;

  const deltaVsClaim = Math.round((activity.contractorReportedProgress - calculatedConsensus) * 10) / 10;
  const isToleranceBreached = Math.abs(deltaVsClaim) > 5.0;

  return (
    <div className="flex flex-col gap-space-lg">
      {/* Top Summary Banner */}
      <div className="grid grid-cols-1 xl:grid-cols-12 gap-space-md">
        {/* Consensus Truth Card */}
        <div className="xl:col-span-4 bg-surface-container-lowest p-space-lg rounded-DEFAULT border border-surface-container-high shadow-sm flex flex-col justify-between relative overflow-hidden">
          <div className="absolute -right-10 -bottom-10 w-44 h-44 rounded-full bg-primary/5 pointer-events-none"></div>
          <div>
            <div className="flex items-center justify-between">
              <div className="flex flex-col">
                <span className="text-[11px] text-on-surface-variant uppercase tracking-wider font-semibold">
                  Validated Multi-Factor Progress
                </span>
                <span className="font-mono text-[12px] text-on-surface-variant">
                  {activity.activityCode} · {activity.name.slice(0, 32)}...
                </span>
              </div>
              <span className="px-space-xs py-0.5 rounded-full bg-tertiary-container/20 text-tertiary font-mono text-[11px] font-bold flex items-center gap-1 border border-tertiary/20">
                <span className="w-1.5 h-1.5 rounded-full bg-tertiary"></span>
                HIGH CONFIDENCE ({activity.progressConfidence}%)
              </span>
            </div>

            <div className="mt-space-lg flex items-baseline gap-space-sm">
              <span className="text-4xl text-primary font-black tracking-tight font-mono font-tnum">
                {calculatedConsensus}
              </span>
              <span className="text-xl text-primary font-semibold">%</span>
              <span className="text-[13px] text-on-surface-variant ml-space-xs font-medium">
                Reconciled Consensus Truth
              </span>
            </div>

            {/* Split Progress Bar */}
            <div className="mt-space-md relative w-full h-3 bg-surface-container rounded-full overflow-hidden flex">
              <div
                className="h-full bg-primary transition-all duration-500"
                style={{ width: `${calculatedConsensus}%` }}
                title={`Consensus: ${calculatedConsensus}%`}
              ></div>
              {deltaVsClaim > 0 && (
                <div
                  className="h-full bg-secondary-container/80 transition-all duration-500"
                  style={{ width: `${deltaVsClaim}%` }}
                  title={`Contested Contractor Delta: +${deltaVsClaim}%`}
                ></div>
              )}
            </div>

            <div className="flex items-center justify-between mt-space-xs text-on-surface-variant font-mono text-[11px]">
              <span>Verified 0.0%</span>
              <span className="text-primary font-bold">Consensus {calculatedConsensus}%</span>
              <span className="text-secondary font-semibold">Claimed {activity.contractorReportedProgress}%</span>
            </div>
          </div>

          <div className="mt-space-lg pt-space-md bg-surface-container-low p-space-md rounded-DEFAULT border border-surface-container-high/60">
            <div className="flex items-center justify-between text-on-surface-variant text-[11px]">
              <span className="uppercase font-semibold">Assigned Contractor JV</span>
              <span className="text-on-surface font-semibold truncate">Central Viaduct JV · Fe500D / API 5L</span>
            </div>
            <div className="flex items-center justify-between mt-1 text-on-surface-variant text-[11px]">
              <span className="uppercase font-semibold">Surveyed Cycle</span>
              <span className="font-mono text-on-surface">Cycle #44 (Updated {activity.lastEvidenceUpdate})</span>
            </div>
          </div>
        </div>

        {/* 4-Source Triangulation Breakdown */}
        <div className="xl:col-span-8 bg-surface-container-lowest p-space-lg rounded-DEFAULT border border-surface-container-high shadow-sm flex flex-col justify-between">
          <div className="flex items-center justify-between flex-wrap gap-2">
            <div>
              <span className="text-[11px] text-on-surface-variant uppercase tracking-wider font-semibold">
                Multi-Source Field Triangulation Engine (SIH26122)
              </span>
              <p className="text-[12px] text-on-surface-variant">
                Cross-referencing human submittals, quantity surveys, lab tests & drone observations
              </p>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-[11px] text-on-surface-variant font-mono bg-surface-container px-2 py-0.5 rounded-sm border border-surface-container-high">
                Tolerance Limit: ±5.0%
              </span>
              <button
                onClick={() => setShowDifferenceDrawer(true)}
                className="px-2.5 py-1 text-[11px] font-semibold text-primary bg-primary/10 hover:bg-primary/20 border border-primary/20 rounded-DEFAULT flex items-center gap-1 transition-all"
              >
                <span className="material-symbols-outlined text-[14px]">help</span>
                Why is there a difference?
              </button>
            </div>
          </div>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-space-sm mt-space-md">
            {/* 1. Contractor Claim */}
            <div className="bg-surface-container-low p-space-md rounded-DEFAULT border border-surface-container-high flex flex-col justify-between">
              <div className="flex items-center justify-between text-on-surface-variant">
                <span className="text-[11px] uppercase font-semibold">Contractor Claim</span>
                <span className="material-symbols-outlined text-[17px] text-secondary">assignment_ind</span>
              </div>
              <div className="my-space-sm">
                <div className="text-xl font-bold font-mono text-secondary">{activity.contractorReportedProgress}%</div>
                <span className="text-[11px] text-on-surface-variant">IPC #14 Submittal</span>
              </div>
              <div className="w-full bg-surface-container h-1.5 rounded-full overflow-hidden">
                <div className="bg-secondary h-full" style={{ width: `${activity.contractorReportedProgress}%` }}></div>
              </div>
              <span className={`text-[10px] font-mono mt-2 ${deltaVsClaim > 5.0 ? 'text-error font-bold' : 'text-on-surface-variant'}`}>
                +{deltaVsClaim}% over Consensus
              </span>
            </div>

            {/* 2. Quantity Survey */}
            <div className="bg-surface-container-low p-space-md rounded-DEFAULT border border-surface-container-high flex flex-col justify-between">
              <div className="flex items-center justify-between text-on-surface-variant">
                <span className="text-[11px] uppercase font-semibold">Quantity Survey</span>
                <span className="material-symbols-outlined text-[17px] text-primary">calculate</span>
              </div>
              <div className="my-space-sm">
                <div className="text-xl font-bold font-mono text-on-surface">{activity.quantitySurveyProgress}%</div>
                <span className="text-[11px] text-on-surface-variant">{activity.installedQuantity} / {activity.plannedQuantity} {activity.unit}</span>
              </div>
              <div className="w-full bg-surface-container h-1.5 rounded-full overflow-hidden">
                <div className="bg-primary h-full" style={{ width: `${activity.quantitySurveyProgress}%` }}></div>
              </div>
              <span className="text-[10px] text-on-surface-variant font-mono mt-2">Physical In-Place Calc</span>
            </div>

            {/* 3. QA/QC Passed */}
            <div className="bg-surface-container-low p-space-md rounded-DEFAULT border border-surface-container-high flex flex-col justify-between">
              <div className="flex items-center justify-between text-on-surface-variant">
                <span className="text-[11px] uppercase font-semibold">QA/QC Passed</span>
                <span className="material-symbols-outlined text-[17px] text-tertiary">fact_check</span>
              </div>
              <div className="my-space-sm">
                <div className="text-xl font-bold font-mono text-on-surface">{activity.qcPassedProgress}%</div>
                <span className="text-[11px] text-on-surface-variant">NDT RT & Lab Passed</span>
              </div>
              <div className="w-full bg-surface-container h-1.5 rounded-full overflow-hidden">
                <div className="bg-tertiary h-full" style={{ width: `${activity.qcPassedProgress}%` }}></div>
              </div>
              <span className="text-[10px] text-secondary font-mono mt-2">2 joints pending RT</span>
            </div>

            {/* 4. Drone & LiDAR */}
            <div className="bg-surface-container-low p-space-md rounded-DEFAULT border border-surface-container-high flex flex-col justify-between">
              <div className="flex items-center justify-between text-on-surface-variant">
                <span className="text-[11px] uppercase font-semibold">Drone & LiDAR</span>
                <span className="material-symbols-outlined text-[17px] text-primary">scanner</span>
              </div>
              <div className="my-space-sm">
                <div className="text-xl font-bold font-mono text-on-surface">{activity.droneLidarProgress}%</div>
                <span className="text-[11px] text-on-surface-variant">Point Cloud Volumetric</span>
              </div>
              <div className="w-full bg-surface-container h-1.5 rounded-full overflow-hidden">
                <div className="bg-primary/80 h-full" style={{ width: `${activity.droneLidarProgress}%` }}></div>
              </div>
              <span className="text-[10px] text-error font-mono mt-2">
                -{Math.round((activity.contractorReportedProgress - activity.droneLidarProgress) * 10) / 10}% delta vs claim
              </span>
            </div>
          </div>

          {/* Algorithm Weight Indicator & Settings Trigger */}
          <div className="mt-space-md pt-space-sm border-t border-surface-container-high flex flex-wrap items-center justify-between gap-space-sm text-on-surface-variant text-[11px]">
            <div className="flex items-center gap-space-md">
              <span className="flex items-center gap-1.5 font-medium">
                <span className="w-2 h-2 rounded-sm bg-primary"></span>
                Formula Weights: Drone ({droneWeight}%) + QS ({qsWeight}%) + QC ({qcWeight}%)
              </span>
            </div>
            <button
              onClick={() => setShowWeightModal(true)}
              className="text-primary hover:underline font-semibold flex items-center gap-0.5"
            >
              <span>Modify Weighting Algorithm</span>
              <span className="material-symbols-outlined text-[14px]">arrow_forward</span>
            </button>
          </div>
        </div>
      </div>

      {/* Difference Explanation Drawer / Modal */}
      {showDifferenceDrawer && (
        <div className="p-4 bg-surface-container-lowest border border-primary/30 rounded-DEFAULT flex flex-col gap-3 animate-fade-in">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-primary text-[20px]">account_tree</span>
              <h3 className="font-semibold text-sm text-on-surface">Evidence Lineage: Why is there a difference?</h3>
            </div>
            <button
              onClick={() => setShowDifferenceDrawer(false)}
              className="text-on-surface-variant hover:text-on-surface text-xs"
            >
              Close
            </button>
          </div>
          <p className="text-xs text-on-surface-variant">
            Contractor claimed <strong>{activity.contractorReportedProgress}%</strong> while Consensus Truth is <strong>{calculatedConsensus}%</strong> (Variance: +{deltaVsClaim}%). Here is the breakdown:
          </p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-xs">
            <div className="p-3 bg-surface-container rounded-sm border border-surface-container-high">
              <span className="font-bold text-secondary block mb-1">1. Material Delay on Field Spools</span>
              <p className="text-on-surface-variant text-[11px]">
                Contractor assumed 100% of Line 24 spools were lower-in ready. 6 spools were held at Store B due to mill test certification delays.
              </p>
            </div>
            <div className="p-3 bg-surface-container rounded-sm border border-surface-container-high">
              <span className="font-bold text-tertiary block mb-1">2. QA/QC RT Hold Points</span>
              <p className="text-on-surface-variant text-[11px]">
                Orbital welds on joints #W24-05 & #W24-06 are completed physically, but NDT radiography clearance has not been signed off by 3rd-party inspector.
              </p>
            </div>
            <div className="p-3 bg-surface-container rounded-sm border border-surface-container-high">
              <span className="font-bold text-primary block mb-1">3. LiDAR Spatial Volumetrics</span>
              <p className="text-on-surface-variant text-[11px]">
                Drone flight FL-094-14 scans confirmed stringing along 304m of 420m total alignment, confirming 72.4% physical presence.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Weighting Slider Modal */}
      {showWeightModal && (
        <div className="p-4 bg-surface-container border border-surface-container-high rounded-DEFAULT flex flex-col gap-3">
          <div className="flex items-center justify-between">
            <h4 className="font-bold text-xs text-on-surface uppercase tracking-wider">Configure Triangulation Weights</h4>
            <button onClick={() => setShowWeightModal(false)} className="text-xs text-primary font-semibold">Done</button>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-xs">
            <div>
              <label className="text-on-surface-variant block mb-1">Drone & LiDAR Weight: {droneWeight}%</label>
              <input
                type="range" min="10" max="60" value={droneWeight}
                onChange={(e) => setDroneWeight(Number(e.target.value))}
                className="w-full accent-primary"
              />
            </div>
            <div>
              <label className="text-on-surface-variant block mb-1">Quantity Survey Weight: {qsWeight}%</label>
              <input
                type="range" min="10" max="60" value={qsWeight}
                onChange={(e) => setQsWeight(Number(e.target.value))}
                className="w-full accent-primary"
              />
            </div>
            <div>
              <label className="text-on-surface-variant block mb-1">QA/QC Passed Weight: {qcWeight}%</label>
              <input
                type="range" min="10" max="60" value={qcWeight}
                onChange={(e) => setQcWeight(Number(e.target.value))}
                className="w-full accent-primary"
              />
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
