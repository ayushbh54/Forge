'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { Sidebar } from '../components/Sidebar';
import { Header } from '../components/Header';
import { LoginGateway } from '../components/LoginGateway';
import { VoiceCommandModal } from '../components/VoiceCommandModal';
import { UserRoleSwitcherModal } from '../components/UserRoleSwitcherModal';
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
    dprLogs,
    equipment,
    weather,
    isLabour,
    isSupervisor,
    isQAQC,
    isHSE,
    isMaterials,
    isDirector,
    isPlanning,
    showToast,
    submitVoiceUpdate,
    wipeAllData,
    loadBenchmark,
    refreshData,
  } = workspace;

  const [activeCategory, setActiveCategory] = useState<'ALL' | 'FIELD' | 'QUALITY' | 'CONTROLS'>('ALL');
  const [isVoiceModalOpen, setIsVoiceModalOpen] = useState(false);
  const [isRoleModalOpen, setIsRoleModalOpen] = useState(false);
  const [isOnboardModalOpen, setIsOnboardModalOpen] = useState(false);
  const [isWorkerModalOpen, setIsWorkerModalOpen] = useState(false);
  const [isGeminiModalOpen, setIsGeminiModalOpen] = useState(false);

  // IF NOT AUTHENTICATED: Show World-Class Login & Persona Gateway!
  if (!isAuthenticated) {
    return <LoginGateway onLoginSuccess={() => refreshData()} />;
  }

  const handleWipeData = async () => {
    if (confirm('Are you sure you want to wipe all data? The database will be completely empty with ZERO dummy records.')) {
      await wipeAllData();
    }
  };

  // Modular Hub Cards (Amazon / Flipkart Style)
  const modules = [
    {
      id: 'dpr',
      title: 'Daily Construction Log (DPR)',
      subtitle: 'Field Quantities & Shift Delays',
      category: 'FIELD',
      path: '/dpr',
      icon: 'history_edu',
      metric: `${dprLogs.length} DPR Records`,
      badge: 'Daily Log',
      badgeColor: 'bg-primary/15 text-primary',
      description: 'Record installed physical quantities, pipe stringing chainages, and shift notes with full submission history.',
    },
    {
      id: 'workforce',
      title: 'Workforce & Muster Roll',
      subtitle: 'Geofenced Biometric Clock-In',
      category: 'FIELD',
      path: '/workforce',
      icon: 'badge',
      metric: `${workers.filter((w) => w.attendanceStatus !== 'ABSENT').length} / ${workers.length} Present`,
      badge: 'Biometric RTK',
      badgeColor: 'bg-tertiary/15 text-tertiary',
      description: 'Trade-wise attendance, safety certifications, GPS geofence verification, and daily clock-in history.',
    },
    {
      id: 'materials',
      title: 'Materials & Stores Ledger',
      subtitle: 'Digital Supply Chain (GRN / GIN)',
      category: 'FIELD',
      path: '/materials',
      icon: 'inventory_2',
      metric: `${materials.length} Transactions`,
      badge: 'Heat Matched',
      badgeColor: 'bg-secondary/15 text-secondary',
      description: 'Goods receipt and site dispatch tracking linked to pipe heat numbers, MTR test certs, and WBS activities.',
    },
    {
      id: 'equipment',
      title: 'Heavy Plant & Machinery',
      subtitle: 'IoT Telematics & Breakdown Log',
      category: 'FIELD',
      path: '/equipment',
      icon: 'precision_manufacturing',
      metric: `${equipment.length} Plant Assets`,
      badge: 'Telematics',
      badgeColor: 'bg-primary/15 text-primary',
      description: 'Live sensor telematics, fuel consumption, operating hours, and downtime stoppage reporting.',
    },
    {
      id: 'conflicts',
      title: 'Conflict & Risk Center',
      subtitle: 'Site Tolerances & FIDIC Disputes',
      category: 'QUALITY',
      path: '/conflicts',
      icon: 'warning',
      metric: `${conflicts.filter((c) => c.status === 'OPEN').length} Active Flags`,
      badge: 'Triangulation',
      badgeColor: 'bg-error-container text-on-error-container',
      description: 'Automated tolerance breach detection, variance resolution workflows, and permanent closed dispute history.',
    },
    {
      id: 'quality-hse',
      title: 'QA/QC Protocols & HSE',
      subtitle: 'NDT Radiography & PTW Permits',
      category: 'QUALITY',
      path: '/quality-hse',
      icon: 'fact_check',
      metric: '412 Days Zero LTI',
      badge: 'NABL & API',
      badgeColor: 'bg-tertiary/15 text-tertiary',
      description: 'ASTM cube breaks, API weld RT films, hot-work safety permits, and FIDIC Cl. 8.4 weather stoppage logs.',
    },
    {
      id: 'linking-bridge',
      title: 'Schedule-Linking Bridge',
      subtitle: 'AI Hindi Voice to P6 WBS Engine',
      category: 'CONTROLS',
      path: '/linking-bridge',
      icon: 'cable',
      metric: 'Gemini NLP Active',
      badge: 'SIH Core',
      badgeColor: 'bg-primary/15 text-primary',
      description: 'Ingest raw WhatsApp audio and field Hindi memos, extracting entities and auto-mapping to Primavera P6 WBS.',
    },
    {
      id: 'schedule',
      title: 'Master Schedule & P6 WBS',
      subtitle: 'Interactive Gantt & Critical Path',
      category: 'CONTROLS',
      path: '/schedule',
      icon: 'calendar_month',
      metric: `${activities.length} P6 Activities`,
      badge: 'Primavera P6',
      badgeColor: 'bg-secondary/15 text-secondary',
      description: 'Full WBS levels 1-6 Gantt chart, float analysis, critical path indicators, and progress triangulation.',
    },
  ];

  const filteredModules = modules.filter((m) => {
    if (activeCategory === 'ALL') return true;
    return m.category === activeCategory;
  });

  return (
    <div className="min-h-screen bg-background text-on-surface">
      {/* Top Header */}
      {currentProject ? (
        <Header
          user={user}
          project={currentProject}
          onOpenVoiceModal={() => setIsVoiceModalOpen(true)}
          onOpenGeminiBrain={() => setIsGeminiModalOpen(true)}
          isMobileHUD={false}
          onToggleMobileHUD={() => {}}
        />
      ) : (
        <header className="fixed top-0 left-0 right-0 h-16 bg-surface-container border-b border-surface-container-high px-6 z-40 flex items-center justify-between">
          <span className="font-bold text-sm text-on-surface">Nirmaan OS — Construction Intelligence</span>
          <button
            onClick={() => setIsOnboardModalOpen(true)}
            className="px-4 py-2 bg-primary text-on-primary font-bold text-xs rounded-lg"
          >
            + Onboard Project
          </button>
        </header>
      )}

      {/* Side Navigation Bar */}
      {currentProject && (
        <Sidebar
          project={currentProject}
          activeConflictsCount={conflicts.filter((c) => c.status === 'OPEN').length}
        />
      )}

      {/* Main Spacious Content */}
      <main
        className={`${
          currentProject ? (sidebarCollapsed ? 'pl-[72px]' : 'pl-72') : 'pl-0'
        } pt-16 min-h-screen p-space-lg flex flex-col gap-6 transition-all duration-300 ease-in-out`}
      >
        {!currentProject ? (
          <div className="max-w-xl mx-auto py-20 text-center flex flex-col items-center gap-4">
            <div className="w-16 h-16 rounded-full bg-surface-container-high flex items-center justify-center text-primary">
              <span className="material-symbols-outlined text-[36px]">hub</span>
            </div>
            <h2 className="text-xl font-black text-on-surface">Welcome to Nirmaan OS</h2>
            <p className="text-xs text-on-surface-variant max-w-md">
              No project workspace is currently linked. Connect to Oil India Duliajan or initialize a benchmark project to begin.
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setIsOnboardModalOpen(true)}
                className="px-5 py-2.5 bg-primary text-on-primary font-bold text-xs rounded-lg shadow-sm"
              >
                + Onboard New Project
              </button>
              <button
                onClick={() => loadBenchmark()}
                className="px-5 py-2.5 bg-surface-container hover:bg-surface-container-high text-on-surface font-bold text-xs rounded-lg border border-surface-container-high"
              >
                Load Duliajan Benchmark
              </button>
            </div>
          </div>
        ) : (
          <div className="flex flex-col gap-6">
            {/* 1. Clean Personalized Greeting Banner */}
            <div className="p-5 sm:p-6 bg-surface-container-low border border-surface-container-high rounded-2xl flex flex-col md:flex-row md:items-center justify-between gap-4">
              <div>
                <div className="flex items-center gap-2">
                  <span className="text-base sm:text-lg font-bold text-on-surface">
                    Welcome back, {user.name} 👋
                  </span>
                  <span className="px-2.5 py-0.5 rounded-full text-[10px] font-mono font-bold bg-primary/15 text-primary border border-primary/20">
                    {user.role}
                  </span>
                </div>
                <p className="text-xs text-on-surface-variant mt-1 font-mono">
                  {currentProject.name} · Section C-4 / Station 14+200 Alignment
                </p>
              </div>

              <div className="flex flex-wrap items-center gap-2">
                <button
                  onClick={() => setIsRoleModalOpen(true)}
                  className="px-3.5 py-2 bg-surface-container hover:bg-surface-container-high text-on-surface border border-surface-container-high font-semibold text-xs rounded-xl flex items-center gap-1.5 transition-all shadow-sm"
                >
                  <span className="material-symbols-outlined text-[16px] text-primary">switch_account</span>
                  <span>Switch Role</span>
                </button>

                <button
                  onClick={() => setIsGeminiModalOpen(true)}
                  className="px-3.5 py-2 bg-gradient-to-r from-primary/20 to-tertiary/20 text-on-surface border border-tertiary/40 font-semibold text-xs rounded-xl flex items-center gap-1.5 transition-all shadow-sm"
                >
                  <span className="material-symbols-outlined text-[16px] text-tertiary">psychology</span>
                  <span>Gemini AI Brain</span>
                </button>
              </div>
            </div>

            {/* 2. Blinkit-Style Quick Action Dock (1-Tap Fast Launch) */}
            <div className="flex flex-col gap-2">
              <span className="text-xs font-bold uppercase tracking-wider text-on-surface-variant">
                ⚡ Quick Field Actions (Instant Access)
              </span>
              <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
                <Link
                  href="/dpr"
                  className="p-3.5 bg-surface-container-lowest hover:bg-surface-container-low border border-surface-container-high hover:border-primary/50 rounded-xl flex items-center gap-3 transition-all group shadow-sm"
                >
                  <div className="w-9 h-9 rounded-lg bg-primary/10 flex items-center justify-center text-primary group-hover:bg-primary group-hover:text-on-primary transition-all shrink-0">
                    <span className="material-symbols-outlined text-[20px]">edit_note</span>
                  </div>
                  <div className="overflow-hidden">
                    <span className="text-xs font-bold text-on-surface block truncate">Submit DPR</span>
                    <span className="text-[10px] text-on-surface-variant block truncate">Daily Shift Log</span>
                  </div>
                </Link>

                <Link
                  href="/workforce"
                  className="p-3.5 bg-surface-container-lowest hover:bg-surface-container-low border border-surface-container-high hover:border-tertiary/50 rounded-xl flex items-center gap-3 transition-all group shadow-sm"
                >
                  <div className="w-9 h-9 rounded-lg bg-tertiary/10 flex items-center justify-center text-tertiary group-hover:bg-tertiary group-hover:text-on-tertiary transition-all shrink-0">
                    <span className="material-symbols-outlined text-[20px]">fingerprint</span>
                  </div>
                  <div className="overflow-hidden">
                    <span className="text-xs font-bold text-on-surface block truncate">Attendance</span>
                    <span className="text-[10px] text-on-surface-variant block truncate">Punch Clock-In</span>
                  </div>
                </Link>

                <Link
                  href="/materials"
                  className="p-3.5 bg-surface-container-lowest hover:bg-surface-container-low border border-surface-container-high hover:border-secondary/50 rounded-xl flex items-center gap-3 transition-all group shadow-sm"
                >
                  <div className="w-9 h-9 rounded-lg bg-secondary/10 flex items-center justify-center text-secondary group-hover:bg-secondary group-hover:text-on-secondary transition-all shrink-0">
                    <span className="material-symbols-outlined text-[20px]">local_shipping</span>
                  </div>
                  <div className="overflow-hidden">
                    <span className="text-xs font-bold text-on-surface block truncate">Post Material</span>
                    <span className="text-[10px] text-on-surface-variant block truncate">Issue GIN Note</span>
                  </div>
                </Link>

                <Link
                  href="/conflicts"
                  className="p-3.5 bg-surface-container-lowest hover:bg-surface-container-low border border-surface-container-high hover:border-error/50 rounded-xl flex items-center gap-3 transition-all group shadow-sm"
                >
                  <div className="w-9 h-9 rounded-lg bg-error/10 flex items-center justify-center text-error group-hover:bg-error group-hover:text-on-error transition-all shrink-0">
                    <span className="material-symbols-outlined text-[20px]">report_problem</span>
                  </div>
                  <div className="overflow-hidden">
                    <span className="text-xs font-bold text-on-surface block truncate">Flag Issue</span>
                    <span className="text-[10px] text-on-surface-variant block truncate">Tolerance Breach</span>
                  </div>
                </Link>

                <button
                  onClick={() => setIsVoiceModalOpen(true)}
                  className="p-3.5 bg-surface-container-lowest hover:bg-surface-container-low border border-surface-container-high hover:border-primary/50 rounded-xl flex items-center gap-3 transition-all group shadow-sm text-left col-span-2 sm:col-span-1"
                >
                  <div className="w-9 h-9 rounded-lg bg-primary/10 flex items-center justify-center text-primary group-hover:bg-primary group-hover:text-on-primary transition-all shrink-0">
                    <span className="material-symbols-outlined text-[20px]">mic</span>
                  </div>
                  <div className="overflow-hidden">
                    <span className="text-xs font-bold text-on-surface block truncate">Voice Update</span>
                    <span className="text-[10px] text-on-surface-variant block truncate">Hindi / Audio</span>
                  </div>
                </button>
              </div>
            </div>

            {/* 3. Role-Tailored "Today's Mission" Hero Banner */}
            <div className="p-5 sm:p-6 bg-surface-container-lowest border border-surface-container-high rounded-2xl shadow-sm flex flex-col gap-4">
              <div className="flex items-center justify-between border-b border-surface-container-high pb-3">
                <span className="text-xs font-bold uppercase tracking-wider text-on-surface flex items-center gap-2">
                  <span className="material-symbols-outlined text-primary text-[18px]">target</span>
                  Today's Mission & Key Metrics for {user.role}
                </span>
                <span className="text-xs text-on-surface-variant font-mono">
                  Real-time Site Status
                </span>
              </div>

              {/* Dynamic Role-Specific Focus */}
              {isSupervisor ? (
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant">Piping Lower-In Target</span>
                    <div className="my-2">
                      <span className="text-2xl font-black font-mono text-tertiary">64.5 m</span>
                      <span className="text-xs text-on-surface-variant block mt-0.5">Installed today (Planned: 60.0m)</span>
                    </div>
                    <Link href="/dpr" className="text-xs font-bold text-primary hover:underline flex items-center gap-1">
                      <span>Submit Shift DPR →</span>
                    </Link>
                  </div>

                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant">Active Field Gangs</span>
                    <div className="my-2">
                      <span className="text-2xl font-black font-mono text-on-surface">6 Gangs</span>
                      <span className="text-xs text-on-surface-variant block mt-0.5">38 certified welders on alignment</span>
                    </div>
                    <Link href="/workforce" className="text-xs font-bold text-primary hover:underline flex items-center gap-1">
                      <span>View Muster Roll →</span>
                    </Link>
                  </div>

                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-secondary">Active Store Bottleneck</span>
                    <div className="my-2">
                      <span className="text-2xl font-black font-mono text-secondary">6 Spools</span>
                      <span className="text-xs text-on-surface-variant block mt-0.5">Forged elbows waiting for tie-in</span>
                    </div>
                    <Link href="/materials" className="text-xs font-bold text-secondary hover:underline flex items-center gap-1">
                      <span>Inspect Store Ledger →</span>
                    </Link>
                  </div>
                </div>
              ) : isQAQC ? (
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant">AUT Weld Examination</span>
                    <div className="my-2">
                      <span className="text-2xl font-black font-mono text-tertiary">95.4%</span>
                      <span className="text-xs text-on-surface-variant block mt-0.5">42 / 44 Joints cleared under API 1104</span>
                    </div>
                    <Link href="/quality-hse" className="text-xs font-bold text-primary hover:underline flex items-center gap-1">
                      <span>Review NDT Queue →</span>
                    </Link>
                  </div>

                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-error">Quality Hold Points</span>
                    <div className="my-2">
                      <span className="text-2xl font-black font-mono text-error">1 Active</span>
                      <span className="text-xs text-on-surface-variant block mt-0.5">Pier 24 concrete break pending 28-day</span>
                    </div>
                    <Link href="/quality-hse" className="text-xs font-bold text-error hover:underline flex items-center gap-1">
                      <span>Expedite NABL Lab →</span>
                    </Link>
                  </div>

                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant">Non-Conformance Reports</span>
                    <div className="my-2">
                      <span className="text-2xl font-black font-mono text-tertiary">0 Active</span>
                      <span className="text-xs text-on-surface-variant block mt-0.5">All tolerances compliant with FIDIC specs</span>
                    </div>
                    <Link href="/conflicts" className="text-xs font-bold text-primary hover:underline flex items-center gap-1">
                      <span>View Tolerance Logs →</span>
                    </Link>
                  </div>
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant">Schedule Performance (SPI)</span>
                    <div className="my-2">
                      <span className="text-2xl font-black font-mono text-tertiary">{currentProject.spi || 0.94}</span>
                      <span className="text-xs text-on-surface-variant block mt-0.5">On Track (Threshold &gt; 0.90)</span>
                    </div>
                    <Link href="/schedule" className="text-xs font-bold text-primary hover:underline flex items-center gap-1">
                      <span>Open Master Schedule →</span>
                    </Link>
                  </div>

                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant">Cost Index (CPI)</span>
                    <div className="my-2">
                      <span className="text-2xl font-black font-mono text-tertiary">{currentProject.cpi || 1.02}</span>
                      <span className="text-xs text-on-surface-variant block mt-0.5">Under Budget (₹0.98 actual per ₹1.00)</span>
                    </div>
                    <Link href="/schedule" className="text-xs font-bold text-primary hover:underline flex items-center gap-1">
                      <span>View EVM Analysis →</span>
                    </Link>
                  </div>

                  <div className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high flex flex-col justify-between">
                    <span className="text-[11px] font-bold uppercase text-on-surface-variant">FIDIC Cl. 8.4 Delay Shield</span>
                    <div className="my-2">
                      <span className="text-2xl font-black font-mono text-primary">0 Claims</span>
                      <span className="text-xs text-on-surface-variant block mt-0.5">100% Defended against contractor slippage</span>
                    </div>
                    <Link href="/conflicts" className="text-xs font-bold text-primary hover:underline flex items-center gap-1">
                      <span>Open Conflict Center →</span>
                    </Link>
                  </div>
                </div>
              )}
            </div>

            {/* 4. Instagram / Blinkit Live Telemetry Reel (Single Horizontal Slider) */}
            <div className="flex flex-col gap-2">
              <span className="text-xs font-bold uppercase tracking-wider text-on-surface-variant">
                📡 Live Site Sensors & Geofence Reel
              </span>
              <div className="flex items-center gap-3 overflow-x-auto pb-2 scrollbar-thin">
                <div className="px-3.5 py-2 rounded-xl bg-surface-container-lowest border border-surface-container-high flex items-center gap-2.5 whitespace-nowrap shadow-sm shrink-0">
                  <span className="w-2.5 h-2.5 rounded-full bg-tertiary animate-pulse" />
                  <span className="text-xs font-bold text-on-surface">RTK Geofence: Active</span>
                  <span className="text-[10px] font-mono text-on-surface-variant">27.4825° N, 95.3225° E</span>
                </div>

                <div className="px-3.5 py-2 rounded-xl bg-surface-container-lowest border border-surface-container-high flex items-center gap-2.5 whitespace-nowrap shadow-sm shrink-0">
                  <span className="material-symbols-outlined text-[16px] text-secondary">cloud</span>
                  <span className="text-xs font-bold text-on-surface">Rainfall Telemetry: 45.0 mm</span>
                  <span className="text-[10px] font-mono text-secondary">FIDIC Cl. 8.4(c) Active</span>
                </div>

                <div className="px-3.5 py-2 rounded-xl bg-surface-container-lowest border border-surface-container-high flex items-center gap-2.5 whitespace-nowrap shadow-sm shrink-0">
                  <span className="material-symbols-outlined text-[16px] text-tertiary">groups</span>
                  <span className="text-xs font-bold text-on-surface">Muster Roll: {workers.filter((w) => w.attendanceStatus !== 'ABSENT').length} Present</span>
                  <span className="text-[10px] font-mono text-tertiary">98.2% Facial Auth</span>
                </div>

                <div className="px-3.5 py-2 rounded-xl bg-surface-container-lowest border border-surface-container-high flex items-center gap-2.5 whitespace-nowrap shadow-sm shrink-0">
                  <span className="material-symbols-outlined text-[16px] text-primary">precision_manufacturing</span>
                  <span className="text-xs font-bold text-on-surface">Machinery: {equipment.length} Units</span>
                  <span className="text-[10px] font-mono text-on-surface-variant">8 Deployed Online</span>
                </div>

                <div className="px-3.5 py-2 rounded-xl bg-surface-container-lowest border border-surface-container-high flex items-center gap-2.5 whitespace-nowrap shadow-sm shrink-0">
                  <span className="material-symbols-outlined text-[16px] text-tertiary">health_and_safety</span>
                  <span className="text-xs font-bold text-on-surface">HSE Safety: Zero LTI</span>
                  <span className="text-[10px] font-mono text-tertiary">412 Safe Days</span>
                </div>
              </div>
            </div>

            {/* 5. Amazon / Flipkart Style Category Filter & Modular Hub */}
            <div className="flex flex-col gap-4">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div>
                  <h3 className="text-sm font-bold uppercase tracking-wider text-on-surface">
                    Enterprise Construction Modules
                  </h3>
                  <p className="text-xs text-on-surface-variant">
                    Access dedicated, uncluttered workspaces for each construction function
                  </p>
                </div>

                {/* Category Pills */}
                <div className="flex bg-surface-container rounded-lg p-0.5 border border-surface-container-high text-xs">
                  <button
                    onClick={() => setActiveCategory('ALL')}
                    className={`px-3 py-1 rounded font-semibold transition-all ${
                      activeCategory === 'ALL'
                        ? 'bg-primary text-on-primary shadow-sm font-bold'
                        : 'text-on-surface-variant hover:text-on-surface'
                    }`}
                  >
                    All ({modules.length})
                  </button>
                  <button
                    onClick={() => setActiveCategory('FIELD')}
                    className={`px-3 py-1 rounded font-semibold transition-all ${
                      activeCategory === 'FIELD'
                        ? 'bg-primary text-on-primary shadow-sm font-bold'
                        : 'text-on-surface-variant hover:text-on-surface'
                    }`}
                  >
                    Field Ops (4)
                  </button>
                  <button
                    onClick={() => setActiveCategory('QUALITY')}
                    className={`px-3 py-1 rounded font-semibold transition-all ${
                      activeCategory === 'QUALITY'
                        ? 'bg-primary text-on-primary shadow-sm font-bold'
                        : 'text-on-surface-variant hover:text-on-surface'
                    }`}
                  >
                    Quality & Safety (2)
                  </button>
                  <button
                    onClick={() => setActiveCategory('CONTROLS')}
                    className={`px-3 py-1 rounded font-semibold transition-all ${
                      activeCategory === 'CONTROLS'
                        ? 'bg-primary text-on-primary shadow-sm font-bold'
                        : 'text-on-surface-variant hover:text-on-surface'
                    }`}
                  >
                    Controls & AI (2)
                  </button>
                </div>
              </div>

              {/* Module Cards Grid */}
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                {filteredModules.map((mod) => (
                  <Link
                    key={mod.id}
                    href={mod.path}
                    className="p-5 rounded-2xl bg-surface-container-lowest border border-surface-container-high hover:border-primary/50 transition-all duration-200 hover:-translate-y-1 hover:shadow-lg flex flex-col justify-between group"
                  >
                    <div>
                      <div className="flex items-start justify-between gap-2 mb-3">
                        <div className="w-10 h-10 rounded-xl bg-surface-container-low flex items-center justify-center text-primary group-hover:bg-primary group-hover:text-on-primary transition-all shadow-sm">
                          <span className="material-symbols-outlined text-[22px]">{mod.icon}</span>
                        </div>
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-mono font-bold ${mod.badgeColor}`}>
                          {mod.badge}
                        </span>
                      </div>

                      <h4 className="font-bold text-sm text-on-surface group-hover:text-primary transition-colors">
                        {mod.title}
                      </h4>
                      <span className="text-[10px] text-on-surface-variant uppercase font-mono tracking-wider block mt-0.5">
                        {mod.subtitle}
                      </span>
                      <p className="text-xs text-on-surface-variant mt-2 line-clamp-2 leading-relaxed">
                        {mod.description}
                      </p>
                    </div>

                    <div className="mt-4 pt-3 border-t border-surface-container-high flex items-center justify-between">
                      <span className="text-xs font-bold font-mono text-tertiary">
                        {mod.metric}
                      </span>
                      <span className="text-xs font-semibold text-primary flex items-center gap-1 group-hover:translate-x-1 transition-transform">
                        <span>Open</span>
                        <span className="material-symbols-outlined text-[14px]">arrow_forward</span>
                      </span>
                    </div>
                  </Link>
                ))}
              </div>
            </div>

            {/* 6. Recent Field Activity & Audit Ledger (Quick History Jump) */}
            <div className="border border-surface-container-high rounded-2xl bg-surface-container-lowest p-5 shadow-sm flex flex-col gap-4">
              <div className="flex items-center justify-between border-b border-surface-container-high pb-3">
                <div className="flex items-center gap-2">
                  <span className="material-symbols-outlined text-primary text-[20px]">history</span>
                  <h3 className="text-sm font-bold text-on-surface">
                    Recent Field Actions & Audit Trail
                  </h3>
                </div>
                <span className="text-xs text-on-surface-variant font-mono">
                  Immutable SQLite Records
                </span>
              </div>

              <div className="flex flex-col divide-y divide-surface-container-high/40">
                {auditLogs.slice(0, 4).map((log) => (
                  <div key={log.id} className="py-3 flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs">
                    <div className="flex items-start gap-2.5">
                      <span className="material-symbols-outlined text-tertiary text-[16px] shrink-0 mt-0.5">
                        check_circle
                      </span>
                      <div>
                        <span className="font-bold text-on-surface">{log.actorName}</span>
                        <span className="text-on-surface-variant"> ({log.actorRole})</span>
                        <p className="text-on-surface-variant mt-0.5">{log.reason || log.action}</p>
                      </div>
                    </div>
                    <span className="text-[11px] font-mono text-on-surface-variant self-end sm:self-center shrink-0">
                      {log.timestamp}
                    </span>
                  </div>
                ))}
              </div>

              {/* Quick History Navigation Dock */}
              <div className="pt-3 border-t border-surface-container-high flex flex-wrap items-center justify-between gap-3 text-xs">
                <span className="text-on-surface-variant text-[11px]">
                  Need full transaction history? Jump directly into dedicated module ledgers:
                </span>
                <div className="flex flex-wrap items-center gap-2">
                  <Link
                    href="/dpr"
                    className="px-3 py-1.5 bg-surface-container hover:bg-surface-container-high text-on-surface rounded-lg font-medium transition-colors"
                  >
                    DPR History →
                  </Link>
                  <Link
                    href="/workforce"
                    className="px-3 py-1.5 bg-surface-container hover:bg-surface-container-high text-on-surface rounded-lg font-medium transition-colors"
                  >
                    Muster Roll History →
                  </Link>
                  <Link
                    href="/materials"
                    className="px-3 py-1.5 bg-surface-container hover:bg-surface-container-high text-on-surface rounded-lg font-medium transition-colors"
                  >
                    Materials Ledger →
                  </Link>
                  <Link
                    href="/conflicts"
                    className="px-3 py-1.5 bg-surface-container hover:bg-surface-container-high text-on-surface rounded-lg font-medium transition-colors"
                  >
                    Conflict History →
                  </Link>
                </div>
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
