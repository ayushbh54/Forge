'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Project } from '../types';

interface SidebarProps {
  project: Project;
  activeConflictsCount: number;
}

export const Sidebar: React.FC<SidebarProps> = ({ project, activeConflictsCount }) => {
  const pathname = usePathname();

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
        },
        {
          name: 'Schedule-Linking Bridge (SIH)',
          path: '/linking-bridge',
          icon: 'cable',
          badge: 'OIL Core',
          badgeColor: 'bg-primary-container text-on-primary-container',
        },
        {
          name: 'Conflict & Silent Risk Center',
          path: '/conflicts',
          icon: 'warning',
          badge: activeConflictsCount > 0 ? `${activeConflictsCount}` : undefined,
          badgeColor: 'bg-secondary-container text-on-secondary-container',
        },
        {
          name: 'Universal Work ID (UWID)',
          path: '/relationship-map',
          icon: 'hub',
        },
        {
          name: 'Master Schedule & P6 WBS',
          path: '/schedule',
          icon: 'calendar_month',
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
        },
        {
          name: 'Verified Workforce & Attendance',
          path: '/workforce',
          icon: 'badge',
        },
        {
          name: 'Materials & Stores (GRN/GIN)',
          path: '/materials',
          icon: 'inventory_2',
        },
        {
          name: 'Plant, Fleet & Equipment',
          path: '/equipment',
          icon: 'precision_manufacturing',
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
        },
        {
          name: 'CDE Documents & Translation',
          path: '/documents',
          icon: 'folder_managed',
        },
        {
          name: 'Central Approval Matrix',
          path: '/approvals',
          icon: 'rule',
          badge: '4',
          badgeColor: 'bg-surface-container-high text-on-surface-variant',
        },
        {
          name: 'Tamper-Proof Audit Trail',
          path: '/audit',
          icon: 'verified_user',
        },
      ],
    },
  ];

  return (
    <aside className="fixed left-0 top-0 h-full w-72 bg-surface-container-low z-50 flex flex-col justify-between overflow-y-auto border-r border-surface-container-high/60 select-none">
      <div className="flex flex-col">
        {/* Brand Header */}
        <div className="h-16 px-space-md flex items-center justify-between bg-surface-container border-b border-surface-container-high/80">
          <div className="flex items-center gap-space-sm min-w-0">
            <div className="w-8 h-8 rounded-DEFAULT bg-primary-container flex items-center justify-center text-on-primary-container font-black shadow-sm tracking-wider">
              N
            </div>
            <div className="flex flex-col min-w-0">
              <span className="font-semibold text-[15px] text-on-surface truncate tracking-tight">Nirmaan OS</span>
              <span className="text-[10px] text-on-surface-variant truncate uppercase tracking-widest font-mono">OIL · P6 Bridge v4.2</span>
            </div>
          </div>
          <span className="w-2.5 h-2.5 rounded-full bg-tertiary animate-radar" title="Active Connection to Site Telemetry"></span>
        </div>

        {/* Active Project Switcher Card (Stitch Exact Pattern) */}
        <div className="p-space-md bg-surface-container-lowest mx-space-sm my-space-sm rounded-DEFAULT border border-surface-container-high/80 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-[11px] text-on-surface-variant uppercase font-semibold tracking-wider">Active Project</span>
            <span className="font-mono text-[11px] text-primary font-bold">{project.id}</span>
          </div>
          <div className="flex items-center justify-between mt-space-xs">
            <span className="font-semibold text-[13px] text-on-surface truncate" title={project.name}>
              {project.name}
            </span>
            <span className="material-symbols-outlined text-on-surface-variant text-[16px] cursor-pointer hover:text-on-surface">unfold_more</span>
          </div>
          <div className="mt-space-sm flex items-center justify-between gap-space-xs">
            <span className="px-space-xs py-0.5 rounded-full bg-secondary/15 text-secondary border border-secondary/20 text-[10px] font-semibold">
              {project.contractType}
            </span>
            <span className="text-[11px] text-tertiary font-mono font-bold">
              SPI: {project.spi} | CPI: {project.cpi}
            </span>
          </div>
        </div>

        {/* Navigation Sections */}
        <div className="flex flex-col gap-3 px-space-sm py-2">
          {navItems.map((section, idx) => (
            <div key={idx} className="flex flex-col gap-1">
              <span className="px-space-md py-1 text-[10px] uppercase font-bold text-on-surface-variant/70 tracking-widest">
                {section.title}
              </span>
              <nav className="flex flex-col gap-0.5">
                {section.links.map(link => {
                  const isActive = pathname === link.path;
                  return (
                    <Link
                      key={link.path}
                      href={link.path}
                      className={`flex items-center justify-between px-space-md py-2 rounded-DEFAULT text-[13px] font-medium transition-all ${
                        isActive
                          ? 'bg-primary-container text-on-primary font-semibold shadow-sm'
                          : 'text-on-surface-variant hover:bg-surface-container hover:text-on-surface'
                      }`}
                    >
                      <div className="flex items-center gap-space-md min-w-0">
                        <span className={`material-symbols-outlined text-[19px] ${isActive ? 'text-on-primary' : 'text-primary'}`}>
                          {link.icon}
                        </span>
                        <span className="truncate">{link.name}</span>
                      </div>
                      {link.badge && (
                        <span className={`px-space-xs py-0.5 rounded-full font-mono text-[10px] font-bold ${link.badgeColor || 'bg-surface-container text-on-surface'}`}>
                          {link.badge}
                        </span>
                      )}
                    </Link>
                  );
                })}
              </nav>
            </div>
          ))}
        </div>
      </div>

      {/* Network Node & System Health Footer */}
      <div className="p-space-sm bg-surface-container-low border-t border-surface-container-high/60 flex flex-col gap-1">
        <div className="px-space-md py-1 flex items-center justify-between text-on-surface-variant text-[11px]">
          <span className="uppercase tracking-wider">OIL Node Assam</span>
          <span className="font-mono text-tertiary font-semibold flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-tertiary"></span>
            RTK Gateway 99.4%
          </span>
        </div>
      </div>
    </aside>
  );
};
