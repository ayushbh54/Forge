'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Project } from '../types';
import { useWorkspace } from '../context/WorkspaceContext';

interface SidebarProps {
  project?: Project | null;
  activeConflictsCount?: number;
}

export const Sidebar: React.FC<SidebarProps> = ({
  project: propProject,
  activeConflictsCount: propConflictsCount,
}) => {
  const pathname = usePathname();
  const workspace = useWorkspace();
  const {
    currentProject,
    conflicts,
    sidebarCollapsed,
    toggleSidebar,
    user,
    logout,
  } = workspace;

  const project = propProject || currentProject;
  const conflictsCount =
    propConflictsCount !== undefined
      ? propConflictsCount
      : conflicts.filter((c) => c.status === 'OPEN').length;

  const [hoveredNav, setHoveredNav] = useState<string | null>(null);

  const navItems = [
    {
      title: 'Operations Core',
      links: [
        {
          name: 'Project Truth & Triangulation',
          path: '/',
          icon: 'monitoring',
          badge: 'Live',
          badgeColor: 'bg-tertiary-container/30 text-tertiary',
          description: '5-Factor Consensus & Site Telemetry',
        },
        {
          name: 'Schedule-Linking Bridge (SIH)',
          path: '/linking-bridge',
          icon: 'cable',
          badge: 'OIL Core',
          badgeColor: 'bg-primary-container text-white',
          description: 'P6 Activity to Site Observation Bridge',
        },
        {
          name: 'Conflict & Silent Risk Center',
          path: '/conflicts',
          icon: 'warning',
          badge: conflictsCount > 0 ? `${conflictsCount}` : undefined,
          badgeColor: 'bg-error-container text-on-error-container',
          description: 'Tolerance Breaches & Discrepancies',
        },
        {
          name: 'Universal Work ID (UWID)',
          path: '/relationship-map',
          icon: 'hub',
          description: 'Digital Twin Object Relationship Topology',
        },
        {
          name: 'Master Schedule & P6 WBS',
          path: '/schedule',
          icon: 'calendar_month',
          description: 'Interactive Gantt, Floats & Critical Path',
        },
      ],
    },
    {
      title: 'Field Execution & Site Ops',
      links: [
        {
          name: 'Daily Construction Log (DPR)',
          path: '/dpr',
          icon: 'history_edu',
          description: 'Daily Quantities, Delays & Observations',
        },
        {
          name: 'Verified Workforce & Attendance',
          path: '/workforce',
          icon: 'badge',
          description: 'RTK Geofenced Biometric Muster Roll',
        },
        {
          name: 'Materials & Stores (GRN/GIN)',
          path: '/materials',
          icon: 'inventory_2',
          description: 'Pipe Heat Numbers & Weighbridge Slips',
        },
        {
          name: 'Plant, Fleet & Equipment',
          path: '/equipment',
          icon: 'precision_manufacturing',
          description: 'Heavy Earthmovers & Crane Telemetry',
        },
      ],
    },
    {
      title: 'Governance & Assurance',
      links: [
        {
          name: 'QA/QC & Lab Testing (ASTM/ISO)',
          path: '/quality-hse',
          icon: 'fact_check',
          description: 'Radiography AUT & Concrete Cube Breaks',
        },
        {
          name: 'CDE Documents & Translation',
          path: '/documents',
          icon: 'folder_managed',
          description: 'Engineering Drawings & Voice Transcripts',
        },
        {
          name: 'Central Approval Matrix',
          path: '/approvals',
          icon: 'rule',
          badge: '4',
          badgeColor: 'bg-surface-container-high text-on-surface-variant',
          description: 'FIDIC Engineer & Client Sign-offs',
        },
        {
          name: 'Tamper-Proof Audit Trail',
          path: '/audit',
          icon: 'verified_user',
          description: 'SHA-256 SQLite Deterministic Ledger',
        },
      ],
    },
  ];

  return (
    <aside
      className={`fixed left-0 top-0 h-full bg-[#0B1326] z-50 flex flex-col justify-between border-r border-surface-container-high/70 select-none transition-all duration-300 ease-in-out ${
        sidebarCollapsed ? 'w-[72px]' : 'w-72'
      }`}
    >
      <div className="flex flex-col h-full overflow-hidden">
        {/* Brand Header */}
        <div className="h-16 px-4 flex items-center justify-between bg-surface-container-low border-b border-surface-container-high/80">
          {!sidebarCollapsed ? (
            <div className="flex items-center gap-3 min-w-0">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-primary via-primary-container to-blue-700 flex items-center justify-center text-white font-black text-sm shadow-md">
                N
              </div>
              <div className="flex flex-col min-w-0">
                <span className="font-extrabold text-[14px] text-white truncate tracking-tight">
                  Nirmaan OS
                </span>
                <span className="text-[10px] text-on-surface-variant truncate uppercase tracking-widest font-mono">
                  OIL · P6 Bridge v4.2
                </span>
              </div>
            </div>
          ) : (
            <div className="w-full flex justify-center">
              <div
                onClick={toggleSidebar}
                className="w-9 h-9 rounded-lg bg-primary/20 border border-primary/40 flex items-center justify-center text-primary font-black text-sm cursor-pointer hover:bg-primary/30 transition-colors"
                title="Expand Sidebar"
              >
                N
              </div>
            </div>
          )}

          {/* Toggle Sidebar Button */}
          {!sidebarCollapsed && (
            <button
              onClick={toggleSidebar}
              className="w-7 h-7 rounded-md bg-surface-container hover:bg-surface-container-high text-on-surface-variant hover:text-white flex items-center justify-center transition-colors border border-surface-container-high"
              title="Collapse Sidebar"
            >
              <span className="material-symbols-outlined text-[18px]">
                chevron_left
              </span>
            </button>
          )}
        </div>

        {/* Active Project Switcher Card (Only when expanded) */}
        {!sidebarCollapsed && project && (
          <div className="p-3 bg-surface-container-lowest mx-3 my-3 rounded-lg border border-surface-container-high/80 shadow-sm animate-fade-in">
            <div className="flex items-center justify-between">
              <span className="text-[10px] text-on-surface-variant uppercase font-bold tracking-wider">
                Active Project
              </span>
              <span className="font-mono text-[10px] text-primary font-bold bg-primary/10 px-1.5 py-0.5 rounded">
                {project.id}
              </span>
            </div>
            <div className="flex items-center justify-between mt-1">
              <span
                className="font-bold text-[12px] text-white truncate"
                title={project.name}
              >
                {project.name}
              </span>
            </div>
            <div className="mt-2 flex items-center justify-between gap-1 text-[10px]">
              <span className="px-1.5 py-0.5 rounded bg-secondary/15 text-secondary border border-secondary/20 font-semibold truncate max-w-[120px]">
                {project.contractType}
              </span>
              <span className="text-tertiary font-mono font-bold">
                SPI {project.spi} · CPI {project.cpi}
              </span>
            </div>
          </div>
        )}

        {/* Nav Links Container */}
        <div className="flex-1 overflow-y-auto px-2 py-3 space-y-4">
          {navItems.map((section, idx) => (
            <div key={idx} className="flex flex-col gap-1">
              {!sidebarCollapsed && (
                <span className="px-3 py-1 text-[9px] uppercase font-extrabold text-on-surface-variant/60 tracking-wider">
                  {section.title}
                </span>
              )}

              <nav className="flex flex-col gap-1">
                {section.links.map((link) => {
                  const isActive = pathname === link.path;
                  return (
                    <div
                      key={link.path}
                      className="relative"
                      onMouseEnter={() => setHoveredNav(link.path)}
                      onMouseLeave={() => setHoveredNav(null)}
                    >
                      <Link
                        href={link.path}
                        className={`flex items-center rounded-lg transition-all ${
                          sidebarCollapsed
                            ? 'w-11 h-11 mx-auto justify-center'
                            : 'px-3 py-2 justify-between'
                        } ${
                          isActive
                            ? 'bg-primary-container text-white font-bold shadow-md shadow-primary-container/20'
                            : 'text-on-surface-variant hover:bg-surface-container hover:text-white'
                        }`}
                      >
                        <div className="flex items-center gap-3 min-w-0">
                          <span
                            className={`material-symbols-outlined text-[20px] transition-transform duration-200 ${
                              isActive
                                ? 'text-white scale-110'
                                : 'text-primary'
                            }`}
                          >
                            {link.icon}
                          </span>
                          {!sidebarCollapsed && (
                            <span className="text-[12px] truncate">
                              {link.name}
                            </span>
                          )}
                        </div>

                        {!sidebarCollapsed && link.badge && (
                          <span
                            className={`px-1.5 py-0.5 rounded-full font-mono text-[9px] font-bold ${
                              link.badgeColor || 'bg-surface-container text-on-surface'
                            }`}
                          >
                            {link.badge}
                          </span>
                        )}

                        {/* Collapsed active pill indicator */}
                        {sidebarCollapsed && isActive && (
                          <span className="absolute left-0 top-2 bottom-2 w-1 rounded-r-full bg-white" />
                        )}

                        {/* Collapsed badge dot */}
                        {sidebarCollapsed && link.badge && (
                          <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-error ring-2 ring-[#0B1326]" />
                        )}
                      </Link>

                      {/* Tooltip on Collapsed Hover (Instagram / Facebook Style) */}
                      {sidebarCollapsed && hoveredNav === link.path && (
                        <div className="fixed left-[78px] z-50 px-3 py-2 bg-surface-container-high text-white text-xs rounded-lg shadow-xl border border-surface-container-highest pointer-events-none min-w-[180px] animate-fade-in">
                          <div className="flex items-center justify-between gap-2">
                            <span className="font-bold text-[12px] text-white">
                              {link.name}
                            </span>
                            {link.badge && (
                              <span className="px-1.5 py-0.5 rounded text-[9px] font-mono font-bold bg-primary/20 text-primary">
                                {link.badge}
                              </span>
                            )}
                          </div>
                          {link.description && (
                            <p className="text-[10px] text-on-surface-variant mt-0.5">
                              {link.description}
                            </p>
                          )}
                        </div>
                      )}
                    </div>
                  );
                })}
              </nav>
            </div>
          ))}
        </div>

        {/* Sidebar Footer with User Avatar & Expand Button */}
        <div className="p-3 bg-surface-container-lowest border-t border-surface-container-high/60 flex flex-col gap-2">
          {!sidebarCollapsed ? (
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-2 min-w-0">
                <div className="w-8 h-8 rounded-full bg-primary/20 border border-primary/40 flex items-center justify-center text-primary font-bold text-xs uppercase">
                  {user.name.split(' ').map((n) => n[0]).join('').slice(0, 2) || 'US'}
                </div>
                <div className="flex flex-col min-w-0">
                  <span className="text-[11px] font-bold text-white truncate">
                    {user.name}
                  </span>
                  <span className="text-[9px] text-primary truncate uppercase font-mono">
                    {user.role}
                  </span>
                </div>
              </div>

              <button
                onClick={logout}
                className="w-7 h-7 rounded hover:bg-surface-container text-on-surface-variant hover:text-error flex items-center justify-center transition-colors"
                title="Sign Out / Switch User"
              >
                <span className="material-symbols-outlined text-[16px]">
                  logout
                </span>
              </button>
            </div>
          ) : (
            <div className="flex flex-col items-center gap-2">
              <button
                onClick={toggleSidebar}
                className="w-9 h-9 rounded-lg hover:bg-surface-container text-on-surface-variant hover:text-white flex items-center justify-center transition-colors border border-transparent hover:border-surface-container-high"
                title="Expand Navigation (Click or Ctrl+\)"
              >
                <span className="material-symbols-outlined text-[19px]">
                  chevron_right
                </span>
              </button>

              <div
                onClick={logout}
                className="w-8 h-8 rounded-full bg-primary/20 border border-primary/40 flex items-center justify-center text-primary font-bold text-xs cursor-pointer hover:border-error hover:text-error transition-colors"
                title={`Signed in as ${user.name} (${user.role}). Click to Logout.`}
              >
                {user.name.split(' ').map((n) => n[0]).join('').slice(0, 2) || 'US'}
              </div>
            </div>
          )}
        </div>
      </div>
    </aside>
  );
};
