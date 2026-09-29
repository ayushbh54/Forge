'use client';

import React, { useState } from 'react';
import { ScheduleActivity } from '../types';

interface InteractiveDprViewProps {
  activities: ScheduleActivity[];
  onSubmitDpr: (activityCode: string, quantity: number, unit: string, delayReason: string, notes: string) => void;
}

export const InteractiveDprView: React.FC<InteractiveDprViewProps> = ({
  activities,
  onSubmitDpr,
}) => {
  const [selectedAct, setSelectedAct] = useState(activities[0]?.activityCode || 'PIP-L5-024');
  const [quantity, setQuantity] = useState(45);
  const [unit, setUnit] = useState('meters');
  const [delayReason, setDelayReason] = useState('Material Spool Delay');
  const [notes, setNotes] = useState('Completed 6G downhill orbital welding on joints #W24-01 through #W24-06. NDT scheduled for evening shift.');
  const [isSuccess, setIsSuccess] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmitDpr(selectedAct, quantity, unit, delayReason, notes);
    setIsSuccess(true);
    setTimeout(() => setIsSuccess(false), 3000);
  };

  return (
    <div className="bg-surface-container-lowest p-5 rounded-DEFAULT border border-surface-container-high shadow-sm flex flex-col gap-4">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-surface-container-high/60 pb-3">
        <div>
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-primary text-[20px]">history_edu</span>
            <h2 className="text-sm font-bold uppercase tracking-wider text-on-surface">
              Interactive Daily Construction Log (DPR)
            </h2>
          </div>
          <p className="text-xs text-on-surface-variant">
            Direct field execution logger matching the Indian Infrastructure Project Management Mobile APK
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="px-2.5 py-0.5 rounded-full bg-tertiary/20 text-tertiary text-xs font-mono font-bold">
            Shift: Day (07:00 – 17:30)
          </span>
          <span className="px-2.5 py-0.5 rounded-full bg-surface-container text-on-surface-variant text-xs font-mono">
            Weather: 28°C / Dry
          </span>
        </div>
      </div>

      {isSuccess && (
        <div className="p-3 bg-tertiary-container/20 border border-tertiary/40 rounded-DEFAULT text-tertiary text-xs flex items-center gap-2 animate-fade-in">
          <span className="material-symbols-outlined text-[18px]">verified</span>
          <span>Daily Progress Report (DPR #44) successfully submitted, timestamped, and linked to Schedule Activity!</span>
        </div>
      )}

      {/* DPR Submission Form */}
      <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Left Column */}
        <div className="flex flex-col gap-3">
          <div>
            <label className="text-[11px] uppercase font-bold text-on-surface-variant block mb-1">
              Select Schedule Activity (P6 L5/L6)
            </label>
            <select
              value={selectedAct}
              onChange={(e) => setSelectedAct(e.target.value)}
              className="w-full p-2.5 bg-surface-container-low text-on-surface text-xs rounded-DEFAULT border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary"
            >
              {activities.map((a) => (
                <option key={a.id} value={a.activityCode} className="bg-surface-container">
                  [{a.activityCode}] {a.name}
                </option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-2">
            <div>
              <label className="text-[11px] uppercase font-bold text-on-surface-variant block mb-1">
                Installed Today
              </label>
              <input
                type="number"
                value={quantity}
                onChange={(e) => setQuantity(Number(e.target.value))}
                className="w-full p-2 bg-surface-container-low text-on-surface text-xs rounded-DEFAULT border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary"
              />
            </div>
            <div>
              <label className="text-[11px] uppercase font-bold text-on-surface-variant block mb-1">
                Unit of Measure
              </label>
              <input
                type="text"
                value={unit}
                onChange={(e) => setUnit(e.target.value)}
                className="w-full p-2 bg-surface-container-low text-on-surface text-xs rounded-DEFAULT border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary"
              />
            </div>
          </div>

          <div>
            <label className="text-[11px] uppercase font-bold text-on-surface-variant block mb-1">
              Delay Reason (If Any)
            </label>
            <select
              value={delayReason}
              onChange={(e) => setDelayReason(e.target.value)}
              className="w-full p-2 bg-surface-container-low text-on-surface text-xs rounded-DEFAULT border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary"
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
        <div className="flex flex-col gap-3">
          <div>
            <label className="text-[11px] uppercase font-bold text-on-surface-variant block mb-1">
              Shift Diary & Detailed Progress Notes
            </label>
            <textarea
              rows={4}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              className="w-full p-2.5 bg-surface-container-low text-on-surface text-xs rounded-DEFAULT border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary resize-none"
            />
          </div>

          {/* Photo & GPS Geo-Tag Preview */}
          <div className="p-3 bg-surface-container-low rounded-DEFAULT border border-dashed border-surface-container-high flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-primary text-[20px]">add_a_photo</span>
              <div className="flex flex-col">
                <span className="text-xs font-semibold text-on-surface">Site Photo #IMG-2026-0929-01.jpg</span>
                <span className="text-[10px] text-tertiary font-mono">Geo: 27.3512° N, 95.3124° E (Assam Trench)</span>
              </div>
            </div>
            <span className="px-2 py-0.5 rounded-sm bg-tertiary/20 text-tertiary text-[10px] font-mono font-bold">
              GPS Verified
            </span>
          </div>

          <div className="flex justify-end gap-2 mt-auto">
            <button
              type="submit"
              className="h-10 px-6 bg-primary hover:bg-primary-container text-on-primary font-bold text-xs rounded-DEFAULT flex items-center gap-1.5 transition-all shadow-sm active:scale-95"
            >
              <span className="material-symbols-outlined text-[17px]">publish</span>
              <span>Submit & Link DPR</span>
            </button>
          </div>
        </div>
      </form>
    </div>
  );
};
