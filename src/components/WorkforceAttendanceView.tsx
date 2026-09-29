'use client';

import React, { useState } from 'react';
import { WorkerProfile } from '../types';

interface WorkforceAttendanceViewProps {
  workers: WorkerProfile[];
  onClockIn: (workerId: string) => void;
}

export const WorkforceAttendanceView: React.FC<WorkforceAttendanceViewProps> = ({
  workers,
  onClockIn,
}) => {
  const [selectedTrade, setSelectedTrade] = useState<string>('ALL');

  const filtered = workers.filter(w => selectedTrade === 'ALL' || w.trade === selectedTrade);

  return (
    <div className="bg-surface-container-lowest p-5 rounded-DEFAULT border border-surface-container-high shadow-sm flex flex-col gap-4">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-surface-container-high/60 pb-3">
        <div>
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-primary text-[20px]">badge</span>
            <h2 className="text-sm font-bold uppercase tracking-wider text-on-surface">
              Digital Workforce Identity & Verified Site Attendance
            </h2>
          </div>
          <p className="text-xs text-on-surface-variant">
            Geofence + Biometric multi-factor verification with productivity correlation
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="px-2.5 py-0.5 rounded-full bg-tertiary/20 text-tertiary text-xs font-mono font-bold">
            18 Verified Present
          </span>
          <span className="px-2.5 py-0.5 rounded-full bg-secondary/20 text-secondary text-xs font-mono font-bold">
            1 Needs Review
          </span>
        </div>
      </div>

      {/* Workforce Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
        {filtered.map((worker) => {
          const isVerified = worker.attendanceStatus === 'VERIFIED_PRESENT';
          return (
            <div
              key={worker.id}
              className="p-4 rounded-DEFAULT bg-surface-container-low border border-surface-container-high flex flex-col justify-between shadow-sm relative overflow-hidden"
            >
              {/* Top Row with Badge & Photo */}
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-center gap-2.5">
                  <div className="w-10 h-10 rounded-full bg-surface-container border border-surface-container-highest overflow-hidden flex-shrink-0 flex items-center justify-center font-bold text-xs text-primary">
                    {worker.name.split(' ').map(n => n[0]).join('')}
                  </div>
                  <div>
                    <h4 className="font-bold text-xs text-on-surface leading-tight">{worker.name}</h4>
                    <span className="text-[10px] text-on-surface-variant font-mono">{worker.badgeNumber}</span>
                  </div>
                </div>
                <span className="px-2 py-0.5 rounded-sm bg-primary/20 text-primary text-[10px] font-mono font-bold">
                  {worker.trade}
                </span>
              </div>

              {/* Skills and Certifications */}
              <div className="my-3 flex flex-col gap-1.5 text-[11px]">
                <div className="flex items-center justify-between text-on-surface-variant">
                  <span>Contractor:</span>
                  <span className="text-on-surface font-semibold truncate max-w-[140px]">{worker.contractor}</span>
                </div>
                <div className="flex items-center justify-between text-on-surface-variant">
                  <span>Assigned Work:</span>
                  <span className="font-mono text-secondary font-semibold">{worker.assignedActivityId}</span>
                </div>
                <div className="flex items-center justify-between text-on-surface-variant">
                  <span>Safety Induction:</span>
                  <span className="text-tertiary font-mono">Valid till {worker.safetyCertValidTill}</span>
                </div>
              </div>

              {/* Attendance Verification Strip */}
              <div className="pt-2 border-t border-surface-container-high/60 flex flex-col gap-1.5">
                <div className="flex items-center justify-between text-[11px]">
                  <span className="text-on-surface-variant">Confidence Score:</span>
                  <span className={`font-mono font-bold ${isVerified ? 'text-tertiary' : 'text-secondary'}`}>
                    {worker.confidenceScore}% ({isVerified ? 'Strong' : 'Review'})
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-[10px] text-on-surface-variant font-mono truncate max-w-[160px]">
                    {worker.lastClockIn}
                  </span>
                  <button
                    onClick={() => onClockIn(worker.id)}
                    className="px-2.5 py-1 bg-surface-container hover:bg-surface-container-high text-primary font-bold text-[10px] rounded-sm transition-colors"
                  >
                    Verify Clock-In
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
