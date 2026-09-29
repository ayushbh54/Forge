'use client';

import React from 'react';
import { ScheduleActivity } from '../types';

interface MobileFieldHUDProps {
  activity: ScheduleActivity;
  onOpenVoiceModal: () => void;
  onQuickProgressAdd: (quantity: number) => void;
}

export const MobileFieldHUD: React.FC<MobileFieldHUDProps> = ({
  activity,
  onOpenVoiceModal,
  onQuickProgressAdd,
}) => {
  return (
    <div className="max-w-md mx-auto bg-surface-container-lowest border border-surface-container-high rounded-xl p-4 shadow-2xl flex flex-col gap-4 animate-fade-in text-on-surface">
      {/* Mobile Top Status Header */}
      <div className="flex items-center justify-between border-b border-surface-container-high/60 pb-3">
        <div className="flex items-center gap-2">
          <span className="w-2.5 h-2.5 rounded-full bg-tertiary animate-pulse"></span>
          <span className="font-mono text-xs font-bold text-tertiary">Site Mode (Online · Synced)</span>
        </div>
        <span className="font-mono text-[11px] text-on-surface-variant bg-surface-container px-2 py-0.5 rounded-full">
          Assam Zone B
        </span>
      </div>

      {/* Main Work Card */}
      <div className="p-4 bg-surface-container-low rounded-DEFAULT border border-primary/30 flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <span className="text-[11px] uppercase font-bold text-primary font-mono">{activity.activityCode}</span>
          <span className="px-2 py-0.5 rounded-full bg-primary/20 text-primary font-mono text-[10px] font-bold">
            Critical Path
          </span>
        </div>
        <h3 className="font-bold text-sm leading-snug">{activity.name}</h3>

        {/* Progress Progress Gauge */}
        <div className="flex flex-col gap-1.5 mt-1">
          <div className="flex items-center justify-between text-xs font-mono">
            <span className="text-on-surface-variant">Installed: {activity.installedQuantity} / {activity.plannedQuantity} {activity.unit}</span>
            <span className="text-primary font-bold">{activity.validatedConsensusProgress}%</span>
          </div>
          <div className="w-full bg-surface-container h-3 rounded-full overflow-hidden flex">
            <div className="h-full bg-primary" style={{ width: `${activity.validatedConsensusProgress}%` }}></div>
          </div>
        </div>
      </div>

      {/* Quick Field Increments */}
      <div className="flex flex-col gap-1.5">
        <span className="text-[11px] uppercase font-bold text-on-surface-variant tracking-wider">
          One-Tap Field Quantity Entry:
        </span>
        <div className="grid grid-cols-3 gap-2">
          <button
            onClick={() => onQuickProgressAdd(5)}
            className="h-12 bg-surface-container hover:bg-surface-container-high border border-surface-container-high rounded-DEFAULT font-mono font-bold text-xs flex flex-col items-center justify-center active:scale-95 transition-all text-on-surface"
          >
            <span>+5 {activity.unit}</span>
            <span className="text-[9px] text-on-surface-variant font-normal">Add welding</span>
          </button>
          <button
            onClick={() => onQuickProgressAdd(10)}
            className="h-12 bg-surface-container hover:bg-surface-container-high border border-surface-container-high rounded-DEFAULT font-mono font-bold text-xs flex flex-col items-center justify-center active:scale-95 transition-all text-on-surface"
          >
            <span>+10 {activity.unit}</span>
            <span className="text-[9px] text-on-surface-variant font-normal">Add stringing</span>
          </button>
          <button
            onClick={() => onQuickProgressAdd(20)}
            className="h-12 bg-surface-container hover:bg-surface-container-high border border-surface-container-high rounded-DEFAULT font-mono font-bold text-xs flex flex-col items-center justify-center active:scale-95 transition-all text-on-surface"
          >
            <span>+20 {activity.unit}</span>
            <span className="text-[9px] text-on-surface-variant font-normal">Spool install</span>
          </button>
        </div>
      </div>

      {/* Large Voice Action Button (Central SIH26122 interaction) */}
      <button
        onClick={onOpenVoiceModal}
        className="w-full h-14 bg-gradient-to-r from-primary-container to-blue-600 hover:opacity-90 text-white font-bold rounded-xl flex items-center justify-center gap-3 shadow-lg active:scale-98 transition-all"
      >
        <span className="w-9 h-9 rounded-full bg-white/20 flex items-center justify-center">
          <span className="material-symbols-outlined text-[22px]">mic</span>
        </span>
        <span className="text-sm tracking-wide">Record Voice Update (बोलकर रिपोर्ट करें)</span>
      </button>

      {/* Field Actions Grid */}
      <div className="grid grid-cols-2 gap-2 text-xs font-semibold">
        <button
          onClick={() => alert('GPS Camera Active: Geo-tagged photo attached to Line 24.')}
          className="h-11 bg-surface-container hover:bg-surface-container-high border border-surface-container-high rounded-DEFAULT flex items-center justify-center gap-1.5 transition-all active:scale-95"
        >
          <span className="material-symbols-outlined text-[18px] text-primary">add_a_photo</span>
          <span>Attach Photo</span>
        </button>
        <button
          onClick={() => alert('Gang attendance checked: 18/18 present on site.')}
          className="h-11 bg-surface-container hover:bg-surface-container-high border border-surface-container-high rounded-DEFAULT flex items-center justify-center gap-1.5 transition-all active:scale-95"
        >
          <span className="material-symbols-outlined text-[18px] text-tertiary">how_to_reg</span>
          <span>Verify Gang</span>
        </button>
      </div>
    </div>
  );
};
