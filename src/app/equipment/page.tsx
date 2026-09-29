'use client';

import React, { useState } from 'react';
import { Sidebar } from '../../components/Sidebar';
import { Header } from '../../components/Header';
import { GeminiBrainModal } from '../../components/GeminiBrainModal';
import { ProjectOnboardModal } from '../../components/ProjectOnboardModal';
import { useWorkspace } from '../../context/WorkspaceContext';

const INITIAL_EQUIPMENT = [
  {
    id: 'EQ-CRANE-04',
    name: 'Tadano GR-500XL (50T Rough Terrain Crane)',
    tag: 'Heavy Lifting · Spool Rigging',
    operator: 'Biren Chetia (Certified Heavy Operator)',
    status: 'ACTIVE_DEPLOYED',
    location: 'Line 24 Trench Corridor (Chainage 14+350)',
    operatingHours: '1,420 hrs',
    fuelLevel: '78%',
    maintenanceDue: 'In 180 hrs',
    associatedAct: 'PIP-L5-024',
  },
  {
    id: 'EQ-PUMP-01',
    name: 'Schwing Stetter S36X Concrete Boom Pump',
    tag: 'Concrete Pouring · Viaduct',
    operator: 'D. Kalita',
    status: 'STANDBY',
    location: 'Central Batching Plant Assam',
    operatingHours: '890 hrs',
    fuelLevel: '92%',
    maintenanceDue: 'In 320 hrs',
    associatedAct: 'ACT-3088',
  },
  {
    id: 'EQ-WELD-GEN-02',
    name: 'Lincoln Electric Dual Vantage 500 Diesel Generator',
    tag: 'Orbital & Downhill Welding',
    operator: 'Tapan Das Gang',
    status: 'ACTIVE_DEPLOYED',
    location: 'Line 24 Pipe Stringing Alignment',
    operatingHours: '2,150 hrs',
    fuelLevel: '65%',
    maintenanceDue: 'Filter swap in 24 hrs',
    associatedAct: 'PIP-L5-024',
  },
  {
    id: 'EQ-EXCAV-07',
    name: 'Komatsu PC210-10M0 Hydraulic Excavator',
    tag: 'Trenching & Shoring Removal',
    operator: 'M. Gogoi',
    status: 'SCHEDULED_MAINTENANCE',
    location: 'Workshop Zone B',
    operatingHours: '3,840 hrs',
    fuelLevel: '40%',
    maintenanceDue: 'Hydraulic seal servicing in progress',
    associatedAct: 'CIV-L5-019',
  },
];

export default function EquipmentPage() {
  const workspace = useWorkspace();
  const { user, currentProject, conflicts, refreshData } = workspace;
  const [equipment] = useState(INITIAL_EQUIPMENT);
  const [isGeminiOpen, setIsGeminiOpen] = useState(false);
  const [isOnboardOpen, setIsOnboardOpen] = useState(false);

  return (
    <div className="min-h-screen bg-background text-on-surface">
      {currentProject ? (
        <Header
          user={user}
          project={currentProject}
          onOpenVoiceModal={() => {}}
          onOpenGeminiBrain={() => setIsGeminiOpen(true)}
          isMobileHUD={false}
          onToggleMobileHUD={() => {}}
        />
      ) : (
        <header className="fixed top-0 left-0 right-0 h-16 bg-surface-container border-b border-surface-container-high px-6 z-40 flex items-center justify-between">
          <span className="font-bold text-sm text-on-surface">Heavy Machinery & Equipment Telemetry</span>
          <button
            onClick={() => setIsOnboardOpen(true)}
            className="px-4 py-2 bg-primary text-on-primary font-bold text-xs rounded-DEFAULT"
          >
            + Onboard Project
          </button>
        </header>
      )}

      {currentProject && (
        <Sidebar
          project={currentProject}
          activeConflictsCount={conflicts.filter(c => c.status === 'OPEN').length}
        />
      )}

      <main className={`${currentProject ? 'pl-72' : 'pl-0'} pt-16 min-h-screen p-space-lg flex flex-col gap-4`}>
        {/* Banner */}
        <div className="p-5 bg-surface-container-low border border-surface-container-high rounded-DEFAULT flex items-center justify-between">
          <div>
            <h1 className="text-base font-bold uppercase tracking-wider text-on-surface">
              Heavy Plant & Equipment Telemetry Hub
            </h1>
            <p className="text-xs text-on-surface-variant font-mono mt-0.5">
              IoT Telematics, Fuel Consumption, Maintenance Schedules & Operator Log · {currentProject?.name || 'Workspace'}
            </p>
          </div>

          <button
            onClick={() => setIsGeminiOpen(true)}
            className="px-3 py-1.5 bg-gradient-to-r from-primary/20 to-tertiary/20 text-on-surface border border-tertiary/40 font-semibold text-xs rounded-DEFAULT flex items-center gap-1.5"
          >
            <span className="material-symbols-outlined text-[16px] text-tertiary">psychology</span>
            <span>Gemini Telematics Audit</span>
          </button>
        </div>

        {/* Equipment Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {equipment.map((eq) => (
            <div key={eq.id} className="p-4 bg-surface-container-lowest rounded-DEFAULT border border-surface-container-high shadow-sm flex flex-col gap-3">
              <div className="flex items-start justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-mono text-primary font-bold text-xs">{eq.id}</span>
                    <span className="text-[11px] text-on-surface-variant font-semibold">· {eq.tag}</span>
                  </div>
                  <h3 className="font-bold text-sm text-on-surface mt-0.5">{eq.name}</h3>
                </div>
                <span className={`px-2 py-0.5 rounded-sm font-mono font-bold text-[10px] ${
                  eq.status === 'ACTIVE_DEPLOYED'
                    ? 'bg-tertiary/20 text-tertiary'
                    : eq.status === 'STANDBY'
                    ? 'bg-primary/20 text-primary'
                    : 'bg-error/20 text-error'
                }`}>
                  {eq.status}
                </span>
              </div>

              <div className="grid grid-cols-3 gap-2 text-xs py-2 border-y border-surface-container-high/60">
                <div>
                  <span className="text-[10px] text-on-surface-variant block uppercase font-mono">Operator</span>
                  <span className="font-semibold text-on-surface truncate block">{eq.operator}</span>
                </div>
                <div>
                  <span className="text-[10px] text-on-surface-variant block uppercase font-mono">Running Hrs</span>
                  <span className="font-mono font-bold text-on-surface">{eq.operatingHours}</span>
                </div>
                <div>
                  <span className="text-[10px] text-on-surface-variant block uppercase font-mono">Fuel Level</span>
                  <span className="font-mono font-bold text-tertiary">{eq.fuelLevel}</span>
                </div>
              </div>

              <div className="flex items-center justify-between text-xs text-on-surface-variant">
                <span className="truncate">Loc: {eq.location}</span>
                <span className="font-mono text-[11px] text-error">{eq.maintenanceDue}</span>
              </div>
            </div>
          ))}
        </div>
      </main>

      <GeminiBrainModal
        isOpen={isGeminiOpen}
        onClose={() => setIsGeminiOpen(false)}
      />

      <ProjectOnboardModal
        isOpen={isOnboardOpen}
        onClose={() => setIsOnboardOpen(false)}
        onProjectCreated={() => refreshData()}
        onWipeData={() => workspace.wipeAllData()}
        onLoadBenchmark={() => workspace.loadBenchmark()}
      />
    </div>
  );
}
