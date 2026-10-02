'use client';

import React from 'react';
import { UserProfile, Project } from '../types';
import { useWorkspace } from '../context/WorkspaceContext';

interface HeaderProps {
  user: UserProfile;
  project: Project;
  onOpenVoiceModal: () => void;
  onOpenGeminiBrain?: () => void;
  onOpenRoleSwitcher?: () => void;
  isMobileHUD: boolean;
  onToggleMobileHUD: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  user,
  project,
  onOpenVoiceModal,
  onOpenGeminiBrain,
  onOpenRoleSwitcher,
  isMobileHUD,
  onToggleMobileHUD,
}) => {
  const { sidebarCollapsed, toggleSidebar, logout } = useWorkspace();

  const userInitials =
    user.name
      .split(' ')
      .map((part) => part[0])
      .join('')
      .slice(0, 2)
      .toUpperCase() || 'US';

  return (
    <header
      className={`fixed top-0 right-0 h-16 bg-[#0B1326]/95 backdrop-blur-md z-40 flex items-center justify-between px-4 sm:px-6 border-b border-surface-container-high/70 transition-all duration-300 ease-in-out shadow-sm ${
        sidebarCollapsed ? 'left-[72px]' : 'left-72'
      }`}
    >
      {/* Left Breadcrumb & Status */}
      <div className="flex items-center gap-3 min-w-0">
        {/* Toggle button on small screens or when collapsed */}
        <button
          onClick={toggleSidebar}
          className="w-8 h-8 rounded-lg bg-surface-container hover:bg-surface-container-high border border-surface-container-high flex items-center justify-center text-on-surface-variant hover:text-white transition-colors"
          title="Toggle Navigation Bar"
        >
          <span className="material-symbols-outlined text-[19px]">
            {sidebarCollapsed ? 'menu' : 'menu_open'}
          </span>
        </button>

        <div className="flex items-center gap-1.5 text-on-surface-variant text-[12px] truncate">
          <span className="truncate hidden md:inline text-on-surface-variant font-medium">
            Oil India Infrastructure
          </span>
          <span className="material-symbols-outlined text-[14px] text-outline hidden md:inline">
            chevron_right
          </span>
          <span className="font-mono text-white font-bold truncate bg-surface-container px-2 py-0.5 rounded border border-surface-container-high text-xs">
            {project.code}
          </span>
          <span className="material-symbols-outlined text-[14px] text-outline">
            chevron_right
          </span>
          <span className="text-primary font-bold truncate text-xs sm:text-sm">
            {user.role} Cockpit
          </span>
        </div>

        <div className="hidden 2xl:flex items-center gap-1.5 px-2.5 py-1 bg-surface-container-lowest rounded-full border border-surface-container-high text-[11px] font-mono">
          <span className="w-1.5 h-1.5 rounded-full bg-tertiary animate-pulse" />
          <span className="text-on-surface-variant">RTK Base Active (Assam)</span>
        </div>
      </div>

      {/* Right Action Bar */}
      <div className="flex items-center gap-2 sm:gap-3">
        {/* Voice Update CTA (SIH26122 core) */}
        <button
          onClick={onOpenVoiceModal}
          className="h-8 sm:h-9 px-2.5 sm:px-3.5 bg-primary-container hover:bg-blue-600 text-white font-bold text-xs rounded-lg flex items-center gap-1.5 transition-all shadow-sm active:scale-95"
          title="Record Site Observation via Voice (Hindi/Assamese/English)"
        >
          <span className="material-symbols-outlined text-[18px]">mic</span>
          <span className="hidden sm:inline">Voice DPR</span>
        </button>

        {/* Gemini AI Autonomous Brain */}
        {onOpenGeminiBrain && (
          <button
            onClick={onOpenGeminiBrain}
            className="h-8 sm:h-9 px-2.5 sm:px-3 bg-gradient-to-r from-primary/15 via-tertiary/15 to-blue-500/10 hover:from-primary/25 hover:to-tertiary/25 text-white font-bold text-xs rounded-lg flex items-center gap-1.5 transition-all border border-tertiary/30 shadow-sm active:scale-95"
            title="Open Gemini Multi-Agent Autonomous Brain"
          >
            <span className="material-symbols-outlined text-[18px] text-tertiary">
              psychology
            </span>
            <span className="hidden md:inline">Gemini AI</span>
            <span className="w-1.5 h-1.5 rounded-full bg-tertiary animate-pulse" />
          </button>
        )}

        {/* Mobile / Field Viewport toggle */}
        <button
          onClick={onToggleMobileHUD}
          className={`h-8 sm:h-9 px-2.5 rounded-lg flex items-center gap-1.5 text-xs font-semibold border transition-all ${
            isMobileHUD
              ? 'bg-secondary/20 text-secondary border-secondary/40'
              : 'bg-surface-container hover:bg-surface-container-high text-on-surface-variant border-surface-container-high'
          }`}
          title="Toggle Mobile Field Mode"
        >
          <span className="material-symbols-outlined text-[17px]">
            {isMobileHUD ? 'smartphone' : 'devices'}
          </span>
          <span className="hidden lg:inline">
            {isMobileHUD ? 'Mobile Mode' : 'Desktop View'}
          </span>
        </button>

        <div className="h-6 w-px bg-surface-container-high mx-0.5 hidden sm:block" />

        {/* User Identity Profile & Switcher */}
        <div className="flex items-center gap-2">
          <div
            onClick={onOpenRoleSwitcher}
            className="flex items-center gap-2 p-1 sm:px-2 sm:py-1 rounded-lg hover:bg-surface-container cursor-pointer transition-colors border border-transparent hover:border-surface-container-high"
            title="Click to Switch Persona or Role"
          >
            <div className="w-7 h-7 sm:w-8 sm:h-8 rounded-lg bg-primary/20 border border-primary/40 flex items-center justify-center text-primary font-bold text-xs uppercase shadow-sm">
              {userInitials}
            </div>
            <div className="hidden xl:flex flex-col text-left">
              <span className="text-[11px] font-bold text-white leading-tight truncate max-w-[120px]">
                {user.name}
              </span>
              <span className="text-[9px] text-primary uppercase font-mono tracking-wider truncate max-w-[120px]">
                {user.role}
              </span>
            </div>
            <span className="material-symbols-outlined text-[16px] text-on-surface-variant hidden sm:inline">
              unfold_more
            </span>
          </div>

          {/* Quick Sign Out / Change Persona */}
          <button
            onClick={logout}
            className="w-8 h-8 rounded-lg bg-surface-container hover:bg-surface-container-high hover:text-error text-on-surface-variant flex items-center justify-center transition-colors border border-surface-container-high"
            title="Sign Out / Switch Identity"
          >
            <span className="material-symbols-outlined text-[17px]">logout</span>
          </button>
        </div>
      </div>
    </header>
  );
};
