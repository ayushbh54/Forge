'use client';

import React, { useState } from 'react';
import { Sidebar } from '../components/Sidebar';
import { Header } from '../components/Header';
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
    currentProject,
    activities,
    conflicts,
    workers,
    materials,
    auditLogs,
    loading,
    toastMessage,
    isLabour,
    isSupervisor,
    showToast,
    clockInWorker,
    resolveConflict,
    submitDpr,
    submitVoiceUpdate,
    wipeAllData,
    loadBenchmark,
    refreshData,
  } = workspace;

  // Local UI tab states
  const [activeTab, setActiveTab] = useState<'TRUTH' | 'SCHEDULE' | 'UWID' | 'CONFLICTS' | 'DPR' | 'WORKFORCE' | 'MATERIALS' | 'TRANSLATION' | 'AUDIT'>('TRUTH');
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

  return (
    <div className="min-h-screen bg-background text-on-surface">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed top-20 right-6 z-50 p-3.5 bg-primary text-on-primary rounded-DEFAULT shadow-2xl flex items-center gap-2 text-xs font-bold animate-bounce">
          <span className="material-symbols-outlined text-[18px]">verified</span>
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Header */}
      {currentProject ? (
        <Header
          user={user}
          project={currentProject}
          onOpenVoiceModal={() => setIsVoiceModalOpen(true)}
          onOpenGeminiBrain={() => setIsGeminiModalOpen(true)}
          isMobileHUD={isMobileHUD}
          onToggleMobileHUD={() => setIsMobileHUD(!isMobileHUD)}
        />
      ) : (
        <header className="fixed top-0 left-0 right-0 h-16 bg-surface-container border-b border-surface-container-high px-6 z-40 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="w-8 h-8 rounded-DEFAULT bg-primary-container text-white flex items-center justify-center font-black">N</span>
            <span className="font-bold text-sm text-on-surface">Nirmaan OS — Clean State Project Intelligence</span>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setIsRoleModalOpen(true)}
              className="px-3.5 py-1.5 bg-surface-container hover:bg-surface-container-high text-on-surface text-xs font-semibold rounded-DEFAULT border border-surface-container-high flex items-center gap-1.5"
            >
              <span className="material-symbols-outlined text-[16px]">how_to_reg</span>
              <span>Register / Connect ID</span>
            </button>
            <button
              onClick={() => setIsOnboardModalOpen(true)}
              className="px-4 py-1.5 bg-primary hover:bg-primary-container text-on-primary font-bold text-xs rounded-DEFAULT shadow-sm flex items-center gap-1.5"
            >
              <span className="material-symbols-outlined text-[16px]">add_circle</span>
              <span>Onboard Project / Import P6</span>
            </button>
          </div>
        </header>
      )}

      {/* Sidebar */}
      {currentProject && (
        <Sidebar
          project={currentProject}
          activeConflictsCount={conflicts.filter(c => c.status === 'OPEN').length}
        />
      )}

      {/* Main Container */}
      <main className={`${currentProject ? 'pl-72' : 'pl-0'} pt-16 min-h-screen bg-background`}>
        {/* EMPTY STATE: When NO project or NO activities exist in SQLite */}
        {!currentProject || activities.length === 0 ? (
          <div className="max-w-3xl mx-auto py-16 px-6 flex flex-col items-center text-center gap-6 animate-fade-in">
            <div className="w-20 h-20 rounded-full bg-surface-container-high flex items-center justify-center text-primary border border-surface-container-highest shadow-inner">
              <span className="material-symbols-outlined text-[40px]">dataset</span>
            </div>

            <div>
              <h1 className="text-2xl font-black text-on-surface tracking-tight">
                No Real Project Data Loaded
              </h1>
              <p className="text-sm text-on-surface-variant max-w-lg mx-auto mt-2 leading-relaxed">
                As requested, all dummy data has been purged. Nirmaan OS operates strictly on authentic project data provided by your organization or imported from Primavera P6.
              </p>
            </div>

            <div className="flex flex-wrap items-center justify-center gap-3">
              <button
                onClick={() => setIsRoleModalOpen(true)}
                className="px-5 py-2.5 bg-surface-container hover:bg-surface-container-high text-on-surface border border-surface-container-high font-bold text-xs rounded-DEFAULT flex items-center gap-2 shadow-sm transition-all"
              >
                <span className="material-symbols-outlined text-[17px] text-tertiary">how_to_reg</span>
                <span>Register with Project Unique ID</span>
              </button>

              <button
                onClick={() => setIsOnboardModalOpen(true)}
                className="px-6 py-2.5 bg-primary hover:bg-primary-container text-on-primary font-bold text-xs rounded-DEFAULT shadow-lg flex items-center gap-2 transition-all active:scale-95"
              >
                <span className="material-symbols-outlined text-[18px]">domain_add</span>
                <span>Create Real Project / Import P6</span>
              </button>

              <button
                onClick={loadBenchmark}
                className="px-5 py-2.5 bg-surface-container hover:bg-surface-container-high text-on-surface border border-surface-container-high font-bold text-xs rounded-DEFAULT flex items-center gap-2 transition-all"
              >
                <span className="material-symbols-outlined text-[18px] text-secondary">play_circle</span>
                <span>Load Official Oil India SIH26122 Dataset</span>
              </button>
            </div>

            {/* Architecture Cards */}
            <div className="w-full grid grid-cols-1 sm:grid-cols-3 gap-3 text-left mt-6 pt-6 border-t border-surface-container-high/60">
              <div className="p-4 bg-surface-container-lowest rounded-DEFAULT border border-surface-container-high">
                <span className="material-symbols-outlined text-primary text-[22px] mb-1">upload_file</span>
                <h4 className="font-bold text-xs text-on-surface">Primavera P6 & MS Project</h4>
                <p className="text-[11px] text-on-surface-variant mt-1">Import real XML or XER schedules with full WBS, Floats, and Critical Paths.</p>
              </div>

              <div className="p-4 bg-surface-container-lowest rounded-DEFAULT border border-surface-container-high">
                <span className="material-symbols-outlined text-tertiary text-[22px] mb-1">psychology</span>
                <h4 className="font-bold text-xs text-on-surface">Gemini Autonomous Brain</h4>
                <p className="text-[11px] text-on-surface-variant mt-1">Parallel multimodal reasoning linking Hindi field voice notes to P6 activities.</p>
              </div>

              <div className="p-4 bg-surface-container-lowest rounded-DEFAULT border border-surface-container-high">
                <span className="material-symbols-outlined text-secondary text-[22px] mb-1">badge</span>
                <h4 className="font-bold text-xs text-on-surface">Role-Based Workspaces</h4>
                <p className="text-[11px] text-on-surface-variant mt-1">Labour, Supervisor, Scheduler, QA/QC, and Director adapt automatically.</p>
              </div>
            </div>
          </div>
        ) : isMobileHUD ? (
          /* Mobile Field Viewport */
          <div className="p-6">
            <div className="flex items-center justify-between mb-4 max-w-md mx-auto">
              <span className="text-xs uppercase font-bold text-on-surface-variant font-mono">
                Field Supervisor Viewport ({currentProject.location})
              </span>
              <button onClick={() => setIsMobileHUD(false)} className="text-xs text-primary font-semibold hover:underline">
                Return to Desktop Matrix
              </button>
            </div>
            <MobileFieldHUD
              activity={activeActivity}
              onOpenVoiceModal={() => setIsVoiceModalOpen(true)}
              onQuickProgressAdd={(qty) => {
                submitDpr(activeActivity.activityCode, qty, activeActivity.unit, undefined, 'Quick supervisor progress addition');
              }}
            />
          </div>
        ) : isLabour ? (
          /* Labour / Tradesperson Self-Service Portal */
          <div className="p-6">
            <div className="flex items-center justify-between mb-4 max-w-xl mx-auto">
              <span className="text-xs uppercase font-bold text-on-surface-variant font-mono">
                Workforce Self-Service · {user.name} ({user.role})
              </span>
              <button onClick={() => setIsRoleModalOpen(true)} className="text-xs text-primary font-semibold hover:underline">
                Switch Identity / Project
              </button>
            </div>
            <LabourSelfServiceView
              worker={workers[0] || {
                id: 'WRK-01',
                badgeNumber: 'LAB-NEW',
                name: user.name,
                trade: '6G Pipe Welder (TIG/MIG)',
                skills: ['6G Pipe TIG/MIG', 'API 1104'],
                contractor: 'Site Contractor Gang',
                activeProject: currentProject.id,
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
          /* Desktop Operations Matrix (Stitch UI Primary) */
          <div className="flex flex-col w-full">
            {/* Top Command Banner with Project Meta */}
            <div className="relative w-full overflow-hidden bg-surface-container-low px-space-lg py-space-md border-b border-surface-container-high/60 shadow-sm">
              <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-space-md relative z-10">
                <div className="flex flex-col min-w-0">
                  <div className="flex flex-wrap items-center gap-space-xs text-on-surface-variant text-[11px]">
                    <span className="px-space-xs py-0.5 rounded-DEFAULT bg-surface-container-highest text-on-surface font-mono font-semibold">
                      {currentProject.code}
                    </span>
                    <span>/</span>
                    <span className="font-mono">{activeActivity?.wbsCode || 'WBS 01'}</span>
                    <span>/</span>
                    <span className="text-primary font-semibold truncate max-w-md">
                      {activeActivity?.name || currentProject.name}
                    </span>
                    <span className="mx-1 text-outline">•</span>
                    <span className="text-tertiary font-semibold flex items-center gap-1 font-mono">
                      <span className="w-1.5 h-1.5 rounded-full bg-tertiary"></span>
                      RTK Gateway Active
                    </span>
                  </div>

                  <div className="flex items-center gap-space-md mt-1">
                    <h1 className="text-2xl text-on-surface font-black tracking-tight truncate">
                      Project Truth & Progress Intelligence
                    </h1>
                    <span className="hidden md:inline-flex items-center px-space-sm py-0.5 rounded-full bg-primary-fixed text-on-primary-fixed text-[11px] font-bold uppercase font-mono">
                      {currentProject.contractType}
                    </span>
                  </div>
                </div>

                {/* Top Metrics Strip */}
                <div className="flex flex-wrap items-center gap-space-sm">
                  {/* Evidence Coverage */}
                  <div className="bg-surface-container-lowest px-space-md py-1.5 rounded-DEFAULT border border-surface-container-high flex items-center gap-space-md shadow-sm">
                    <div className="flex flex-col text-right">
                      <span className="text-[10px] text-on-surface-variant uppercase font-bold">Evidence Coverage</span>
                      <span className="font-mono text-base text-on-surface font-bold">
                        {currentProject.evidenceCoverage}<span className="text-on-surface-variant font-normal text-xs">%</span>
                      </span>
                    </div>
                    <div className="w-8 h-8 flex items-center justify-center text-tertiary bg-tertiary-container/10 rounded-full">
                      <span className="material-symbols-outlined text-[19px]">verified</span>
                    </div>
                  </div>

                  {/* Gemini Brain Quick Trigger */}
                  <button
                    onClick={() => setIsGeminiModalOpen(true)}
                    className="h-10 px-3 bg-gradient-to-r from-primary/20 to-tertiary/20 hover:from-primary/30 hover:to-tertiary/30 text-on-surface border border-tertiary/40 rounded-DEFAULT text-xs font-semibold flex items-center gap-1.5 transition-colors shadow-sm"
                  >
                    <span className="material-symbols-outlined text-[18px] text-tertiary">psychology</span>
                    <span>Gemini Brain</span>
                  </button>

                  {/* Onboard / Import P6 */}
                  <button
                    onClick={() => setIsOnboardModalOpen(true)}
                    className="h-10 px-3 bg-surface-container hover:bg-surface-container-high text-on-surface border border-surface-container-high rounded-DEFAULT text-xs font-semibold flex items-center gap-1.5 transition-colors"
                  >
                    <span className="material-symbols-outlined text-[17px]">domain_add</span>
                    <span>Project & P6 Import</span>
                  </button>

                  {/* Switch Role */}
                  <button
                    onClick={() => setIsRoleModalOpen(true)}
                    className="h-10 px-3 bg-surface-container hover:bg-surface-container-high text-on-surface border border-surface-container-high rounded-DEFAULT text-xs font-semibold flex items-center gap-1.5 transition-colors"
                  >
                    <span className="material-symbols-outlined text-[17px]">switch_account</span>
                    <span>Switch Role</span>
                  </button>
                </div>
              </div>

              {/* Module View Tabs */}
              <div className="flex items-center gap-1.5 mt-space-md overflow-x-auto text-xs font-semibold pt-1">
                {[
                  { key: 'TRUTH', label: 'Project Truth & Triangulation', icon: 'monitoring' },
                  { key: 'SCHEDULE', label: 'P6 Master Schedule & WBS', icon: 'calendar_month' },
                  { key: 'UWID', label: 'Universal Work ID (Topology)', icon: 'hub' },
                  { key: 'CONFLICTS', label: `Conflict Center (${conflicts.filter(c => c.status === 'OPEN').length})`, icon: 'warning' },
                  { key: 'DPR', label: 'Daily Construction Log (DPR)', icon: 'history_edu' },
                  { key: 'WORKFORCE', label: `Workforce (${workers.length})`, icon: 'badge' },
                  { key: 'MATERIALS', label: `Materials (${materials.length})`, icon: 'inventory_2' },
                  { key: 'TRANSLATION', label: 'CDE & Translation', icon: 'translate' },
                  { key: 'AUDIT', label: 'Audit Trail', icon: 'verified_user' },
                ].map((tab) => (
                  <button
                    key={tab.key}
                    onClick={() => setActiveTab(tab.key as any)}
                    className={`px-3.5 py-2 rounded-DEFAULT flex items-center gap-1.5 transition-all whitespace-nowrap ${
                      activeTab === tab.key
                        ? 'bg-primary-container text-on-primary font-bold shadow-sm'
                        : 'bg-surface-container text-on-surface-variant hover:text-on-surface hover:bg-surface-container-high'
                    }`}
                  >
                    <span className="material-symbols-outlined text-[17px]">{tab.icon}</span>
                    <span>{tab.label}</span>
                  </button>
                ))}
              </div>
            </div>

            {/* Dynamic View Canvas */}
            <div className="p-space-lg flex flex-col gap-space-lg">
              {activeTab === 'TRUTH' && (
                <div className="flex flex-col gap-space-lg">
                  <TriangulationMatrix
                    activity={activeActivity}
                    onOpenAuditLog={() => setActiveTab('AUDIT')}
                    onRequestLabExpedite={() => showToast('Lab Expedite Notice issued!')}
                  />

                  <ConflictCenterView
                    conflicts={conflicts}
                    onResolve={(id, notes) => resolveConflict(id, notes)}
                    onInvestigate={(code) => {
                      setSelectedActCode(code);
                      setActiveTab('SCHEDULE');
                    }}
                  />
                </div>
              )}

              {activeTab === 'SCHEDULE' && (
                <GanttScheduleView
                  activities={activities}
                  wbsNodes={[]}
                  selectedActivityCode={selectedActCode}
                  onSelectActivity={(code) => setSelectedActCode(code)}
                />
              )}

              {activeTab === 'UWID' && (
                <RelationshipGraph activity={activeActivity} />
              )}

              {activeTab === 'CONFLICTS' && (
                <ConflictCenterView
                  conflicts={conflicts}
                  onResolve={(id, notes) => resolveConflict(id, notes)}
                  onInvestigate={() => setActiveTab('TRUTH')}
                />
              )}

              {activeTab === 'DPR' && (
                <InteractiveDprView
                  activities={activities}
                  onSubmitDpr={(actCode, qty, unit, delay, notes) => {
                    submitDpr(actCode, qty, unit, delay, notes);
                  }}
                />
              )}

              {activeTab === 'WORKFORCE' && (
                <div className="flex flex-col gap-3">
                  <div className="flex justify-end">
                    <button
                      onClick={() => setIsWorkerModalOpen(true)}
                      className="px-4 py-2 bg-primary text-on-primary font-bold text-xs rounded-sm shadow-sm flex items-center gap-1.5"
                    >
                      <span className="material-symbols-outlined text-[16px]">person_add</span>
                      <span>Enroll Real Worker</span>
                    </button>
                  </div>
                  <WorkforceAttendanceView
                    workers={workers}
                    onClockIn={(wId) => clockInWorker(wId)}
                  />
                </div>
              )}

              {activeTab === 'MATERIALS' && (
                <MaterialsStoresView
                  materials={materials}
                  onCreateTransaction={(tx) => {
                    workspace.createMaterialTx(tx);
                  }}
                />
              )}

              {activeTab === 'TRANSLATION' && (
                <TechnicalTranslationView />
              )}

              {activeTab === 'AUDIT' && (
                <div className="bg-surface-container-lowest p-5 rounded-DEFAULT border border-surface-container-high shadow-sm flex flex-col gap-3">
                  <div className="flex items-center justify-between border-b border-surface-container-high pb-3">
                    <h2 className="text-sm font-bold uppercase tracking-wider text-on-surface">
                      Deterministic SQLite Audit Trail
                    </h2>
                    <span className="font-mono text-xs text-tertiary font-bold bg-tertiary/10 px-2.5 py-1 rounded-sm border border-tertiary/20">
                      SHA-256 Ledger Verified ({auditLogs.length} Records)
                    </span>
                  </div>

                  <div className="flex flex-col gap-2 max-h-96 overflow-y-auto">
                    {auditLogs.map((log) => (
                      <div key={log.id} className="p-3 bg-surface-container-low rounded-sm border border-surface-container-high flex items-center justify-between text-xs">
                        <div className="flex flex-col">
                          <span className="font-bold text-on-surface">{log.action} · <span className="text-primary font-mono">{log.entityId}</span></span>
                          <span className="text-[11px] text-on-surface-variant">{log.reason || 'Operation recorded'} (by {log.actorName})</span>
                        </div>
                        <span className="font-mono text-[10px] text-on-surface-variant">{log.timestamp}</span>
                      </div>
                    ))}
                    {auditLogs.length === 0 && (
                      <div className="text-xs text-on-surface-variant p-4 text-center">No audit logs recorded yet.</div>
                    )}
                  </div>
                </div>
              )}
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
