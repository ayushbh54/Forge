'use client';

import React, { useState } from 'react';
import { UserProfile, Project } from '../types';
import { useWorkspace } from '../context/WorkspaceContext';

interface UserRoleSwitcherModalProps {
  isOpen: boolean;
  onClose: () => void;
  currentUser?: UserProfile;
  currentProject?: Project;
  onSwitchRole?: (user: UserProfile, project: Project) => void;
}

export const PRESET_ROLES: {
  roleTitle: string;
  name: string;
  category: 'LEADERSHIP' | 'SITE_SUPERVISION' | 'WORKFORCE' | 'CONTROLS' | 'QUALITY_HSE';
  department: string;
  fidicRole: string;
  description: string;
  financialLimit: string;
  viewScope: string[];
  createAuthority: string[];
  approveAuthority: string[];
  editAuthority: string[];
}[] = [
  {
    roleTitle: 'Project Director / PM',
    name: 'Marcus Vance, P.E.',
    category: 'LEADERSHIP',
    department: 'Project Controls & Management',
    fidicRole: "Engineer's Representative (FIDIC 3.1)",
    description: 'Executive project health, FIDIC approvals, SPI/CPI, 5-Factor Project Truth consensus, and dispute governance.',
    financialLimit: '₹50,00,00,000 (₹50 Cr)',
    viewScope: ['Complete Project Financials', 'All Department WBS', 'FIDIC Claims', 'High-level Audit Trail', 'Critical Path Schedule'],
    createAuthority: ['FIDIC Clause 20.1 Claims', 'Subcontractor Agreements', 'Contract Milestones', 'Extension of Time (EOT)'],
    approveAuthority: ['Vendor Invoices (> ₹1 Cr)', 'Baseline Schedule Changes', 'Variation Orders', 'Subcontract Awards'],
    editAuthority: ['Executive Project Target Dates', 'Budget Allocations', 'Contractor JV Agreements'],
  },
  {
    roleTitle: 'Planning & Controls Engineer',
    name: 'Ananya Sen',
    category: 'CONTROLS',
    department: 'Project Controls & Planning',
    fidicRole: 'Scheduler & Delay Analyst (FIDIC 8.3)',
    description: 'Primavera P6 schedule, WBS L1-L6, critical path floats, and baseline variance analysis.',
    financialLimit: '₹25,00,000 (₹25 Lakhs)',
    viewScope: ['Master WBS L1-L6', 'Primavera P6 Schedules', 'EVM Metrics (SPI/CPI)', 'Critical Path Activity Sequences'],
    createAuthority: ['WBS Nodes', 'Baseline Schedules', 'Activity Dependencies', 'Float Variance Reports'],
    approveAuthority: ['Activity Logic Adjustments', 'Milestone Forecast Progress Updates'],
    editAuthority: ['Float Limits', 'Critical Path Logic Links', 'Resource Calendar Allocations'],
  },
  {
    roleTitle: 'Site Operations Supervisor',
    name: 'Vikram Joshi',
    category: 'SITE_SUPERVISION',
    department: 'Field Operations & Construction',
    fidicRole: 'Section In-Charge (FIDIC 7.3)',
    description: 'Voice DPR updates, gang supervision, shift logs, well sinking, pier cap pours, and stores material requisitions.',
    financialLimit: '₹5,00,000 (₹5 Lakhs)',
    viewScope: ['Assigned Site Zones (Piers P1-P24)', 'Shift DPRs', 'Material Allocations', 'Plant Machinery'],
    createAuthority: ['Daily Progress Reports (DPR)', 'Site Incident Log', 'Equipment Breakdown Reports', 'Shift Gang Notes'],
    approveAuthority: ['Daily Gang Muster Roll', 'Shift Activity Completion', 'Stores Material Issue Slips'],
    editAuthority: ['DPR Field Quantities', 'Weather Interruption Hours', 'Site Remarks'],
  },
  {
    roleTitle: 'QA/QC Lead Inspector',
    name: 'R. K. Sharma',
    category: 'QUALITY_HSE',
    department: 'Quality Assurance & Inspection',
    fidicRole: 'Quality Testing Authority (FIDIC 7.4)',
    description: 'Radiography NDT sign-offs, ASTM C39 concrete cube breaks, NCRs, and ITP inspections.',
    financialLimit: '₹0 (Independent Quality Authority)',
    viewScope: ['Material Test Reports (MTR)', 'Welding Radiography (RT)', 'Concrete Slump Tests', 'Inspection Hold Points'],
    createAuthority: ['Non-Conformance Reports (NCR)', 'Inspection Requests (IR)', 'Hydrostatic Test Logs'],
    approveAuthority: ['Hold Point Releases', '28-Day Cube Compressive Certificates', 'NABL Lab Reports'],
    editAuthority: ['Quality Checklists', 'Inspection Notes', 'Punch Lists'],
  },
  {
    roleTitle: 'HSE & Safety Lead',
    name: 'Kavita Nair',
    category: 'QUALITY_HSE',
    department: 'Health, Safety & Environment (HSE)',
    fidicRole: 'Safety Compliance Officer (FIDIC 4.8)',
    description: 'Hot work and confined space PTW authorization, atmospheric gas checks, zero-harm audits, and TBT briefings.',
    financialLimit: '₹10,00,000 (Safety Emergency)',
    viewScope: ['Safety Induction Registry', 'Atmospheric Gas Checks', 'Hazardous Work Zones', 'Incident Records'],
    createAuthority: ['Permit-to-Work (PTW)', 'Stop Work Hazard Orders', 'Emergency Evacuation Logs'],
    approveAuthority: ['Daily PTW Authorizations', 'Tool-Box Talk (TBT) Sign-offs', 'PPE Compliance Clearances'],
    editAuthority: ['Safety Risk Assessments', 'Gas Level Recordings', 'Incident Classifications'],
  },
  {
    roleTitle: 'Stores & Materials Controller',
    name: 'Pranab Deka',
    category: 'SITE_SUPERVISION',
    department: 'Stores & Materials Management',
    fidicRole: 'Material Controller (FIDIC 5.2)',
    description: 'Goods Receipt Notes (GRN), Goods Issue Notes (GIN), and line pipe / spool shortage management.',
    financialLimit: '₹50,00,000 (₹50 Lakhs)',
    viewScope: ['Warehouse Bin Cards', 'Goods Receipt Notes (GRN)', 'Rebar & Cement Consignments', 'Pipe Stacks'],
    createAuthority: ['Goods Receipt Notes (GRN)', 'Goods Issue Notes (GIN)', 'Material Return Vouchers'],
    approveAuthority: ['Material Dispatches to Authorized Site Supervisors', 'Physical Inventory Counts'],
    editAuthority: ['Stock Yard Storage Locations', 'Heat Number Tags', 'Unit Costs'],
  },
  {
    roleTitle: 'Labour Gang Foreman',
    name: 'Tapan Das',
    category: 'WORKFORCE',
    department: 'Field Workforce Gang',
    fidicRole: 'Certified Tradesperson (API 1104)',
    description: 'Digital Labour ID, GPS biometric attendance, task assignments, and safety induction record.',
    financialLimit: '₹0',
    viewScope: ['Assigned Trade Workers', 'Daily Shift Gang Allocation', 'Task Target Locations'],
    createAuthority: ['Shift Gang Labour Log', 'Digital Attendance Self-Declaration'],
    approveAuthority: ['Trade Peer Verification'],
    editAuthority: ['None (Read/Submit Only)'],
  },
];

export const DEPARTMENTS = [
  'Piping & Pipeline Engineering',
  'Civil & Structural Engineering',
  'Mechanical & Rotating Equipment',
  'Electrical & Instrumentation',
  'Quality Assurance & Inspection (QA/QC)',
  'Health, Safety & Environment (HSE)',
  'Project Controls & Planning',
  'Stores & Materials Management',
  'Field Operations & Workforce',
];

export const TRADES = [
  '6G Pipe Welder (TIG/MIG)',
  'Structural Steel Erector',
  'Pipe Fitter / Fabricator',
  'Heavy Crane / Rigging Operator',
  'Civil Barbender / Mason',
  'Scaffolding Inspector',
  'Electrical Technician',
  'Hydrotest Technician',
  'General Construction Tradesperson',
];

export const UserRoleSwitcherModal: React.FC<UserRoleSwitcherModalProps> = ({
  isOpen,
  onClose,
  currentUser,
  currentProject,
  onSwitchRole,
}) => {
  const workspace = useWorkspace();
  const activeUser = currentUser || workspace.user;
  const activeProject = currentProject || workspace.currentProject;

  const [activeTab, setActiveTab] = useState<'REGISTER' | 'PRESET' | 'AUTHORITY'>('AUTHORITY');

  // Quick Switch state
  const [selectedPreset, setSelectedPreset] = useState(PRESET_ROLES[0]);
  const [selectedAuthorityRole, setSelectedAuthorityRole] = useState(PRESET_ROLES[0]);
  const [projectIdInput, setProjectIdInput] = useState(activeProject?.id || 'PRJ-BRG-2026');
  const [projectNameInput, setProjectNameInput] = useState(activeProject?.name || 'Brahmaputra Multi-Span Cable-Stayed Bridge Package II (2-Year Project)');

  // Registration state
  const [regName, setRegName] = useState('');
  const [regPhone, setRegPhone] = useState('');
  const [regRole, setRegRole] = useState('Labour / Skilled Tradesperson');
  const [regDepartment, setRegDepartment] = useState(DEPARTMENTS[0]);
  const [regProjectId, setRegProjectId] = useState(activeProject?.id || 'PRJ-BRG-2026');
  const [regBadgeNumber, setRegBadgeNumber] = useState(`LAB-${Math.floor(1000 + Math.random() * 9000)}`);
  const [regTrade, setRegTrade] = useState(TRADES[0]);
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (!isOpen) return null;

  // Handle Quick Switch
  const handleApplyPreset = (presetToApply = selectedPreset) => {
    const updatedUser: UserProfile = {
      ...activeUser,
      name: presetToApply.name,
      role: presetToApply.roleTitle,
      discipline: presetToApply.department,
      currentProjectRole: presetToApply.roleTitle,
      fidicDesignation: presetToApply.fidicRole,
    };

    const isBridgeProject = projectIdInput.includes('BRG');
    const targetProject: Project = {
      id: projectIdInput.toUpperCase(),
      code: projectIdInput.toUpperCase(),
      name: projectNameInput || `Project ${projectIdInput.toUpperCase()}`,
      client: isBridgeProject ? 'NHAI / Ministry of Road Transport' : (activeProject?.client || 'Project Client'),
      contractorJV: isBridgeProject ? 'L&T - Daewoo JV' : (activeProject?.contractorJV || 'Consortium JV'),
      contractType: isBridgeProject ? 'FIDIC Yellow Book Design-Build' : (activeProject?.contractType || 'FIDIC Red Book'),
      lifecycle: 'EXECUTION',
      location: isBridgeProject ? 'Brahmaputra River Corridor (Assam)' : (activeProject?.location || 'Site Location'),
      budget: isBridgeProject ? 34500000000 : (activeProject?.budget || 100000000),
      currency: 'INR (₹)',
      startDate: '2024-04-01',
      plannedFinishDate: '2026-03-31',
      spi: 0.94,
      cpi: 0.98,
      evidenceCoverage: 88.5,
      telemetryFreshness: 94,
      status: 'ON_TRACK',
    };

    if (onSwitchRole) {
      onSwitchRole(updatedUser, targetProject);
    } else {
      workspace.switchUserRole(updatedUser, targetProject);
    }
    onClose();
  };

  const handleRegisterAndConnect = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!regName.trim() || !regProjectId.trim()) {
      alert('Please enter your Name and Project Unique ID');
      return;
    }

    setIsSubmitting(true);
    const success = await workspace.registerAndConnect({
      name: regName.trim(),
      phone: regPhone.trim(),
      role: regRole,
      department: regDepartment,
      projectId: regProjectId.trim().toUpperCase(),
      badgeNumber: regRole.toLowerCase().includes('labour') ? regBadgeNumber : undefined,
      trade: regRole.toLowerCase().includes('labour') ? regTrade : undefined,
    });

    setIsSubmitting(false);
    if (success) {
      onClose();
    }
  };

  const isLabourSelected = regRole.toLowerCase().includes('labour');

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-background/85 backdrop-blur-md animate-fade-in">
      <div className="w-full max-w-3xl bg-surface-container-lowest border border-surface-container-high rounded-xl shadow-2xl overflow-hidden flex flex-col">
        {/* Header */}
        <div className="p-4 bg-surface-container flex items-center justify-between border-b border-surface-container-high">
          <div className="flex items-center gap-2.5">
            <span className="w-8 h-8 rounded-DEFAULT bg-primary-container flex items-center justify-center text-white">
              <span className="material-symbols-outlined text-[19px]">admin_panel_settings</span>
            </span>
            <div>
              <h2 className="font-bold text-sm text-on-surface">Department & Role Authority Matrix (RBAC Engine)</h2>
              <p className="text-[11px] text-on-surface-variant font-mono">
                Enforcing View Scopes, Creation Rights, Approvals & Financial Limits Across Projects
              </p>
            </div>
          </div>
          <button 
            onClick={onClose}
            className="w-8 h-8 flex items-center justify-center text-on-surface-variant hover:text-on-surface rounded-DEFAULT hover:bg-surface-container-high transition-colors"
          >
            <span className="material-symbols-outlined text-[18px]">close</span>
          </button>
        </div>

        {/* Tab Toggle */}
        <div className="flex border-b border-surface-container-high bg-surface-container-low px-5 pt-2 gap-4 text-xs font-bold">
          <button
            type="button"
            onClick={() => setActiveTab('AUTHORITY')}
            className={`pb-2.5 border-b-2 flex items-center gap-1.5 transition-all ${
              activeTab === 'AUTHORITY'
                ? 'border-primary text-primary'
                : 'border-transparent text-on-surface-variant hover:text-on-surface'
            }`}
          >
            <span className="material-symbols-outlined text-[16px]">security</span>
            <span>Department & Role Authority Matrix</span>
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('PRESET')}
            className={`pb-2.5 border-b-2 flex items-center gap-1.5 transition-all ${
              activeTab === 'PRESET'
                ? 'border-primary text-primary'
                : 'border-transparent text-on-surface-variant hover:text-on-surface'
            }`}
          >
            <span className="material-symbols-outlined text-[16px]">swap_horiz</span>
            <span>Quick Switch Persona</span>
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('REGISTER')}
            className={`pb-2.5 border-b-2 flex items-center gap-1.5 transition-all ${
              activeTab === 'REGISTER'
                ? 'border-primary text-primary'
                : 'border-transparent text-on-surface-variant hover:text-on-surface'
            }`}
          >
            <span className="material-symbols-outlined text-[16px]">person_add</span>
            <span>Register & Connect</span>
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-5 max-h-[75vh] overflow-y-auto">
          {/* TAB 1: AUTHORITY MATRIX */}
          {activeTab === 'AUTHORITY' && (
            <div className="flex flex-col gap-4 animate-fade-in">
              {/* Project Archetype Quick Switch */}
              <div className="p-3 bg-surface-container-low rounded-xl border border-surface-container-high flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="material-symbols-outlined text-primary text-[20px]">account_tree</span>
                  <div>
                    <span className="text-xs font-bold text-white block">2-Year River Bridge Construction (PRJ-BRG-2026)</span>
                    <span className="text-[10px] text-on-surface-variant font-mono">₹3,450 Cr • 24-Month Project • FIDIC Yellow Book</span>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => {
                    setProjectIdInput('PRJ-BRG-2026');
                    setProjectNameInput('Brahmaputra Multi-Span Cable-Stayed Bridge Package II (2-Year Project)');
                  }}
                  className="px-2.5 py-1 rounded bg-primary/20 text-primary border border-primary/30 text-[10px] font-bold font-mono hover:bg-primary/30 transition-colors"
                >
                  Select Bridge Project
                </button>
              </div>

              {/* Horizontal Role Selector */}
              <div className="flex gap-2 overflow-x-auto pb-1">
                {PRESET_ROLES.map((role, idx) => {
                  const isSelected = selectedAuthorityRole.roleTitle === role.roleTitle;
                  return (
                    <button
                      key={idx}
                      type="button"
                      onClick={() => setSelectedAuthorityRole(role)}
                      className={`px-3 py-1.5 rounded-lg text-xs font-bold whitespace-nowrap transition-all border ${
                        isSelected
                          ? 'bg-primary text-white border-primary shadow-sm'
                          : 'bg-surface-container hover:bg-surface-container-high text-on-surface-variant border-surface-container-high'
                      }`}
                    >
                      {role.roleTitle}
                    </button>
                  );
                })}
              </div>

              {/* Active Role Detailed Authority Card */}
              <div className="p-4 bg-surface-container-low rounded-xl border border-surface-container-high flex flex-col gap-3">
                <div className="flex flex-wrap items-center justify-between gap-2 border-b border-surface-container-high/60 pb-3">
                  <div>
                    <h3 className="text-sm font-bold text-white">{selectedAuthorityRole.roleTitle}</h3>
                    <span className="text-xs text-primary font-medium">{selectedAuthorityRole.department}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="px-2 py-0.5 rounded bg-tertiary/20 text-tertiary text-[10px] font-mono font-bold">
                      {selectedAuthorityRole.fidicRole}
                    </span>
                    <span className="px-2 py-0.5 rounded bg-primary/20 text-primary text-[10px] font-mono font-bold">
                      Limit: {selectedAuthorityRole.financialLimit}
                    </span>
                  </div>
                </div>

                {/* 4 Authority Grid Cards */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                  {/* View Scope */}
                  <div className="p-3 bg-surface-container rounded-lg border border-surface-container-high flex flex-col gap-1.5">
                    <div className="flex items-center gap-1.5 text-primary font-bold">
                      <span className="material-symbols-outlined text-[16px]">visibility</span>
                      <span>View Scope (Kya Visible Rahega)</span>
                    </div>
                    <ul className="list-disc list-inside text-on-surface-variant text-[11px] space-y-1">
                      {selectedAuthorityRole.viewScope.map((item, i) => (
                        <li key={i}>{item}</li>
                      ))}
                    </ul>
                  </div>

                  {/* Creation Rights */}
                  <div className="p-3 bg-surface-container rounded-lg border border-surface-container-high flex flex-col gap-1.5">
                    <div className="flex items-center gap-1.5 text-tertiary font-bold">
                      <span className="material-symbols-outlined text-[16px]">add_circle</span>
                      <span>Creation Rights (Kya Create Kar Sakte Hai)</span>
                    </div>
                    <ul className="list-disc list-inside text-on-surface-variant text-[11px] space-y-1">
                      {selectedAuthorityRole.createAuthority.map((item, i) => (
                        <li key={i}>{item}</li>
                      ))}
                    </ul>
                  </div>

                  {/* Approval Rights */}
                  <div className="p-3 bg-surface-container rounded-lg border border-surface-container-high flex flex-col gap-1.5">
                    <div className="flex items-center gap-1.5 text-blue-400 font-bold">
                      <span className="material-symbols-outlined text-[16px]">verified</span>
                      <span>Approval Rights (Kya Approve Kar Sakte Hai)</span>
                    </div>
                    <ul className="list-disc list-inside text-on-surface-variant text-[11px] space-y-1">
                      {selectedAuthorityRole.approveAuthority.map((item, i) => (
                        <li key={i}>{item}</li>
                      ))}
                    </ul>
                  </div>

                  {/* Edit Authority */}
                  <div className="p-3 bg-surface-container rounded-lg border border-surface-container-high flex flex-col gap-1.5">
                    <div className="flex items-center gap-1.5 text-amber-400 font-bold">
                      <span className="material-symbols-outlined text-[16px]">edit_note</span>
                      <span>Modification Limits (Kya Changes Kar Sakte Hai)</span>
                    </div>
                    <ul className="list-disc list-inside text-on-surface-variant text-[11px] space-y-1">
                      {selectedAuthorityRole.editAuthority.map((item, i) => (
                        <li key={i}>{item}</li>
                      ))}
                    </ul>
                  </div>
                </div>

                <div className="flex justify-end pt-2 border-t border-surface-container-high/60">
                  <button
                    type="button"
                    onClick={() => handleApplyPreset(selectedAuthorityRole)}
                    className="px-5 py-2 bg-primary hover:bg-primary-container text-white font-bold text-xs rounded-lg shadow-sm flex items-center gap-1.5"
                  >
                    <span className="material-symbols-outlined text-[16px]">login</span>
                    <span>Switch to {selectedAuthorityRole.roleTitle}</span>
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: PRESETS */}
          {activeTab === 'PRESET' && (
            <div className="flex flex-col gap-4 animate-fade-in">
              <div className="p-3 bg-surface-container-low rounded-DEFAULT border border-surface-container-high flex flex-col gap-2">
                <span className="text-[11px] uppercase font-bold text-primary font-mono flex items-center gap-1">
                  <span className="material-symbols-outlined text-[15px]">apartment</span>
                  Connect to Project Workspace
                </span>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 text-xs">
                  <div>
                    <label className="text-[10px] text-on-surface-variant font-bold uppercase block mb-1">Project Unique ID</label>
                    <input
                      type="text"
                      value={projectIdInput}
                      onChange={(e) => setProjectIdInput(e.target.value.toUpperCase())}
                      className="w-full p-2 bg-surface-container text-on-surface font-mono font-bold text-xs rounded-sm border border-surface-container-high uppercase"
                    />
                  </div>
                  <div className="sm:col-span-2">
                    <label className="text-[10px] text-on-surface-variant font-bold uppercase block mb-1">Project Scope</label>
                    <input
                      type="text"
                      value={projectNameInput}
                      onChange={(e) => setProjectNameInput(e.target.value)}
                      className="w-full p-2 bg-surface-container text-on-surface text-xs rounded-sm border border-surface-container-high"
                    />
                  </div>
                </div>
              </div>

              <div className="flex flex-col gap-2">
                <span className="text-[11px] uppercase font-bold text-on-surface-variant font-mono">
                  Select Active Role Persona
                </span>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                  {PRESET_ROLES.map((r, idx) => {
                    const isSelected = selectedPreset.roleTitle === r.roleTitle;
                    return (
                      <div
                        key={idx}
                        onClick={() => setSelectedPreset(r)}
                        className={`p-3 rounded-DEFAULT border cursor-pointer transition-all flex flex-col justify-between ${
                          isSelected
                            ? 'border-primary bg-primary/10 shadow-sm'
                            : 'border-surface-container-high bg-surface-container-low hover:bg-surface-container'
                        }`}
                      >
                        <div>
                          <div className="flex items-center justify-between mb-1">
                            <span className="font-bold text-xs text-on-surface">{r.roleTitle}</span>
                            <span className="font-mono text-[9px] uppercase font-bold px-1.5 py-0.5 rounded-sm bg-surface-container text-on-surface-variant">
                              {r.category}
                            </span>
                          </div>
                          <span className="text-[11px] text-primary font-semibold block">{r.name}</span>
                          <p className="text-[10px] text-on-surface-variant mt-1 leading-snug">{r.description}</p>
                        </div>
                        <span className="text-[10px] font-mono text-tertiary mt-2 block truncate">
                          {r.fidicRole}
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>

              <div className="flex justify-end gap-2 pt-3 border-t border-surface-container-high">
                <button
                  type="button"
                  onClick={onClose}
                  className="px-4 py-2 bg-surface-container hover:bg-surface-container-high text-on-surface text-xs rounded-sm"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  onClick={() => handleApplyPreset()}
                  className="px-6 py-2 bg-primary hover:bg-primary-container text-on-primary font-bold text-xs rounded-sm shadow-sm flex items-center gap-1.5"
                >
                  <span className="material-symbols-outlined text-[16px]">switch_account</span>
                  <span>Switch Persona & Enter Workspace</span>
                </button>
              </div>
            </div>
          )}

          {/* TAB 3: REGISTER */}
          {activeTab === 'REGISTER' && (
            <form onSubmit={handleRegisterAndConnect} className="flex flex-col gap-4 animate-fade-in">
              <div className="p-3 bg-surface-container-low rounded-DEFAULT border border-surface-container-high text-xs text-on-surface-variant flex items-start gap-2">
                <span className="material-symbols-outlined text-primary text-[18px] shrink-0 mt-0.5">verified_user</span>
                <span>
                  Registering connects your device and authority credentials to the project data store.
                </span>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                <div>
                  <label className="text-[10px] uppercase font-bold text-on-surface-variant block mb-1">Full Name *</label>
                  <input
                    type="text"
                    required
                    value={regName}
                    onChange={(e) => setRegName(e.target.value)}
                    placeholder="e.g. Vikram Joshi"
                    className="w-full p-2 bg-surface-container text-on-surface text-xs rounded-sm border border-surface-container-high"
                  />
                </div>
                <div>
                  <label className="text-[10px] uppercase font-bold text-on-surface-variant block mb-1">Mobile / WhatsApp</label>
                  <input
                    type="tel"
                    value={regPhone}
                    onChange={(e) => setRegPhone(e.target.value)}
                    placeholder="+91 98765 43210"
                    className="w-full p-2 bg-surface-container text-on-surface text-xs rounded-sm border border-surface-container-high"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                <div>
                  <label className="text-[10px] uppercase font-bold text-on-surface-variant block mb-1">Department</label>
                  <select
                    value={regDepartment}
                    onChange={(e) => setRegDepartment(e.target.value)}
                    className="w-full p-2 bg-surface-container text-on-surface text-xs rounded-sm border border-surface-container-high"
                  >
                    {DEPARTMENTS.map((d, idx) => (
                      <option key={idx} value={d}>{d}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="text-[10px] uppercase font-bold text-on-surface-variant block mb-1">Role / Designation</label>
                  <input
                    type="text"
                    value={regRole}
                    onChange={(e) => setRegRole(e.target.value)}
                    className="w-full p-2 bg-surface-container text-on-surface text-xs rounded-sm border border-surface-container-high"
                  />
                </div>
              </div>

              {isLabourSelected && (
                <div className="p-3 bg-surface-container-low rounded-DEFAULT border border-primary/30 flex flex-col gap-2">
                  <span className="text-[11px] uppercase font-bold text-primary font-mono flex items-center gap-1">
                    <span className="material-symbols-outlined text-[15px]">badge</span>
                    Labour ID Card Metadata
                  </span>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                    <div>
                      <label className="text-[10px] uppercase font-bold text-on-surface-variant block mb-1">Badge Number</label>
                      <input
                        type="text"
                        value={regBadgeNumber}
                        onChange={(e) => setRegBadgeNumber(e.target.value)}
                        className="w-full p-2 bg-surface-container-low text-on-surface font-mono text-xs rounded-sm border border-surface-container-high"
                      />
                    </div>
                    <div>
                      <label className="text-[10px] uppercase font-bold text-on-surface-variant block mb-1">Trade Specialization</label>
                      <select
                        value={regTrade}
                        onChange={(e) => setRegTrade(e.target.value)}
                        className="w-full p-2 bg-surface-container-low text-on-surface text-xs rounded-sm border border-surface-container-high"
                      >
                        {TRADES.map((t, idx) => (
                          <option key={idx} value={t}>{t}</option>
                        ))}
                      </select>
                    </div>
                  </div>
                </div>
              )}

              <div className="flex justify-end gap-2 mt-2 pt-3 border-t border-surface-container-high">
                <button
                  type="button"
                  onClick={onClose}
                  className="px-4 py-2 bg-surface-container hover:bg-surface-container-high text-on-surface text-xs rounded-sm"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-6 py-2 bg-primary hover:bg-primary-container text-on-primary font-bold text-xs rounded-sm shadow-sm flex items-center gap-1.5 disabled:opacity-50"
                >
                  <span className="material-symbols-outlined text-[16px]">how_to_reg</span>
                  <span>{isSubmitting ? 'Connecting...' : 'Register & Enter Workspace'}</span>
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
};
