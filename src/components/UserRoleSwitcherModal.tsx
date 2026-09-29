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
}[] = [
  {
    roleTitle: 'Project Director / PM',
    name: 'Marcus Vance, P.E.',
    category: 'LEADERSHIP',
    department: 'Project Controls & Management',
    fidicRole: "Engineer's Representative (FIDIC 3.1)",
    description: 'Executive project health, FIDIC approvals, SPI/CPI, 5-Factor Project Truth consensus, and dispute governance.',
  },
  {
    roleTitle: 'Site Piping Supervisor',
    name: 'Vikram Joshi',
    category: 'SITE_SUPERVISION',
    department: 'Piping & Pipeline Engineering',
    fidicRole: 'Section In-Charge (Site Ops)',
    description: 'Voice DPR updates, gang supervision, shift logs, Line 24 pipe lower-in, and stores material requisitions.',
  },
  {
    roleTitle: 'Skilled 6G Welder (Labour ID)',
    name: 'Tapan Das',
    category: 'WORKFORCE',
    department: 'Field Workforce Gang',
    fidicRole: 'Certified Tradesperson (API 1104)',
    description: 'Digital Labour ID, GPS biometric attendance, task assignments, and safety induction record.',
  },
  {
    roleTitle: 'Planning & Controls Engineer',
    name: 'Ananya Sen',
    category: 'CONTROLS',
    department: 'Project Controls & Planning',
    fidicRole: 'Scheduler & Delay Analyst',
    description: 'Primavera P6 schedule, WBS L1-L6, critical path floats, and baseline variance analysis.',
  },
  {
    roleTitle: 'QA/QC Lead Inspector',
    name: 'R. K. Sharma',
    category: 'QUALITY_HSE',
    department: 'Quality Assurance & Inspection',
    fidicRole: 'Quality Assurance Inspector',
    description: 'Radiography NDT sign-offs, ASTM C39 concrete cube breaks, NCRs, and ITP inspections.',
  },
  {
    roleTitle: 'Stores & Materials Controller',
    name: 'Pranab Deka',
    category: 'SITE_SUPERVISION',
    department: 'Stores & Materials Management',
    fidicRole: 'Material Controller',
    description: 'Goods Receipt Notes (GRN), Goods Issue Notes (GIN), and line pipe / spool shortage management.',
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

  const [activeTab, setActiveTab] = useState<'REGISTER' | 'PRESET'>('REGISTER');

  // Quick Switch state
  const [selectedPreset, setSelectedPreset] = useState(PRESET_ROLES[0]);
  const [projectIdInput, setProjectIdInput] = useState(activeProject?.id || 'PRJ-OIL-2026');
  const [projectNameInput, setProjectNameInput] = useState(activeProject?.name || 'Oil India Trunk Pipeline Expansion');

  // Registration state
  const [regName, setRegName] = useState('');
  const [regPhone, setRegPhone] = useState('');
  const [regRole, setRegRole] = useState('Labour / Skilled Tradesperson');
  const [regDepartment, setRegDepartment] = useState(DEPARTMENTS[0]);
  const [regProjectId, setRegProjectId] = useState(activeProject?.id || 'PRJ-OIL-2026');
  const [regBadgeNumber, setRegBadgeNumber] = useState(`LAB-${Math.floor(1000 + Math.random() * 9000)}`);
  const [regTrade, setRegTrade] = useState(TRADES[0]);
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (!isOpen) return null;

  // Handle Quick Switch
  const handleApplyPreset = () => {
    const updatedUser: UserProfile = {
      ...activeUser,
      name: selectedPreset.name,
      role: selectedPreset.roleTitle,
      discipline: selectedPreset.department,
      currentProjectRole: selectedPreset.roleTitle,
      fidicDesignation: selectedPreset.fidicRole,
    };

    const targetProject: Project = {
      id: projectIdInput.toUpperCase(),
      code: projectIdInput.toUpperCase(),
      name: projectNameInput || `Project ${projectIdInput.toUpperCase()}`,
      client: activeProject?.client || 'Project Client',
      contractorJV: activeProject?.contractorJV || 'Consortium JV',
      contractType: activeProject?.contractType || 'FIDIC Red Book',
      lifecycle: 'EXECUTION',
      location: activeProject?.location || 'Site Location',
      budget: activeProject?.budget || 100000000,
      currency: activeProject?.currency || 'INR (₹)',
      startDate: activeProject?.startDate || new Date().toISOString().split('T')[0],
      plannedFinishDate: activeProject?.plannedFinishDate || '',
      spi: 1.0,
      cpi: 1.0,
      evidenceCoverage: 85,
      telemetryFreshness: 92,
      status: 'ON_TRACK',
    };

    if (onSwitchRole) {
      onSwitchRole(updatedUser, targetProject);
    } else {
      workspace.switchUserRole(updatedUser, targetProject);
    }
    onClose();
  };

  // Handle Real Registration
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
      <div className="w-full max-w-2xl bg-surface-container-lowest border border-surface-container-high rounded-xl shadow-2xl overflow-hidden flex flex-col">
        {/* Header */}
        <div className="p-4 bg-surface-container flex items-center justify-between border-b border-surface-container-high">
          <div className="flex items-center gap-2.5">
            <span className="w-8 h-8 rounded-DEFAULT bg-primary-container flex items-center justify-center text-white">
              <span className="material-symbols-outlined text-[19px]">manage_accounts</span>
            </span>
            <div>
              <h2 className="font-bold text-sm text-on-surface">Workspace Identity & Project Gateway</h2>
              <p className="text-[11px] text-on-surface-variant font-mono">
                Connect Department & Role to Project Unique ID (Universal Architecture)
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
            onClick={() => setActiveTab('REGISTER')}
            className={`pb-2.5 border-b-2 flex items-center gap-1.5 transition-all ${
              activeTab === 'REGISTER'
                ? 'border-primary text-primary'
                : 'border-transparent text-on-surface-variant hover:text-on-surface'
            }`}
          >
            <span className="material-symbols-outlined text-[16px]">person_add</span>
            <span>Register & Connect to Project ID</span>
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
            <span>Quick Switch Role Persona</span>
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-5 max-h-[72vh] overflow-y-auto">
          {activeTab === 'REGISTER' ? (
            /* TAB 1: User / Labour / Supervisor Registration Form */
            <form onSubmit={handleRegisterAndConnect} className="flex flex-col gap-4">
              <div className="p-3 bg-surface-container-low rounded-DEFAULT border border-surface-container-high text-xs text-on-surface-variant flex items-start gap-2">
                <span className="material-symbols-outlined text-primary text-[18px] shrink-0 mt-0.5">verified_user</span>
                <span>
                  Enter your details and connect directly to your project workspace using the <strong>Project Unique ID</strong> provided by your client or contractor consortium.
                </span>
              </div>

              {/* Project Unique ID Input */}
              <div className="p-3.5 bg-surface-container-lowest rounded-DEFAULT border border-primary/40 flex flex-col gap-1.5 shadow-sm">
                <label className="text-[11px] uppercase font-bold text-primary font-mono flex items-center justify-between">
                  <span>Project Unique ID (Mandatory)</span>
                  <span className="text-[10px] text-on-surface-variant font-normal">Connects to Project Baseline</span>
                </label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    required
                    value={regProjectId}
                    onChange={(e) => setRegProjectId(e.target.value.toUpperCase())}
                    placeholder="e.g. PRJ-OIL-2026 or P6-EXP-01"
                    className="flex-1 p-2.5 bg-surface-container-low text-on-surface font-mono font-bold text-xs rounded-sm border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary uppercase tracking-wider"
                  />
                  {workspace.projects.length > 0 && (
                    <select
                      onChange={(e) => e.target.value && setRegProjectId(e.target.value)}
                      className="p-2 bg-surface-container text-xs text-on-surface rounded-sm border border-surface-container-high max-w-[140px] truncate"
                    >
                      <option value="">Choose Existing</option>
                      {workspace.projects.map((p) => (
                        <option key={p.id} value={p.id}>{p.code} - {p.name}</option>
                      ))}
                    </select>
                  )}
                </div>
              </div>

              {/* Personal Details */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                <div>
                  <label className="text-[10px] uppercase font-bold text-on-surface-variant block mb-1">
                    Full Name <span className="text-error">*</span>
                  </label>
                  <input
                    type="text"
                    required
                    value={regName}
                    onChange={(e) => setRegName(e.target.value)}
                    placeholder="e.g. Rajesh Sharma"
                    className="w-full p-2 bg-surface-container-low text-on-surface text-xs rounded-sm border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary"
                  />
                </div>

                <div>
                  <label className="text-[10px] uppercase font-bold text-on-surface-variant block mb-1">
                    Phone / Mobile Number
                  </label>
                  <input
                    type="tel"
                    value={regPhone}
                    onChange={(e) => setRegPhone(e.target.value)}
                    placeholder="+91 98765 43210"
                    className="w-full p-2 bg-surface-container-low text-on-surface text-xs rounded-sm border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary font-mono"
                  />
                </div>
              </div>

              {/* Role & Department */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                <div>
                  <label className="text-[10px] uppercase font-bold text-on-surface-variant block mb-1">
                    Role in Project <span className="text-error">*</span>
                  </label>
                  <select
                    value={regRole}
                    onChange={(e) => setRegRole(e.target.value)}
                    className="w-full p-2 bg-surface-container-low text-on-surface text-xs rounded-sm border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary"
                  >
                    <option value="Labour / Skilled Tradesperson">Labour / Skilled Tradesperson (Field HUD)</option>
                    <option value="Site Piping Supervisor">Site Piping Supervisor / Foreman</option>
                    <option value="Site Civil Supervisor">Site Civil Supervisor / Foreman</option>
                    <option value="Planning & Controls Engineer">Planning & Controls Engineer (P6 Schedule)</option>
                    <option value="QA/QC Lead Inspector">QA/QC Lead Inspector (NDT / Tests)</option>
                    <option value="HSE & Safety Officer">HSE & Safety Officer (Permits / Toolbox)</option>
                    <option value="Stores & Materials Controller">Stores & Materials Controller (GRN / GIN)</option>
                    <option value="Project Director / PM">Project Director / Engineer's Rep (FIDIC)</option>
                  </select>
                </div>

                <div>
                  <label className="text-[10px] uppercase font-bold text-on-surface-variant block mb-1">
                    Assigned Department <span className="text-error">*</span>
                  </label>
                  <select
                    value={regDepartment}
                    onChange={(e) => setRegDepartment(e.target.value)}
                    className="w-full p-2 bg-surface-container-low text-on-surface text-xs rounded-sm border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary"
                  >
                    {DEPARTMENTS.map((dept, i) => (
                      <option key={i} value={dept}>{dept}</option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Labour / Tradesperson Specific Fields */}
              {isLabourSelected && (
                <div className="p-3.5 bg-tertiary/10 rounded-DEFAULT border border-tertiary/30 flex flex-col gap-3 animate-fade-in">
                  <span className="text-[11px] uppercase font-bold text-tertiary font-mono flex items-center gap-1.5">
                    <span className="material-symbols-outlined text-[16px]">badge</span>
                    Digital Labour ID & Trade Credential Setup
                  </span>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                    <div>
                      <label className="text-[10px] uppercase font-bold text-on-surface-variant block mb-1">
                        Labour Badge ID Number
                      </label>
                      <input
                        type="text"
                        value={regBadgeNumber}
                        onChange={(e) => setRegBadgeNumber(e.target.value)}
                        className="w-full p-2 bg-surface-container-low text-on-surface text-xs rounded-sm border border-surface-container-high font-mono font-bold"
                      />
                    </div>

                    <div>
                      <label className="text-[10px] uppercase font-bold text-on-surface-variant block mb-1">
                        Primary Trade Specialization
                      </label>
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

              {/* Submit Button */}
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
          ) : (
            /* TAB 2: Quick Switch Persona */
            <div className="flex flex-col gap-4">
              {/* Step 1: Project Connection */}
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

              {/* Step 2: Role Selection Grid */}
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

              {/* Switch Button */}
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
                  onClick={handleApplyPreset}
                  className="px-6 py-2 bg-primary hover:bg-primary-container text-on-primary font-bold text-xs rounded-sm shadow-sm flex items-center gap-1.5"
                >
                  <span className="material-symbols-outlined text-[16px]">switch_account</span>
                  <span>Switch Persona & Enter Workspace</span>
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
