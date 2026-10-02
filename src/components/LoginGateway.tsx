'use client';

import React, { useState } from 'react';
import { UserProfile, Project } from '../types';
import { useWorkspace } from '../context/WorkspaceContext';

export interface PersonaOption {
  id: string;
  name: string;
  role: string;
  department: string;
  fidicRole: string;
  avatarInitials: string;
  color: {
    bg: string;
    border: string;
    text: string;
    badgeBg: string;
    badgeText: string;
    glow: string;
  };
  icon: string;
  highlights: string[];
  description: string;
}

export const DEMO_PERSONAS: PersonaOption[] = [
  {
    id: 'USR-DIR-01',
    name: 'Marcus Vance, P.E.',
    role: 'Project Director',
    department: 'Executive Governance & Controls',
    fidicRole: "Engineer's Representative (FIDIC 3.1)",
    avatarInitials: 'MV',
    color: {
      bg: 'bg-amber-500/10',
      border: 'border-amber-500/30 hover:border-amber-400',
      text: 'text-amber-400',
      badgeBg: 'bg-amber-500/20',
      badgeText: 'text-amber-300',
      glow: 'shadow-amber-500/10',
    },
    icon: 'analytics',
    highlights: ['EVM S-Curves (SPI/CPI)', 'FIDIC Delay Claim Shield', 'Capex & Risk Radar'],
    description: 'Executive project health, contractual compliance, 5-Factor Project Truth consensus, and board-level risk governance.',
  },
  {
    id: 'USR-SUP-02',
    name: 'Vikram Joshi',
    role: 'Site Piping Supervisor',
    department: 'Piping & Pipeline Engineering',
    fidicRole: 'Section In-Charge (Site Ops)',
    avatarInitials: 'VJ',
    color: {
      bg: 'bg-sky-500/10',
      border: 'border-sky-500/30 hover:border-sky-400',
      text: 'text-sky-400',
      badgeBg: 'bg-sky-500/20',
      badgeText: 'text-sky-300',
      glow: 'shadow-sky-500/10',
    },
    icon: 'engineering',
    highlights: ['Voice DPR (Hindi/English)', 'Crew & Gang Allocation', 'Pipe Lower-in Progress'],
    description: 'Daily field log submissions, trenching & pipe stringing supervision, equipment dispatch, and voice updates.',
  },
  {
    id: 'USR-QA-03',
    name: 'R. K. Sharma',
    role: 'QA/QC Lead Inspector',
    department: 'Quality Assurance & Inspection',
    fidicRole: 'Quality Assurance Inspector',
    avatarInitials: 'RS',
    color: {
      bg: 'bg-emerald-500/10',
      border: 'border-emerald-500/30 hover:border-emerald-400',
      text: 'text-emerald-400',
      badgeBg: 'bg-emerald-500/20',
      badgeText: 'text-emerald-300',
      glow: 'shadow-emerald-500/10',
    },
    icon: 'fact_check',
    highlights: ['AUT Phased Array NDT', 'Golden Weld Approvals', 'ASTM Concrete Breaks'],
    description: 'Radiography weld inspections, concrete cube crush tests, non-conformance reports (NCR), and specification tolerances.',
  },
  {
    id: 'USR-HSE-04',
    name: 'Kavita Nair',
    role: 'HSE & Safety Lead',
    department: 'Health, Safety & Environment',
    fidicRole: 'Safety Compliance Officer',
    avatarInitials: 'KN',
    color: {
      bg: 'bg-rose-500/10',
      border: 'border-rose-500/30 hover:border-rose-400',
      text: 'text-rose-400',
      badgeBg: 'bg-rose-500/20',
      badgeText: 'text-rose-300',
      glow: 'shadow-rose-500/10',
    },
    icon: 'health_and_safety',
    highlights: ['Permits-to-Work (PTW)', 'Atmospheric Gas Alarms', 'Zero-Harm Safety Audits'],
    description: 'Hot work and confined space authorization, atmospheric gas checks, excavation trench safety, and tool box talks.',
  },
  {
    id: 'USR-MAT-05',
    name: 'Pranab Deka',
    role: 'Stores & Materials Manager',
    department: 'Stores & Supply Chain Management',
    fidicRole: 'Materials Controller',
    avatarInitials: 'PD',
    color: {
      bg: 'bg-purple-500/10',
      border: 'border-purple-500/30 hover:border-purple-400',
      text: 'text-purple-400',
      badgeBg: 'bg-purple-500/20',
      badgeText: 'text-purple-300',
      glow: 'shadow-purple-500/10',
    },
    icon: 'inventory_2',
    highlights: ['Heat Number Traceability', 'Weighbridge GRN/GIN', 'Pipe Yard Inventory'],
    description: 'Line pipe heat tally matching, material receipts, gate passes, warehouse reorder alerts, and delivery inspections.',
  },
  {
    id: 'USR-LAB-06',
    name: 'Tapan Das',
    role: 'Skilled 6G Welder',
    department: 'Field Workforce Gang',
    fidicRole: 'Certified Tradesperson (API 1104)',
    avatarInitials: 'TD',
    color: {
      bg: 'bg-cyan-500/10',
      border: 'border-cyan-500/30 hover:border-cyan-400',
      text: 'text-cyan-400',
      badgeBg: 'bg-cyan-500/20',
      badgeText: 'text-cyan-300',
      glow: 'shadow-cyan-500/10',
    },
    icon: 'badge',
    highlights: ['Digital Labour ID', 'GPS Biometric Attendance', 'Daily Shift Wage Ledger'],
    description: 'Personalized self-service portal, biometric RTK clock-in, assigned weld tasks, overtime tracking, and safety induction.',
  },
];

interface LoginGatewayProps {
  onLoginSuccess?: () => void;
}

export const LoginGateway: React.FC<LoginGatewayProps> = ({ onLoginSuccess }) => {
  const workspace = useWorkspace();
  const { loginAsPersona, projects, currentProject, loadBenchmark } = workspace;

  const [activeTab, setActiveTab] = useState<'PERSONAS' | 'CREDENTIALS'>('PERSONAS');
  
  // Custom credential login state
  const [projectId, setProjectId] = useState<string>(currentProject?.id || 'PRJ-OIL-2026');
  const [empId, setEmpId] = useState<string>('OIL-ENG-2026');
  const [empName, setEmpName] = useState<string>('Site Engineer');
  const [selectedRole, setSelectedRole] = useState<string>('Site Piping Supervisor');
  const [passcode, setPasscode] = useState<string>('••••••••');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  const handleSelectPersona = (persona: PersonaOption) => {
    const userProfile: UserProfile = {
      id: persona.id,
      name: persona.name,
      email: `${persona.name.toLowerCase().replace(/[^a-z]/g, '.')}@oil.in`,
      role: persona.role,
      discipline: persona.department,
      organization: 'Universal Construction & Consortium',
      avatarUrl: '',
      fidicDesignation: persona.fidicRole,
      currentProjectRole: persona.role,
    };

    loginAsPersona(userProfile, currentProject || undefined);
    if (onLoginSuccess) onLoginSuccess();
  };

  const handleCredentialsSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    const userProfile: UserProfile = {
      id: empId || 'USR-CUSTOM',
      name: empName || 'Engineering Personnel',
      email: `${(empName || 'user').toLowerCase().replace(/\s+/g, '.')}@oil.in`,
      role: selectedRole,
      discipline: 'Infrastructure Operations',
      organization: 'Oil India Limited Consortium',
      avatarUrl: '',
      fidicDesignation: selectedRole,
      currentProjectRole: selectedRole,
    };

    setTimeout(() => {
      loginAsPersona(userProfile);
      setIsSubmitting(false);
      if (onLoginSuccess) onLoginSuccess();
    }, 300);
  };

  return (
    <div className="min-h-screen bg-[#070D1E] text-on-surface relative overflow-x-hidden flex flex-col justify-between selection:bg-primary selection:text-on-primary">
      {/* Ambient background glow elements */}
      <div className="absolute top-0 left-1/4 w-[600px] h-[400px] bg-primary/10 rounded-full blur-[140px] pointer-events-none -z-10" />
      <div className="absolute top-1/3 right-1/4 w-[500px] h-[350px] bg-tertiary/10 rounded-full blur-[130px] pointer-events-none -z-10" />
      <div className="absolute bottom-0 left-1/3 w-[600px] h-[300px] bg-secondary/10 rounded-full blur-[150px] pointer-events-none -z-10" />

      {/* Top Navigation Bar */}
      <header className="w-full border-b border-surface-container-high/60 bg-surface-container-lowest/80 backdrop-blur-md px-6 py-4 flex items-center justify-between z-30">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-primary via-primary-container to-blue-700 flex items-center justify-center text-white font-black text-lg shadow-lg shadow-primary/20">
            N
          </div>
          <div className="flex flex-col">
            <div className="flex items-center gap-2">
              <span className="font-extrabold text-base tracking-tight text-white">Nirmaan OS</span>
              <span className="px-2 py-0.5 rounded-full bg-primary/20 text-primary border border-primary/30 text-[10px] font-bold uppercase font-mono tracking-wider">
                SIH26122
              </span>
            </div>
            <span className="text-[11px] text-on-surface-variant font-medium">
              Oil India Limited · Industrial Project Intelligence Layer
            </span>
          </div>
        </div>

        {/* Live Network & Telemetry Pill */}
        <div className="hidden sm:flex items-center gap-3">
          <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-surface-container border border-surface-container-high text-xs font-mono">
            <span className="w-2 h-2 rounded-full bg-tertiary animate-radar" />
            <span className="text-tertiary font-bold">Node Assam Online</span>
            <span className="text-outline">•</span>
            <span className="text-on-surface-variant">RTK 99.4%</span>
          </div>

          <button
            onClick={() => loadBenchmark()}
            className="px-3 py-1.5 bg-surface-container-high hover:bg-surface-container-highest text-on-surface text-xs font-semibold rounded-md border border-surface-container-highest transition-colors flex items-center gap-1.5"
            title="Reload Official Oil India Duliajan Pipeline Dataset"
          >
            <span className="material-symbols-outlined text-[16px] text-secondary">database</span>
            <span>Reload Benchmark</span>
          </button>
        </div>
      </header>

      {/* Main Gateway Body */}
      <main className="flex-1 max-w-6xl w-full mx-auto px-4 sm:px-6 py-10 flex flex-col justify-center items-center z-10">
        {/* Hero Section */}
        <div className="text-center max-w-2xl mb-8 animate-fade-in">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-surface-container-high/80 border border-primary/30 text-primary text-xs font-semibold mb-4 backdrop-blur-sm">
            <span className="material-symbols-outlined text-[16px]">verified_user</span>
            <span>Role-Based Operational Access Control</span>
          </div>
          <h1 className="text-3xl sm:text-4xl lg:text-5xl font-black text-white tracking-tight leading-tight">
            Select Your Role to Enter{' '}
            <span className="bg-gradient-to-r from-primary via-tertiary to-secondary bg-clip-text text-transparent">
              Nirmaan OS
            </span>
          </h1>
          <p className="mt-3 text-sm sm:text-base text-on-surface-variant leading-relaxed">
            Every team member from Project Director to Field Welder receives a tailored, decluttered cockpit designed strictly for their workflows and decision rights.
          </p>
        </div>

        {/* Tab Switcher */}
        <div className="flex items-center p-1 rounded-lg bg-surface-container-lowest border border-surface-container-high mb-8 shadow-inner">
          <button
            onClick={() => setActiveTab('PERSONAS')}
            className={`flex items-center gap-2 px-5 py-2 rounded-md text-xs font-bold transition-all ${
              activeTab === 'PERSONAS'
                ? 'bg-primary-container text-white shadow-md'
                : 'text-on-surface-variant hover:text-white'
            }`}
          >
            <span className="material-symbols-outlined text-[17px]">groups</span>
            <span>1-Click Role Direct Access (SSO Demo)</span>
          </button>

          <button
            onClick={() => setActiveTab('CREDENTIALS')}
            className={`flex items-center gap-2 px-5 py-2 rounded-md text-xs font-bold transition-all ${
              activeTab === 'CREDENTIALS'
                ? 'bg-primary-container text-white shadow-md'
                : 'text-on-surface-variant hover:text-white'
            }`}
          >
            <span className="material-symbols-outlined text-[17px]">badge</span>
            <span>Corporate ID & Passkey Sign-In</span>
          </button>
        </div>

        {/* TAB 1: Role-Based Fast Access Cards */}
        {activeTab === 'PERSONAS' && (
          <div className="w-full grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 animate-fade-in">
            {DEMO_PERSONAS.map((persona) => (
              <div
                key={persona.id}
                onClick={() => handleSelectPersona(persona)}
                className={`group relative p-5 rounded-xl bg-surface-container-lowest/90 border ${persona.color.border} transition-all duration-300 hover:-translate-y-1.5 hover:shadow-xl ${persona.color.glow} cursor-pointer flex flex-col justify-between overflow-hidden`}
              >
                {/* Top Role Header */}
                <div>
                  <div className="flex items-start justify-between gap-3 mb-3">
                    <div className="flex items-center gap-3">
                      <div
                        className={`w-12 h-12 rounded-xl ${persona.color.bg} border ${persona.color.border} flex items-center justify-center font-black text-base ${persona.color.text} shadow-sm group-hover:scale-105 transition-transform`}
                      >
                        <span className="material-symbols-outlined text-[24px]">
                          {persona.icon}
                        </span>
                      </div>
                      <div className="flex flex-col">
                        <span className="font-bold text-sm text-white group-hover:text-primary transition-colors">
                          {persona.name}
                        </span>
                        <span className={`text-[11px] font-semibold ${persona.color.text}`}>
                          {persona.role}
                        </span>
                      </div>
                    </div>

                    <span
                      className={`px-2 py-0.5 rounded-full text-[10px] font-bold font-mono ${persona.color.badgeBg} ${persona.color.badgeText}`}
                    >
                      {persona.fidicRole.split(' ')[0]}
                    </span>
                  </div>

                  <p className="text-xs text-on-surface-variant leading-relaxed line-clamp-2 mb-4">
                    {persona.description}
                  </p>

                  {/* Highlights list */}
                  <div className="flex flex-wrap gap-1.5 mb-4">
                    {persona.highlights.map((item, idx) => (
                      <span
                        key={idx}
                        className="px-2 py-0.5 rounded bg-surface-container text-on-surface-variant border border-surface-container-high text-[10px] font-medium"
                      >
                        ✓ {item}
                      </span>
                    ))}
                  </div>
                </div>

                {/* Enter Button */}
                <div className="pt-3 border-t border-surface-container-high/60 flex items-center justify-between text-xs font-bold text-on-surface group-hover:text-primary transition-colors">
                  <span>Enter Tailored Cockpit</span>
                  <span className="material-symbols-outlined text-[18px] group-hover:translate-x-1 transition-transform">
                    arrow_forward
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* TAB 2: Corporate Credential Sign-In Form */}
        {activeTab === 'CREDENTIALS' && (
          <div className="w-full max-w-lg p-6 sm:p-8 rounded-2xl bg-surface-container-lowest border border-surface-container-high shadow-2xl animate-fade-in">
            <div className="flex items-center gap-3 mb-6 pb-4 border-b border-surface-container-high">
              <span className="material-symbols-outlined text-primary text-[28px]">lock</span>
              <div className="flex flex-col">
                <h3 className="font-bold text-base text-white">Enterprise Authentication</h3>
                <span className="text-xs text-on-surface-variant">Sign in with official project credentials</span>
              </div>
            </div>

            <form onSubmit={handleCredentialsSubmit} className="flex flex-col gap-4">
              <div>
                <label className="block text-xs font-bold text-on-surface-variant uppercase tracking-wider mb-1.5">
                  Project Code / Workspace ID
                </label>
                <div className="relative">
                  <span className="material-symbols-outlined absolute left-3 top-2.5 text-[18px] text-on-surface-variant">
                    business
                  </span>
                  <input
                    type="text"
                    value={projectId}
                    onChange={(e) => setProjectId(e.target.value)}
                    className="w-full h-10 pl-9 pr-3 rounded-lg bg-surface-container border border-surface-container-high text-xs text-white focus:outline-none focus:border-primary"
                    placeholder="e.g. PRJ-OIL-2026"
                    required
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-on-surface-variant uppercase tracking-wider mb-1.5">
                    Full Name
                  </label>
                  <input
                    type="text"
                    value={empName}
                    onChange={(e) => setEmpName(e.target.value)}
                    className="w-full h-10 px-3 rounded-lg bg-surface-container border border-surface-container-high text-xs text-white focus:outline-none focus:border-primary"
                    placeholder="e.g. John Doe"
                    required
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-on-surface-variant uppercase tracking-wider mb-1.5">
                    Employee ID
                  </label>
                  <input
                    type="text"
                    value={empId}
                    onChange={(e) => setEmpId(e.target.value)}
                    className="w-full h-10 px-3 rounded-lg bg-surface-container border border-surface-container-high text-xs text-white focus:outline-none focus:border-primary font-mono"
                    placeholder="e.g. OIL-ENG-04"
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-on-surface-variant uppercase tracking-wider mb-1.5">
                  Assigned Project Role
                </label>
                <select
                  value={selectedRole}
                  onChange={(e) => setSelectedRole(e.target.value)}
                  className="w-full h-10 px-3 rounded-lg bg-surface-container border border-surface-container-high text-xs text-white focus:outline-none focus:border-primary"
                >
                  <option value="Project Director">Project Director / PM (FIDIC 3.1)</option>
                  <option value="Site Piping Supervisor">Site Piping Supervisor (Section In-Charge)</option>
                  <option value="QA/QC Lead Inspector">QA/QC Lead Inspector (NDT/Welding)</option>
                  <option value="HSE & Safety Lead">HSE & Safety Lead (PTW & Compliance)</option>
                  <option value="Stores & Materials Manager">Stores & Materials Manager (GRN/GIN)</option>
                  <option value="Planning & Controls Engineer">Planning & Controls Engineer (P6 WBS)</option>
                  <option value="Skilled 6G Welder">Skilled 6G Welder / Labour (Field ID)</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-on-surface-variant uppercase tracking-wider mb-1.5">
                  Security Passkey / PIN
                </label>
                <input
                  type="password"
                  value={passcode}
                  onChange={(e) => setPasscode(e.target.value)}
                  className="w-full h-10 px-3 rounded-lg bg-surface-container border border-surface-container-high text-xs text-white focus:outline-none focus:border-primary"
                  placeholder="Enter 6-digit access PIN"
                  required
                />
              </div>

              <button
                type="submit"
                disabled={isSubmitting}
                className="w-full h-11 mt-2 rounded-lg bg-primary hover:bg-primary-container text-on-primary font-bold text-xs tracking-wider uppercase transition-all shadow-lg flex items-center justify-center gap-2 disabled:opacity-50"
              >
                {isSubmitting ? (
                  <>
                    <span className="w-4 h-4 border-2 border-on-primary border-t-transparent rounded-full animate-spin" />
                    <span>Authenticating Identity...</span>
                  </>
                ) : (
                  <>
                    <span className="material-symbols-outlined text-[18px]">login</span>
                    <span>Authenticate & Launch Workspace</span>
                  </>
                )}
              </button>
            </form>
          </div>
        )}

        {/* Quick Launch Direct Shortcuts */}
        <div className="mt-8 flex flex-wrap items-center justify-center gap-3 text-xs text-on-surface-variant">
          <span className="font-semibold">Quick Jump:</span>
          <button
            onClick={() => handleSelectPersona(DEMO_PERSONAS[0])}
            className="px-3 py-1 rounded bg-surface-container hover:bg-surface-container-high border border-surface-container-high text-white transition-colors"
          >
            Director (EVM & Claims)
          </button>
          <button
            onClick={() => handleSelectPersona(DEMO_PERSONAS[1])}
            className="px-3 py-1 rounded bg-surface-container hover:bg-surface-container-high border border-surface-container-high text-white transition-colors"
          >
            Supervisor (Voice DPR)
          </button>
          <button
            onClick={() => handleSelectPersona(DEMO_PERSONAS[2])}
            className="px-3 py-1 rounded bg-surface-container hover:bg-surface-container-high border border-surface-container-high text-white transition-colors"
          >
            QA/QC (NDT Welds)
          </button>
          <button
            onClick={() => handleSelectPersona(DEMO_PERSONAS[5])}
            className="px-3 py-1 rounded bg-surface-container hover:bg-surface-container-high border border-surface-container-high text-white transition-colors"
          >
            Labour (Digital ID)
          </button>
        </div>
      </main>

      {/* Footer */}
      <footer className="w-full border-t border-surface-container-high/40 bg-surface-container-lowest/60 px-6 py-4 flex flex-col sm:flex-row items-center justify-between text-[11px] text-on-surface-variant gap-2 z-10">
        <div className="flex items-center gap-2">
          <span className="w-2 h-2 rounded-full bg-tertiary"></span>
          <span>SQLite Deterministic Ledger · Zero Mock Data · Production Benchmark Active</span>
        </div>
        <div>
          <span>Nirmaan OS v4.2.0 · Smart India Hackathon 2024 (SIH26122)</span>
        </div>
      </footer>
    </div>
  );
};
