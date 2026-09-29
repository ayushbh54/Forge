'use client';

import React from 'react';
import { UserProfile, Project } from '../types';

interface HeaderProps {
  user: UserProfile;
  project: Project;
  onOpenVoiceModal: () => void;
  onOpenGeminiBrain?: () => void;
  isMobileHUD: boolean;
  onToggleMobileHUD: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  user,
  project,
  onOpenVoiceModal,
  onOpenGeminiBrain,
  isMobileHUD,
  onToggleMobileHUD,
}) => {
  return (
    <header className="fixed top-0 left-72 right-0 h-16 bg-surface/95 backdrop-blur-md z-40 flex items-center justify-between px-space-lg border-b border-surface-container-high/60 shadow-sm">
      {/* Breadcrumb Hierarchy */}
      <div className="flex items-center gap-space-md min-w-0">
        <div className="flex items-center gap-space-xs text-on-surface-variant text-[13px] truncate">
          <span className="truncate text-on-surface-variant font-medium">Oil India Infrastructure</span>
          <span className="material-symbols-outlined text-[15px] text-outline">chevron_right</span>
          <span className="font-mono text-on-surface font-semibold truncate bg-surface-container px-1.5 py-0.5 rounded-sm">
            {project.code}
          </span>
          <span className="material-symbols-outlined text-[15px] text-outline">chevron_right</span>
          <span className="text-primary font-semibold truncate">Execution Matrix</span>
        </div>

        <div className="hidden xl:flex items-center gap-space-xs px-space-sm py-1 bg-surface-container rounded-full border border-surface-container-high/60">
          <span className="w-1.5 h-1.5 rounded-full bg-tertiary"></span>
          <span className="text-[11px] text-on-surface-variant font-mono">
            P6 Baseline v2.4 (Synced 14m ago)
          </span>
        </div>
      </div>

      {/* Right Action Bar */}
      <div className="flex items-center gap-space-md">
        {/* Global Search */}
        <div className="relative hidden md:flex items-center">
          <span className="material-symbols-outlined absolute left-3 text-[17px] text-on-surface-variant">search</span>
          <input
            className="w-56 lg:w-72 h-9 pl-9 pr-space-md bg-surface-container-lowest text-on-surface text-[12px] rounded-DEFAULT border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary placeholder:text-outline-variant transition-all"
            placeholder="Search WBS, Tag, Line 24, Activity..."
            type="text"
          />
        </div>

        {/* SIH26122 Voice Capture CTA */}
        <button
          onClick={onOpenVoiceModal}
          className="h-9 px-space-md bg-primary-container hover:bg-primary-container/80 text-on-primary font-semibold text-[12px] rounded-DEFAULT flex items-center gap-1.5 transition-all shadow-sm active:scale-95"
          title="Record Site Update via Hindi / English Voice"
        >
          <span className="material-symbols-outlined text-[17px] text-white">mic</span>
          <span className="hidden sm:inline">Voice Update</span>
        </button>

        {/* Gemini AI Autonomous Brain CTA */}
        <button
          onClick={onOpenGeminiBrain}
          className="h-9 px-3 bg-gradient-to-r from-primary/20 via-tertiary/20 to-primary/10 hover:from-primary/30 hover:to-tertiary/30 text-on-surface font-semibold text-[12px] rounded-DEFAULT flex items-center gap-1.5 transition-all border border-tertiary/40 shadow-sm active:scale-95"
          title="Open Gemini Autonomous Project Brain"
        >
          <span className="material-symbols-outlined text-[18px] text-tertiary">psychology</span>
          <span className="hidden md:inline font-bold">Gemini Brain</span>
          <span className="w-1.5 h-1.5 rounded-full bg-tertiary animate-pulse"></span>
        </button>

        {/* Viewport Toggle (Desktop Ops Matrix vs Mobile Field View) */}
        <button
          onClick={onToggleMobileHUD}
          className={`h-9 px-3 rounded-DEFAULT flex items-center gap-1.5 text-[12px] font-semibold border transition-all ${
            isMobileHUD 
              ? 'bg-secondary/20 text-secondary border-secondary/40' 
              : 'bg-surface-container hover:bg-surface-container-high text-on-surface-variant border-surface-container-high'
          }`}
          title="Toggle Mobile Field HUD for Site Supervisors"
        >
          <span className="material-symbols-outlined text-[17px]">
            {isMobileHUD ? 'smartphone' : 'desktop_windows'}
          </span>
          <span className="hidden lg:inline">{isMobileHUD ? 'Mobile Field HUD' : 'Desktop Ops'}</span>
        </button>

        {/* Notifications Icon with Badge */}
        <button 
          aria-label="Alerts" 
          className="relative w-9 h-9 flex items-center justify-center rounded-DEFAULT text-on-surface-variant hover:bg-surface-container hover:text-on-surface transition-colors"
        >
          <span className="material-symbols-outlined text-[20px]">notifications</span>
          <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-error"></span>
        </button>

        <div className="h-6 w-px bg-surface-container-highest"></div>

        {/* User Identity Profile */}
        <div className="flex items-center gap-space-sm">
          <div className="w-8 h-8 rounded-full bg-primary/20 border border-primary/40 flex items-center justify-center text-primary font-bold text-xs uppercase">
            MV
          </div>
          <div className="hidden lg:flex flex-col text-left">
            <span className="text-[12px] font-semibold text-on-surface leading-tight truncate">
              {user.name}
            </span>
            <span className="text-[10px] text-primary font-bold uppercase tracking-wider truncate font-mono">
              {user.fidicDesignation}
            </span>
          </div>
        </div>
      </div>
    </header>
  );
};
