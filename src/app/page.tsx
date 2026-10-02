'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { Sidebar } from '../components/Sidebar';
import { Header } from '../components/Header';
import { LoginGateway } from '../components/LoginGateway';
import { TriangulationMatrix } from '../components/TriangulationMatrix';
import { ConflictCenterView } from '../components/ConflictCenterView';
import { RelationshipGraph } from '../components/RelationshipGraph';
import { GanttScheduleView } from '../components/GanttScheduleView';
import { InteractiveDprView } from '../components/InteractiveDprView';
import { MaterialsStoresView } from '../components/MaterialsStoresView';
import { WorkforceAttendanceView } from '../components/WorkforceAttendanceView';
import { TechnicalTranslationView } from '../components/TechnicalTranslationView';
import { MobileFieldHUD } from '../components/MobileFieldHUD';
import { VoiceCommandModal } from '../components/VoiceCommandModal';
import { UserRoleSwitcherModal } from '../components/UserRoleSwitcherModal';
import { LabourSelfServiceView } from '../components/LabourSelfServiceView';
import { ProjectOnboardModal } from '../components/ProjectOnboardModal';
import { WorkerRegistrationModal } from '../components/WorkerRegistrationModal';
import { GeminiBrainModal } from '../components/GeminiBrainModal';
import { useWorkspace } from '../context/WorkspaceContext';

export default function HomePage() {
  const workspace = useWorkspace();
  const {
    user,
    isAuthenticated,
    sidebarCollapsed,
    currentProject,
    activities,
    conflicts,
    workers,
    materials,
    auditLogs,
    toastMessage,
    isLabour,
    isSupervisor,
    isQAQC,
    isHSE,
    isMaterials,
    isDirector,
    isPlanning,
    showToast,
    clockInWorker,
    resolveConflict,
    submitDpr,
    submitVoiceUpdate,
    wipeAllData,
    loadBenchmark,
    refreshData,
    logout,
  } = workspace;

  // View state & modals
  const [activeCategory, setActiveCategory] = useState<string>('ALL');
  const [deepDiveTab, setDeepDiveTab] = useState<'OVERVIEW' | 'TRUTH' | 'SCHEDULE' | 'CONFLICTS' | 'UWID'>('OVERVIEW');
  const [selectedActCode, setSelectedActCode] = useState<string>('');
  const [isVoiceModalOpen, setIsVoiceModalOpen] = useState(false);
  const [isRoleModalOpen, setIsRoleModalOpen] = useState(false);
  const [isOnboardModalOpen, setIsOnboardModalOpen] = useState(false);
  const [isWorkerModalOpen, setIsWorkerModalOpen] = useState(false);
  const [isGeminiModalOpen, setIsGeminiModalOpen] = useState(false);
  const [isMobileHUD, setIsMobileHUD] = useState(false);

  // Active selected activity
  const activeActivity = activities.find(a => a.activityCode === selectedActCode) || activities[0];

  const handleWipeData = async () => {
    if (confirm('Are you sure you want to wipe all data? The database will be completely empty with ZERO dummy records.')) {
      await wipeAllData();
    }
  };

  // IF NOT AUTHENTICATED: Show World-Class Login & Persona Gateway!
  if (!isAuthenticated) {
    return <LoginGateway onLoginSuccess={() => refreshData()} />;
  }

  // Blinkit-style category filter pills
  const categories = [
    { id: 'ALL', label: 'All Modules', icon: 'grid_view', count: 10 },
    { id: 'CONTROLS', label: 'Executive & EVM', icon: 'analytics', count: 2 },
    { id: 'PIPING', label: 'Piping & Welding', icon: 'cable', count: 2 },
    { id: 'QUALITY', label: 'QA/QC & NDT', icon: 'fact_check', count: 2 },
    { id: 'HSE', label: 'HSE & Safety', icon: 'health_and_safety', count: 1 },
    { id: 'MATERIALS', label: 'Materials & Stores', icon: 'inventory_2', count: 1 },
    { id: 'WORKFORCE', label: 'Workforce & Gangs', icon: 'groups', count: 1 },
    { id: 'EQUIPMENT', label: 'Plant & Fleet', icon: 'precision_manufacturing', count: 1 },
  ];

  // Amazon / Flipkart style module cards
  const moduleCards = [
    {
      id: 'linking-bridge',
      title: 'Schedule-Linking Bridge',
      subtitle: 'OIL Core Bridge',
      category: 'PIPING',
      description: 'Maps raw field voice notes & unstructured text directly to P6 activities.',
      path: '/linking-bridge',
      icon: 'cable',
      metric: `${activities.length} P6 Activities`,
      badge: 'OIL Core',
      badgeColor: 'bg-primary-container text-white',
    },
    {
      id: 'schedule',
      title: 'Master Schedule & P6 WBS',
      subtitle: 'Primavera P6 Engine',
      category: 'CONTROLS',
      description: 'Interactive Gantt chart with critical path floats, WBS levels 1-6, and variance.',
      path: '/schedule',
      icon: 'calendar_month',
      metric: `SPI: ${currentProject?.spi || 0.94}`,
      badge: 'Critical Path',
      badgeColor: 'bg-secondary/20 text-secondary',
    },
    {
      id: 'conflicts',
      title: 'Conflict & Risk Center',
      subtitle: 'Early Warning Radar',
      category: 'CONTROLS',
      description: 'Detects silent scope, quantity, and spec breaches before contractor claims emerge.',
      path: '/conflicts',
      icon: 'warning',
      metric: `${conflicts.filter(c => c.status === 'OPEN').length} Open Conflicts`,
      badge: conflicts.filter(c => c.status === 'OPEN').length > 0 ? 'Action Needed' : 'Nominal',
      badgeColor: conflicts.filter(c => c.status === 'OPEN').length > 0 ? 'bg-error-container text-on-error-container' : 'bg-tertiary/20 text-tertiary',
    },
    {
      id: 'dpr',
      title: 'Daily Construction Log',
      subtitle: 'Shift DPR & Field Data',
      category: 'PIPING',
      description: 'Digital daily progress reports, gang productivity, weather, and delay logs.',
      path: '/dpr',
      icon: 'history_edu',
      metric: 'Today Active',
      badge: 'Daily Log',
      badgeColor: 'bg-surface-container-high text-white',
    },
    {
      id: 'quality-hse',
      title: 'QA/QC & Lab Testing',
      subtitle: 'ASTM & API Compliance',
      category: 'QUALITY',
      description: 'Radiography AUT weld checks, Golden Welds, and concrete cube break tests.',
      path: '/quality-hse',
      icon: 'fact_check',
      metric: '42 Golden Welds',
      badge: 'API 1104',
      badgeColor: 'bg-tertiary/20 text-tertiary',
    },
    {
      id: 'workforce',
      title: 'Verified Workforce & Attendance',
      subtitle: 'RTK Geofenced Muster Roll',
      category: 'WORKFORCE',
      description: 'Biometric GPS clock-in, skill matrix, API 1104 welder certifications.',
      path: '/workforce',
      icon: 'badge',
      metric: `${workers.length} Personnel`,
      badge: '100% Verified',
      badgeColor: 'bg-tertiary/20 text-tertiary',
    },
    {
      id: 'materials',
      title: 'Materials & Stores (GRN/GIN)',
      subtitle: 'Pipe Heat Number Tracking',
      category: 'MATERIALS',
      description: 'Weighbridge gate pass, heat number tallies, and 3LPE primer inventories.',
      path: '/materials',
      icon: 'inventory_2',
      metric: `${materials.length} Transactions`,
      badge: 'Traceable',
      badgeColor: 'bg-primary/20 text-primary',
    },
    {
      id: 'equipment',
      title: 'Plant, Fleet & Machinery',
      subtitle: 'Heavy Equipment Telemetry',
      category: 'EQUIPMENT',
      description: 'Excavators, pipelayers, mobile cranes utilization, fuel burn, and idle alerts.',
      path: '/equipment',
      icon: 'precision_manufacturing',
      metric: '8 Plant Units',
      badge: 'GPS Active',
      badgeColor: 'bg-secondary/20 text-secondary',
    },
    {
      id: 'relationship-map',
      title: 'Universal Work ID (UWID)',
      subtitle: 'Digital Twin Topology',
      category: 'PIPING',
      description: 'Graph visualization linking physical spools, joints, workers, and P6 WBS.',
      path: '/relationship-map',
      icon: 'hub',
      metric: 'Graph Synced',
      badge: 'Topology',
      badgeColor: 'bg-surface-container-high text-white',
    },
    {
      id: 'audit',
      title: 'Tamper-Proof Audit Trail',
      subtitle: 'Deterministic SQLite Ledger',
      category: 'CONTROLS',
      description: 'SHA-256 cryptographic audit logs for every state change and approval.',
      path: '/audit',
      icon: 'verified_user',
      metric: `${auditLogs.length} Records`,
      badge: 'SHA-256',
      badgeColor: 'bg-tertiary/20 text-tertiary',
    },
  ];

  // Filter modules by category
  const filteredModules = activeCategory === 'ALL'
    ? moduleCards
    : moduleCards.filter(m => m.category === activeCategory);

  return (
    <div className="min-h-screen bg-[#070D1E] text-on-surface selection:bg-primary selection:text-on-primary">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed top-20 right-6 z-50 px-4 py-3 bg-primary text-on-primary rounded-lg shadow-2xl flex items-center gap-2 text-xs font-bold animate-bounce border border-white/20">
          <span className="material-symbols-outlined text-[18px]">verified</span>
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Top Header */}
      {currentProject && (
        <Header
          user={user}
          project={currentProject}
          onOpenVoiceModal={() => setIsVoiceModalOpen(true)}
          onOpenGeminiBrain={() => setIsGeminiModalOpen(true)}
          onOpenRoleSwitcher={() => setIsRoleModalOpen(true)}
          isMobileHUD={isMobileHUD}
          onToggleMobileHUD={() => setIsMobileHUD(!isMobileHUD)}
        />
      )}

      {/* Collapsible Left Navigation Bar */}
      {currentProject && (
        <Sidebar
          project={currentProject}
          activeConflictsCount={conflicts.filter(c => c.status === 'OPEN').length}
        />
      )}

      {/* Main Container */}
      <main
        className={`${
          currentProject
            ? sidebarCollapsed
              ? 'pl-[72px]'
              : 'pl-72'
            : 'pl-0'
        } pt-16 min-h-screen transition-all duration-300 ease-in-out bg-[#070D1E]`}
      >
        {/* If Mobile Field HUD is active */}
        {isMobileHUD && activeActivity ? (
          <div className="p-4 sm:p-6 max-w-xl mx-auto">
            <div className="flex items-center justify-between mb-4">
              <span className="text-xs uppercase font-bold text-on-surface-variant font-mono">
                Field Supervisor Viewport ({currentProject?.location})
              </span>
              <button
                onClick={() => setIsMobileHUD(false)}
                className="text-xs text-primary font-semibold hover:underline"
              >
                Return to Desktop
              </button>
            </div>
            <MobileFieldHUD
              activity={activeActivity}
              onOpenVoiceModal={() => setIsVoiceModalOpen(true)}
              onQuickProgressAdd={(qty) => {
                submitDpr(activeActivity.activityCode, qty, activeActivity.unit, undefined, 'Quick supervisor progress');
              }}
            />
          </div>
        ) : isLabour ? (
          /* Labour / Tradesperson Self-Service Portal */
          <div className="p-4 sm:p-8 max-w-2xl mx-auto animate-fade-in">
            <div className="flex items-center justify-between mb-4">
              <span className="text-xs uppercase font-bold text-on-surface-variant font-mono">
                Workforce Self-Service · {user.name} ({user.role})
              </span>
              <button
                onClick={() => setIsRoleModalOpen(true)}
                className="text-xs text-primary font-semibold hover:underline flex items-center gap-1"
              >
                <span className="material-symbols-outlined text-[15px]">switch_account</span>
                <span>Switch Role</span>
              </button>
            </div>
            <LabourSelfServiceView
              worker={workers[0] || {
                id: 'WRK-01',
                badgeNumber: 'LAB-API-01',
                name: user.name,
                trade: '6G Pipe Welder (TIG/MIG)',
                skills: ['6G Pipe TIG/MIG', 'API 1104'],
                contractor: 'Oil India Construction Gang',
                activeProject: currentProject?.id || 'PRJ-OIL-2026',
                assignedActivityId: activeActivity ? activeActivity.activityCode : 'ACT-01',
                safetyCertValidTill: '2027-12-31',
                medicalClearance: true,
                photoUrl: '',
                lastClockIn: 'Clock-in pending today',
                attendanceStatus: 'ABSENT',
                verificationMethod: 'NOT_VERIFIED',
                confidenceScore: 0,
              }}
              activity={activeActivity}
              onClockIn={() => clockInWorker(workers[0]?.id || 'WRK-01')}
            />
          </div>
        ) : (
          /* Modern, Decluttered, Role-Tailored Landing Page */
          <div className="p-4 sm:p-6 lg:p-8 max-w-7xl mx-auto flex flex-col gap-6 animate-fade-in">
            {/* 1. Personalized Hero Banner (Clean, Spacious & Welcoming) */}
            <div className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-surface-container-low via-surface-container to-surface-container-low border border-surface-container-high/80 p-5 sm:p-6 shadow-xl">
              <div className="relative z-10 flex flex-col lg:flex-row lg:items-center justify-between gap-5">
                <div className="flex flex-col gap-1.5">
                  <div className="flex items-center gap-2">
                    <span className="px-2.5 py-0.5 rounded-full bg-primary/20 text-primary border border-primary/30 text-[10px] font-bold uppercase font-mono tracking-wider">
                      {user.role}
                    </span>
                    <span className="text-on-surface-variant text-xs">
                      {user.discipline}
                    </span>
                  </div>

                  <h1 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
                    Welcome back, {user.name}
                  </h1>

                  <div className="flex flex-wrap items-center gap-2 text-xs text-on-surface-variant mt-0.5">
                    <span className="text-white font-semibold">
                      {currentProject?.name}
                    </span>
                    <span>•</span>
                    <span className="font-mono text-tertiary font-bold">
                      SPI {currentProject?.spi} · CPI {currentProject?.cpi}
                    </span>
                    <span>•</span>
                    <span className="text-primary font-mono font-medium">
                      Evidence {currentProject?.evidenceCoverage}%
                    </span>
                  </div>
                </div>

                {/* Quick Action Dock */}
                <div className="flex flex-wrap items-center gap-2.5">
                  <button
                    onClick={() => setIsVoiceModalOpen(true)}
                    className="h-10 px-4 rounded-xl bg-primary-container hover:bg-blue-600 text-white font-bold text-xs flex items-center gap-2 shadow-lg shadow-primary-container/20 transition-all active:scale-95"
                  >
                    <span className="material-symbols-outlined text-[19px]">mic</span>
                    <span>Record Voice DPR</span>
                  </button>

                  <button
                    onClick={() => setIsGeminiModalOpen(true)}
                    className="h-10 px-4 rounded-xl bg-surface-container hover:bg-surface-container-high text-white border border-tertiary/40 font-bold text-xs flex items-center gap-2 shadow-sm transition-all"
                  >
                    <span className="material-symbols-outlined text-[19px] text-tertiary">psychology</span>
                    <span>Gemini AI</span>
                  </button>

                  <button
                    onClick={() => setIsRoleModalOpen(true)}
                    className="h-10 px-3.5 rounded-xl bg-surface-container hover:bg-surface-container-high text-on-surface-variant hover:text-white border border-surface-container-high font-semibold text-xs flex items-center gap-1.5 transition-colors"
                  >
                    <span className="material-symbols-outlined text-[18px]">switch_account</span>
                    <span>Switch Role</span>
                  </button>

                  <button
                    onClick={() => setIsOnboardModalOpen(true)}
                    className="h-10 px-3.5 rounded-xl bg-surface-container hover:bg-surface-container-high text-on-surface-variant hover:text-white border border-surface-container-high font-semibold text-xs flex items-center gap-1.5 transition-colors"
                  >
                    <span className="material-symbols-outlined text-[18px]">domain_add</span>
                    <span>Import P6</span>
                  </button>
                </div>
              </div>
            </div>

            {/* 2. Instagram-Style Live Site Telemetry / Highlights Reel */}
            <div className="flex flex-col gap-2">
              <div className="flex items-center justify-between text-xs px-1">
                <span className="font-bold text-on-surface-variant uppercase tracking-wider text-[11px] flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-tertiary animate-radar" />
                  Live Field Telemetry (Oil India Duliajan Spread)
                </span>
                <span className="text-[10px] text-on-surface-variant font-mono">
                  Real-time RTK Sensor Pulses
                </span>
              </div>

              <div className="flex items-center gap-3 overflow-x-auto pb-1 scrollbar-thin">
                <div className="flex-shrink-0 px-3.5 py-2.5 rounded-xl bg-surface-container-low border border-surface-container-high flex items-center gap-2.5 text-xs shadow-sm">
                  <span className="w-2 h-2 rounded-full bg-tertiary" />
                  <span className="font-bold text-white">Spread 2 Lower-in:</span>
                  <span className="text-on-surface-variant">64.5m 24" pipe verified (Ch. 14+200)</span>
                </div>

                <div className="flex-shrink-0 px-3.5 py-2.5 rounded-xl bg-surface-container-low border border-surface-container-high flex items-center gap-2.5 text-xs shadow-sm">
                  <span className="w-2 h-2 rounded-full bg-tertiary" />
                  <span className="font-bold text-white">Golden Weld GW-08:</span>
                  <span className="text-on-surface-variant">Radiography AUT 100% Accepted</span>
                </div>

                <div className="flex-shrink-0 px-3.5 py-2.5 rounded-xl bg-surface-container-low border border-surface-container-high flex items-center gap-2.5 text-xs shadow-sm">
                  <span className="w-2 h-2 rounded-full bg-primary" />
                  <span className="font-bold text-white">Yard 3 Weighbridge:</span>
                  <span className="text-on-surface-variant">120 joints 3LPE coated line pipe logged</span>
                </div>

                <div className="flex-shrink-0 px-3.5 py-2.5 rounded-xl bg-surface-container-low border border-surface-container-high flex items-center gap-2.5 text-xs shadow-sm">
                  <span className="w-2 h-2 rounded-full bg-secondary" />
                  <span className="font-bold text-white">RTK Geofence:</span>
                  <span className="text-on-surface-variant">142 certified workers online · 0 Incidents</span>
                </div>

                <div className="flex-shrink-0 px-3.5 py-2.5 rounded-xl bg-surface-container-low border border-surface-container-high flex items-center gap-2.5 text-xs shadow-sm">
                  <span className="w-2 h-2 rounded-full bg-sky-400" />
                  <span className="font-bold text-white">Duliajan Weather:</span>
                  <span className="text-on-surface-variant">26°C · Low humidity · Trenching nominal</span>
                </div>
              </div>
            </div>

            {/* 3. The Individual's Personalized Action Cockpit (Role-Tailored Hero Card) */}
            <div className="rounded-2xl bg-surface-container-lowest border border-surface-container-high p-5 sm:p-6 shadow-lg">
              <div className="flex items-center justify-between pb-4 border-b border-surface-container-high/60 mb-5">
                <div className="flex items-center gap-2.5">
                  <div className="w-9 h-9 rounded-lg bg-primary/10 border border-primary/30 flex items-center justify-center text-primary">
                    <span className="material-symbols-outlined text-[20px]">
                      {isDirector
                        ? 'analytics'
                        : isSupervisor
                        ? 'engineering'
                        : isQAQC
                        ? 'fact_check'
                        : isHSE
                        ? 'health_and_safety'
                        : isMaterials
                        ? 'inventory_2'
                        : 'dashboard'}
                    </span>
                  </div>
                  <div className="flex flex-col">
                    <h2 className="text-base font-bold text-white">
                      {isDirector
                        ? 'Executive Director & FIDIC Controls Cockpit'
                        : isSupervisor
                        ? 'Site Piping & Construction Operations Cockpit'
                        : isQAQC
                        ? 'QA/QC Weld & Lab Testing Cockpit'
                        : isHSE
                        ? 'HSE & Safety Permit Compliance Cockpit'
                        : isMaterials
                        ? 'Stores, Inventory & Pipe Heat Registry Cockpit'
                        : 'Project Operations Cockpit'}
                    </h2>
                    <span className="text-xs text-on-surface-variant">
                      Tailored primary control view for {user.name} ({user.role})
                    </span>
                  </div>
                </div>

                <button
                  onClick={() => setIsRoleModalOpen(true)}
                  className="px-3 py-1 rounded-md bg-surface-container hover:bg-surface-container-high text-xs text-primary font-semibold border border-surface-container-high flex items-center gap-1 transition-colors"
                >
                  <span className="material-symbols-outlined text-[15px]">tune</span>
                  <span>Adjust Persona</span>
                </button>
              </div>

              {/* ROLE 1: Project Director */}
              {isDirector && (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 animate-fade-in">
                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant tracking-wider">
                      Earned Value (BCWP)
                    </span>
                    <div className="my-2">
                      <span className="text-2xl font-black text-white font-mono">₹142.4 Cr</span>
                      <span className="text-xs text-tertiary ml-2 font-bold">+₹4.2 Cr ahead</span>
                    </div>
                    <span className="text-[10px] text-on-surface-variant">Planned: ₹138.2 Cr · Capex Secure</span>
                  </div>

                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant tracking-wider">
                      Schedule Index (SPI)
                    </span>
                    <div className="my-2 flex items-baseline gap-2">
                      <span className="text-2xl font-black text-white font-mono">{currentProject?.spi || 0.94}</span>
                      <span className="text-xs px-2 py-0.5 rounded bg-tertiary/20 text-tertiary font-bold">On Track</span>
                    </div>
                    <span className="text-[10px] text-on-surface-variant">Tolerance threshold &gt; 0.90 (Nominal)</span>
                  </div>

                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant tracking-wider">
                      Cost Efficiency (CPI)
                    </span>
                    <div className="my-2 flex items-baseline gap-2">
                      <span className="text-2xl font-black text-white font-mono">{currentProject?.cpi || 1.02}</span>
                      <span className="text-xs px-2 py-0.5 rounded bg-tertiary/20 text-tertiary font-bold">Under Budget</span>
                    </div>
                    <span className="text-[10px] text-on-surface-variant">₹0.98 actual cost per ₹1.00 earned</span>
                  </div>

                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant tracking-wider">
                      FIDIC Cl. 8.4 Delay Shield
                    </span>
                    <div className="my-2 flex items-baseline gap-2">
                      <span className="text-2xl font-black text-white font-mono">0 Claims</span>
                      <span className="text-xs px-2 py-0.5 rounded bg-primary/20 text-primary font-bold">100% Defended</span>
                    </div>
                    <span className="text-[10px] text-on-surface-variant">Zero unmitigated contractor delay exposure</span>
                  </div>
                </div>
              )}

              {/* ROLE 2: Site Supervisor */}
              {isSupervisor && (
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 animate-fade-in">
                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <div className="flex items-center justify-between">
                      <span className="text-[11px] font-bold uppercase text-on-surface-variant tracking-wider">
                        Today's Progress Logging
                      </span>
                      <span className="material-symbols-outlined text-primary text-[20px]">edit_note</span>
                    </div>
                    <div className="my-3">
                      <span className="text-xl font-bold text-white">Line 24 Trench & Lower-in</span>
                      <p className="text-xs text-on-surface-variant mt-1">Planned: 60.0m · Installed: 64.5m today</p>
                    </div>
                    <button
                      onClick={() => setIsVoiceModalOpen(true)}
                      className="w-full py-2 rounded-lg bg-primary-container hover:bg-blue-600 text-white text-xs font-bold flex items-center justify-center gap-1.5 transition-colors shadow-sm"
                    >
                      <span className="material-symbols-outlined text-[16px]">mic</span>
                      <span>Voice Record Shift DPR</span>
                    </button>
                  </div>

                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <div className="flex items-center justify-between">
                      <span className="text-[11px] font-bold uppercase text-on-surface-variant tracking-wider">
                        Active Field Gangs
                      </span>
                      <span className="material-symbols-outlined text-tertiary text-[20px]">groups</span>
                    </div>
                    <div className="my-3">
                      <span className="text-2xl font-black text-white font-mono">6 Active Gangs</span>
                      <p className="text-xs text-on-surface-variant mt-1">38 certified welders & fitters checked-in</p>
                    </div>
                    <Link
                      href="/workforce"
                      className="w-full py-2 rounded-lg bg-surface-container hover:bg-surface-container-high text-white text-xs font-bold flex items-center justify-center gap-1.5 transition-colors border border-surface-container-high"
                    >
                      <span>Manage Gang Allocations →</span>
                    </Link>
                  </div>

                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <div className="flex items-center justify-between">
                      <span className="text-[11px] font-bold uppercase text-on-surface-variant tracking-wider">
                        Heavy Plant Allocation
                      </span>
                      <span className="material-symbols-outlined text-secondary text-[20px]">precision_manufacturing</span>
                    </div>
                    <div className="my-3">
                      <span className="text-2xl font-black text-white font-mono">8 Units Online</span>
                      <p className="text-xs text-on-surface-variant mt-1">EX-04 Excavator & PL-02 Pipelayer active</p>
                    </div>
                    <Link
                      href="/equipment"
                      className="w-full py-2 rounded-lg bg-surface-container hover:bg-surface-container-high text-white text-xs font-bold flex items-center justify-center gap-1.5 transition-colors border border-surface-container-high"
                    >
                      <span>View Machinery HUD →</span>
                    </Link>
                  </div>
                </div>
              )}

              {/* ROLE 3: QA/QC Lead Inspector */}
              {isQAQC && (
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 animate-fade-in">
                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant tracking-wider">
                      AUT Phased Array NDT
                    </span>
                    <div className="my-3">
                      <span className="text-2xl font-black text-white font-mono">42 / 44 Joints</span>
                      <p className="text-xs text-tertiary font-semibold mt-1">95.4% Radiography Acceptance Rate</p>
                    </div>
                    <Link
                      href="/quality-hse"
                      className="w-full py-2 rounded-lg bg-primary-container hover:bg-blue-600 text-white text-xs font-bold flex items-center justify-center gap-1.5 transition-colors"
                    >
                      <span>Review Weld NDT Queue →</span>
                    </Link>
                  </div>

                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant tracking-wider">
                      ASTM C39 Concrete Breaks
                    </span>
                    <div className="my-3">
                      <span className="text-2xl font-black text-white font-mono">38.4 MPa</span>
                      <p className="text-xs text-on-surface-variant mt-1">28-day target: 35.0 MPa (Pass +9.7%)</p>
                    </div>
                    <Link
                      href="/quality-hse"
                      className="w-full py-2 rounded-lg bg-surface-container hover:bg-surface-container-high text-white text-xs font-bold flex items-center justify-center gap-1.5 transition-colors border border-surface-container-high"
                    >
                      <span>Log Cube Crush Test →</span>
                    </Link>
                  </div>

                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant tracking-wider">
                      Non-Conformance Reports (NCR)
                    </span>
                    <div className="my-3">
                      <span className="text-2xl font-black text-white font-mono">0 Active NCRs</span>
                      <p className="text-xs text-tertiary font-semibold mt-1">All welds within API 1104 tolerance</p>
                    </div>
                    <Link
                      href="/conflicts"
                      className="w-full py-2 rounded-lg bg-surface-container hover:bg-surface-container-high text-white text-xs font-bold flex items-center justify-center gap-1.5 transition-colors border border-surface-container-high"
                    >
                      <span>Inspect Tolerance Breaches →</span>
                    </Link>
                  </div>
                </div>
              )}

              {/* ROLE 4: HSE Lead */}
              {isHSE && (
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 animate-fade-in">
                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant tracking-wider">
                      Permits to Work (PTW)
                    </span>
                    <div className="my-3">
                      <span className="text-2xl font-black text-white font-mono">6 Active PTWs</span>
                      <p className="text-xs text-on-surface-variant mt-1">Hot Work & Confined Space entries authorized</p>
                    </div>
                    <span className="text-[10px] text-tertiary font-bold">Valid till 18:00 IST today</span>
                  </div>

                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant tracking-wider">
                      Atmospheric Gas Monitoring
                    </span>
                    <div className="my-3">
                      <span className="text-2xl font-black text-white font-mono">0 ppm H2S</span>
                      <p className="text-xs text-tertiary font-semibold mt-1">LEL: 0% · O2: 20.9% (Safe zone)</p>
                    </div>
                    <span className="text-[10px] text-on-surface-variant">Continuous geofence detector online</span>
                  </div>

                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant tracking-wider">
                      Tool Box Talks (TBT)
                    </span>
                    <div className="my-3">
                      <span className="text-2xl font-black text-white font-mono">100% Signed</span>
                      <p className="text-xs text-on-surface-variant mt-1">142 workers attended morning briefing</p>
                    </div>
                    <span className="text-[10px] text-tertiary font-bold">Zero-Harm Safe Work Hours: 14,280h</span>
                  </div>
                </div>
              )}

              {/* ROLE 5: Materials Manager */}
              {isMaterials && (
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 animate-fade-in">
                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant tracking-wider">
                      Pipe Yard Heat Number Tally
                    </span>
                    <div className="my-3">
                      <span className="text-2xl font-black text-white font-mono">100% Matched</span>
                      <p className="text-xs text-on-surface-variant mt-1">3LPE API 5L X70 pipe joints matched to MTR</p>
                    </div>
                    <Link
                      href="/materials"
                      className="w-full py-2 rounded-lg bg-primary-container hover:bg-blue-600 text-white text-xs font-bold flex items-center justify-center gap-1.5 transition-colors"
                    >
                      <span>Inspect Heat Registry →</span>
                    </Link>
                  </div>

                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant tracking-wider">
                      Weighbridge Slips (GRN/GIN)
                    </span>
                    <div className="my-3">
                      <span className="text-2xl font-black text-white font-mono">14 Trucks Processed</span>
                      <p className="text-xs text-on-surface-variant mt-1">All delivery tare weights recorded</p>
                    </div>
                    <Link
                      href="/materials"
                      className="w-full py-2 rounded-lg bg-surface-container hover:bg-surface-container-high text-white text-xs font-bold flex items-center justify-center gap-1.5 transition-colors border border-surface-container-high"
                    >
                      <span>Issue Material Gate Pass →</span>
                    </Link>
                  </div>

                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant tracking-wider">
                      Consumable Reorder Alerts
                    </span>
                    <div className="my-3">
                      <span className="text-2xl font-black text-white font-mono">Stock Healthy</span>
                      <p className="text-xs text-tertiary font-semibold mt-1">E6010 / E7018 Electrodes above threshold</p>
                    </div>
                    <span className="text-[10px] text-on-surface-variant">Reorder trigger set at 15% minimum buffer</span>
                  </div>
                </div>
              )}
            </div>

            {/* 4. Blinkit-Style Category Filter Chips */}
            <div className="flex flex-col gap-3">
              <div className="flex items-center justify-between">
                <h3 className="text-sm font-bold uppercase tracking-wider text-on-surface-variant">
                  Explore Enterprise Modules (Amazon / Blinkit Grid)
                </h3>
                <span className="text-xs text-on-surface-variant font-mono">
                  Showing {filteredModules.length} of {moduleCards.length} Modules
                </span>
              </div>

              {/* Horizontal Scrollable Category Bar */}
              <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-thin">
                {categories.map((cat) => (
                  <button
                    key={cat.id}
                    onClick={() => setActiveCategory(cat.id)}
                    className={`px-3.5 py-2 rounded-xl text-xs font-bold flex items-center gap-2 whitespace-nowrap transition-all ${
                      activeCategory === cat.id
                        ? 'bg-primary-container text-white shadow-md shadow-primary-container/20 scale-105'
                        : 'bg-surface-container-low hover:bg-surface-container text-on-surface-variant hover:text-white border border-surface-container-high'
                    }`}
                  >
                    <span className="material-symbols-outlined text-[17px]">
                      {cat.icon}
                    </span>
                    <span>{cat.label}</span>
                    <span
                      className={`px-1.5 py-0.2 rounded-full text-[10px] font-mono ${
                        activeCategory === cat.id
                          ? 'bg-white/20 text-white'
                          : 'bg-surface-container text-on-surface-variant'
                      }`}
                    >
                      {cat.count}
                    </span>
                  </button>
                ))}
              </div>
            </div>

            {/* 5. Amazon / Flipkart Style Module Cards Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 animate-fade-in">
              {filteredModules.map((card) => (
                <Link
                  key={card.id}
                  href={card.path}
                  className="group p-5 rounded-2xl bg-surface-container-lowest/80 border border-surface-container-high/80 hover:border-primary/50 transition-all duration-300 hover:-translate-y-1 hover:shadow-xl hover:shadow-primary/5 flex flex-col justify-between"
                >
                  <div>
                    <div className="flex items-start justify-between gap-3 mb-3">
                      <div className="w-11 h-11 rounded-xl bg-surface-container flex items-center justify-center text-primary group-hover:scale-110 group-hover:bg-primary-container group-hover:text-white transition-all shadow-sm">
                        <span className="material-symbols-outlined text-[22px]">
                          {card.icon}
                        </span>
                      </div>

                      <span
                        className={`px-2 py-0.5 rounded-full text-[10px] font-bold font-mono ${card.badgeColor}`}
                      >
                        {card.badge}
                      </span>
                    </div>

                    <h4 className="font-bold text-sm text-white group-hover:text-primary transition-colors">
                      {card.title}
                    </h4>
                    <span className="text-[10px] text-on-surface-variant uppercase font-mono tracking-wider">
                      {card.subtitle}
                    </span>

                    <p className="text-xs text-on-surface-variant/80 mt-2 line-clamp-2 leading-relaxed">
                      {card.description}
                    </p>
                  </div>

                  <div className="mt-4 pt-3 border-t border-surface-container-high/60 flex items-center justify-between">
                    <span className="font-mono text-xs font-bold text-tertiary">
                      {card.metric}
                    </span>
                    <span className="material-symbols-outlined text-[18px] text-on-surface-variant group-hover:text-primary group-hover:translate-x-1 transition-all">
                      arrow_forward
                    </span>
                  </div>
                </Link>
              ))}
            </div>

            {/* 6. Deep-Dive Analytical Matrix (Toggleable, NOT Crowded) */}
            <div className="mt-4 rounded-2xl bg-surface-container-lowest border border-surface-container-high p-5 sm:p-6 shadow-xl">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-surface-container-high/60">
                <div className="flex items-center gap-2">
                  <span className="material-symbols-outlined text-primary text-[22px]">hub</span>
                  <div>
                    <h3 className="text-sm font-bold text-white uppercase tracking-wider">
                      Detailed Analytical Matrix & Schedule Engine
                    </h3>
                    <span className="text-xs text-on-surface-variant">
                      Expand deep dive data models when needed (Without cluttering main dashboard)
                    </span>
                  </div>
                </div>

                {/* Sub-tab Switcher */}
                <div className="flex items-center gap-1.5 p-1 rounded-lg bg-surface-container-low border border-surface-container-high text-xs font-semibold overflow-x-auto">
                  {[
                    { id: 'OVERVIEW', label: 'EVM Metrics', icon: 'speed' },
                    { id: 'TRUTH', label: 'Project Truth', icon: 'monitoring' },
                    { id: 'SCHEDULE', label: 'P6 Gantt', icon: 'calendar_month' },
                    { id: 'CONFLICTS', label: `Conflicts (${conflicts.filter(c => c.status === 'OPEN').length})`, icon: 'warning' },
                    { id: 'UWID', label: 'UWID Topology', icon: 'hub' },
                  ].map((tab) => (
                    <button
                      key={tab.id}
                      onClick={() => setDeepDiveTab(tab.id as any)}
                      className={`px-3 py-1.5 rounded-md flex items-center gap-1.5 transition-all whitespace-nowrap ${
                        deepDiveTab === tab.id
                          ? 'bg-primary-container text-white font-bold shadow-sm'
                          : 'text-on-surface-variant hover:text-white'
                      }`}
                    >
                      <span className="material-symbols-outlined text-[15px]">{tab.icon}</span>
                      <span>{tab.label}</span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Dynamic Sub-tab Canvas */}
              <div className="pt-5">
                {deepDiveTab === 'OVERVIEW' && (
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high">
                      <span className="text-xs font-bold text-on-surface-variant uppercase">Contract Baseline</span>
                      <h4 className="text-lg font-bold text-white mt-1">Duliajan-Digboi Crude Pipeline</h4>
                      <p className="text-xs text-on-surface-variant mt-2 leading-relaxed">
                        Total 42km 24" API 5L X70 pipeline with 3 HDD river crossings under FIDIC Red Book Clause 8.4 conditions.
                      </p>
                    </div>

                    <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high">
                      <span className="text-xs font-bold text-on-surface-variant uppercase">5-Factor Consensus</span>
                      <h4 className="text-lg font-bold text-tertiary mt-1">Deterministic Truth Active</h4>
                      <p className="text-xs text-on-surface-variant mt-2 leading-relaxed">
                        Triangulating physical telemetry, contractor DPR, QA/QC NDT logs, weighbridge slips, and P6 baseline.
                      </p>
                    </div>

                    <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high">
                      <span className="text-xs font-bold text-on-surface-variant uppercase">Gemini Autonomous Brain</span>
                      <h4 className="text-lg font-bold text-primary mt-1">Parallel Micro-Agents</h4>
                      <p className="text-xs text-on-surface-variant mt-2 leading-relaxed">
                        Reasoning across Hindi site voice transcripts to auto-link progress into Primavera P6 WBS.
                      </p>
                    </div>
                  </div>
                )}

                {deepDiveTab === 'TRUTH' && (
                  <TriangulationMatrix
                    activity={activeActivity}
                    onOpenAuditLog={() => {}}
                    onRequestLabExpedite={() => showToast('Lab Expedite Notice Issued!')}
                  />
                )}

                {deepDiveTab === 'SCHEDULE' && (
                  <GanttScheduleView
                    activities={activities}
                    wbsNodes={[]}
                    selectedActivityCode={selectedActCode}
                    onSelectActivity={(code) => setSelectedActCode(code)}
                  />
                )}

                {deepDiveTab === 'CONFLICTS' && (
                  <ConflictCenterView
                    conflicts={conflicts}
                    onResolve={(id, notes) => resolveConflict(id, notes)}
                    onInvestigate={(code) => {
                      setSelectedActCode(code);
                      setDeepDiveTab('SCHEDULE');
                    }}
                  />
                )}

                {deepDiveTab === 'UWID' && (
                  <RelationshipGraph activity={activeActivity} />
                )}
              </div>
            </div>
          </div>
        )}
      </main>

      {/* Modals */}
      <VoiceCommandModal
        isOpen={isVoiceModalOpen}
        onClose={() => setIsVoiceModalOpen(false)}
        activities={activities}
        onConfirmUpdate={(actCode, prog, delay) => submitVoiceUpdate(actCode, prog, delay)}
      />

      <UserRoleSwitcherModal
        isOpen={isRoleModalOpen}
        onClose={() => setIsRoleModalOpen(false)}
      />

      <ProjectOnboardModal
        isOpen={isOnboardModalOpen}
        onClose={() => setIsOnboardModalOpen(false)}
        onProjectCreated={() => refreshData()}
        onWipeData={handleWipeData}
        onLoadBenchmark={loadBenchmark}
      />

      <GeminiBrainModal
        isOpen={isGeminiModalOpen}
        onClose={() => setIsGeminiModalOpen(false)}
      />

      {currentProject && (
        <WorkerRegistrationModal
          isOpen={isWorkerModalOpen}
          onClose={() => setIsWorkerModalOpen(false)}
          projectId={currentProject.id}
          onWorkerRegistered={() => refreshData(currentProject.id)}
        />
      )}
    </div>
  );
}
