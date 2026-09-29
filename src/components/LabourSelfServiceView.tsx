'use client';

import React from 'react';
import { WorkerProfile, ScheduleActivity } from '../types';

interface LabourSelfServiceViewProps {
  worker: WorkerProfile;
  activity: ScheduleActivity;
  onClockIn: () => void;
}

export const LabourSelfServiceView: React.FC<LabourSelfServiceViewProps> = ({
  worker,
  activity,
  onClockIn,
}) => {
  return (
    <div className="max-w-xl mx-auto bg-surface-container-lowest border border-surface-container-high rounded-xl p-5 shadow-2xl flex flex-col gap-4 animate-fade-in text-on-surface">
      {/* Top Banner */}
      <div className="flex items-center justify-between border-b border-surface-container-high/60 pb-3">
        <div className="flex items-center gap-2">
          <span className="w-8 h-8 rounded-DEFAULT bg-primary/20 text-primary flex items-center justify-center font-bold">
            <span className="material-symbols-outlined text-[20px]">badge</span>
          </span>
          <div>
            <h2 className="font-bold text-sm text-on-surface">Digital Labour Identity (श्रम पहचान)</h2>
            <p className="text-[11px] text-on-surface-variant font-mono">OIL Smart Contractor ID · {worker.badgeNumber}</p>
          </div>
        </div>
        <span className="px-2.5 py-0.5 rounded-full bg-tertiary/20 text-tertiary font-mono text-[11px] font-bold">
          Verified Active
        </span>
      </div>

      {/* Digital ID Card */}
      <div className="p-4 bg-gradient-to-br from-surface-container-low to-surface-container rounded-lg border border-primary/30 flex flex-col gap-3 relative overflow-hidden shadow-sm">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-3">
            <div className="w-14 h-14 rounded-full bg-primary/10 border-2 border-primary overflow-hidden flex items-center justify-center text-primary font-black text-lg">
              TD
            </div>
            <div>
              <h3 className="font-bold text-base text-on-surface">{worker.name}</h3>
              <span className="text-xs text-secondary font-mono font-bold block">{worker.trade}</span>
              <span className="text-[11px] text-on-surface-variant">{worker.contractor}</span>
            </div>
          </div>
          <div className="w-16 h-16 bg-white p-1 rounded-sm flex items-center justify-center shadow-inner">
            {/* Simulated QR Code */}
            <div className="w-full h-full bg-black/90 flex items-center justify-center text-[8px] text-white font-mono text-center leading-none p-1">
              QR-LAB-0442
            </div>
          </div>
        </div>

        {/* Skills & Compliance Badges */}
        <div className="flex flex-wrap gap-1.5 pt-2 border-t border-surface-container-high/60">
          {worker.skills.map((s, idx) => (
            <span key={idx} className="px-2 py-0.5 rounded-sm bg-surface-container-lowest text-primary text-[10px] font-mono font-semibold border border-surface-container-high">
              {s}
            </span>
          ))}
          <span className="px-2 py-0.5 rounded-sm bg-tertiary/15 text-tertiary text-[10px] font-mono font-semibold border border-tertiary/20">
            Medical Fit: Yes
          </span>
          <span className="px-2 py-0.5 rounded-sm bg-tertiary/15 text-tertiary text-[10px] font-mono font-semibold border border-tertiary/20">
            Safety Cert: Valid
          </span>
        </div>
      </div>

      {/* Today's Assigned Work Package */}
      <div className="p-4 bg-surface-container-low rounded-DEFAULT border border-surface-container-high flex flex-col gap-2">
        <div className="flex items-center justify-between">
          <span className="text-[11px] uppercase font-bold text-on-surface-variant">Today's Assigned Task (आज का कार्य)</span>
          <span className="font-mono text-xs font-bold text-primary">{activity.activityCode}</span>
        </div>
        <h4 className="font-bold text-xs text-on-surface leading-snug">{activity.name}</h4>
        <p className="text-[11px] text-on-surface-variant leading-relaxed">
          Assigned Step: <strong>Hot, Fill & Cap Welding Passes</strong> on joints #W24-01 to #W24-06 (Chainage 14+350).
        </p>
        <div className="flex items-center justify-between text-xs text-on-surface-variant pt-2 border-t border-surface-container-high font-mono">
          <span>Supervisor: R. K. Sharma</span>
          <span className="text-tertiary">Site Gang: 18 Fitters/Welders</span>
        </div>
      </div>

      {/* Attendance & Self-Check-in Action */}
      <div className="p-4 bg-surface-container-low rounded-DEFAULT border border-surface-container-high flex items-center justify-between">
        <div>
          <span className="text-[11px] uppercase font-bold text-on-surface-variant block">Attendance Status</span>
          <span className="font-mono text-xs font-bold text-tertiary flex items-center gap-1 mt-0.5">
            <span className="w-2 h-2 rounded-full bg-tertiary"></span>
            {worker.lastClockIn}
          </span>
          <span className="text-[10px] text-on-surface-variant font-mono">Verification Confidence: {worker.confidenceScore}%</span>
        </div>
        <button
          onClick={onClockIn}
          className="h-10 px-4 bg-primary hover:bg-primary-container text-on-primary font-bold text-xs rounded-DEFAULT shadow-sm transition-all active:scale-95"
        >
          Check-in Now
        </button>
      </div>
    </div>
  );
};
