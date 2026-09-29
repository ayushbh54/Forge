'use client';

import React, { useState } from 'react';

interface ProjectOnboardModalProps {
  isOpen: boolean;
  onClose: () => void;
  onProjectCreated: (project: any) => void;
  onWipeData: () => void;
  onLoadBenchmark: () => void;
}

export const ProjectOnboardModal: React.FC<ProjectOnboardModalProps> = ({
  isOpen,
  onClose,
  onProjectCreated,
  onWipeData,
  onLoadBenchmark,
}) => {
  const [tab, setTab] = useState<'CREATE' | 'IMPORT_P6' | 'MANAGEMENT'>('CREATE');

  // Create Project State
  const [projectId, setProjectId] = useState('');
  const [projectName, setProjectName] = useState('');
  const [client, setClient] = useState('');
  const [contractor, setContractor] = useState('');
  const [contractType, setContractType] = useState('FIDIC Red Book');
  const [location, setLocation] = useState('');
  const [budget, setBudget] = useState<number>(0);

  // Import State
  const [targetProjectId, setTargetProjectId] = useState('');
  const [importFormat, setImportFormat] = useState<'CSV_TABLE' | 'P6_XML'>('CSV_TABLE');
  const [scheduleText, setScheduleText] = useState(
`ActivityID, Name, WBS, Discipline, Duration, Float, Critical, PlannedQty, Unit
PIP-L5-024, Pipe Installation — Trunk Line 24, 03.02.04, PIPING, 18, 2, true, 420, meters
ACT-3088, Segment B-14 Post-Tensioned Pier Cap, 03.02.04, CIVIL, 20, 0, true, 180, cu.m
CIV-L5-019, Trench Excavation & Shoring, 03.02.04, CIVIL, 18, 5, false, 650, meters
ELC-L5-042, Cathodic Protection ICCP Stations, 04, ELECTRICAL, 19, 4, false, 12, stations`
  );

  const [loading, setLoading] = useState(false);
  const [msg, setMsg] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleCreateProject = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!projectId || !projectName) {
      setMsg('Project ID and Name are required!');
      return;
    }
    setLoading(true);
    try {
      const res = await fetch('/api/projects', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id: projectId,
          name: projectName,
          client,
          contractorJV: contractor,
          contractType,
          location,
          budget,
        }),
      });
      const data = await res.json();
      if (data.success) {
        onProjectCreated(data.project);
        onClose();
      } else {
        setMsg(data.error || 'Failed to create project');
      }
    } catch (err: any) {
      setMsg(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleImportSchedule = async () => {
    if (!targetProjectId) {
      setMsg('Please enter target Project ID to link schedule activities');
      return;
    }
    setLoading(true);
    try {
      const res = await fetch('/api/activities', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          projectId: targetProjectId,
          importMode: true,
          rawScheduleContent: scheduleText,
          format: importFormat,
        }),
      });
      const data = await res.json();
      if (data.success) {
        alert(data.message);
        onClose();
      } else {
        setMsg(data.error || 'Failed to import activities');
      }
    } catch (err: any) {
      setMsg(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-background/85 backdrop-blur-md animate-fade-in">
      <div className="w-full max-w-2xl bg-surface-container-lowest border border-surface-container-high rounded-xl shadow-2xl overflow-hidden flex flex-col">
        {/* Header */}
        <div className="p-4 bg-surface-container flex items-center justify-between border-b border-surface-container-high">
          <div className="flex items-center gap-2">
            <span className="w-8 h-8 rounded-DEFAULT bg-primary-container text-white flex items-center justify-center font-bold">
              <span className="material-symbols-outlined text-[19px]">domain_add</span>
            </span>
            <div>
              <h2 className="font-bold text-sm text-on-surface">Real Project Workspace Onboarding</h2>
              <p className="text-[11px] text-on-surface-variant font-mono">
                No Fake Data · Direct SQLite Database Storage
              </p>
            </div>
          </div>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center text-on-surface-variant hover:text-on-surface rounded-DEFAULT hover:bg-surface-container-high transition-colors">
            <span className="material-symbols-outlined text-[18px]">close</span>
          </button>
        </div>

        {/* Tab Selector */}
        <div className="flex items-center gap-2 px-5 pt-3 border-b border-surface-container-high text-xs font-semibold">
          <button
            onClick={() => setTab('CREATE')}
            className={`pb-2.5 px-3 border-b-2 transition-all ${tab === 'CREATE' ? 'border-primary text-primary font-bold' : 'border-transparent text-on-surface-variant'}`}
          >
            Create Real Project
          </button>
          <button
            onClick={() => setTab('IMPORT_P6')}
            className={`pb-2.5 px-3 border-b-2 transition-all ${tab === 'IMPORT_P6' ? 'border-primary text-primary font-bold' : 'border-transparent text-on-surface-variant'}`}
          >
            Import Primavera P6 / MS Project
          </button>
          <button
            onClick={() => setTab('MANAGEMENT')}
            className={`pb-2.5 px-3 border-b-2 transition-all ${tab === 'MANAGEMENT' ? 'border-error text-error font-bold' : 'border-transparent text-on-surface-variant'}`}
          >
            Data Management & Benchmark
          </button>
        </div>

        {/* Content */}
        <div className="p-5 flex flex-col gap-4 max-h-[75vh] overflow-y-auto text-xs">
          {msg && (
            <div className="p-2.5 bg-error-container/20 border border-error/40 rounded-sm text-error font-semibold">
              {msg}
            </div>
          )}

          {tab === 'CREATE' && (
            <form onSubmit={handleCreateProject} className="flex flex-col gap-3">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="text-[10px] font-bold text-on-surface-variant uppercase block mb-1">
                    Project Unique ID * (e.g. OIL-CORR-01)
                  </label>
                  <input
                    type="text"
                    required
                    value={projectId}
                    onChange={(e) => setProjectId(e.target.value.toUpperCase())}
                    placeholder="OIL-PL-024"
                    className="w-full p-2 bg-surface-container-low border border-surface-container-high rounded-sm text-on-surface font-mono font-bold uppercase"
                  />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-on-surface-variant uppercase block mb-1">
                    Project Name / Scope *
                  </label>
                  <input
                    type="text"
                    required
                    value={projectName}
                    onChange={(e) => setProjectName(e.target.value)}
                    placeholder="Crude Oil Pipeline Package II"
                    className="w-full p-2 bg-surface-container-low border border-surface-container-high rounded-sm text-on-surface"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="text-[10px] font-bold text-on-surface-variant uppercase block mb-1">Client Name</label>
                  <input
                    type="text"
                    value={client}
                    onChange={(e) => setClient(e.target.value)}
                    placeholder="Oil India Limited (OIL)"
                    className="w-full p-2 bg-surface-container-low border border-surface-container-high rounded-sm text-on-surface"
                  />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-on-surface-variant uppercase block mb-1">Contractor / JV</label>
                  <input
                    type="text"
                    value={contractor}
                    onChange={(e) => setContractor(e.target.value)}
                    placeholder="EPC Joint Venture"
                    className="w-full p-2 bg-surface-container-low border border-surface-container-high rounded-sm text-on-surface"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="text-[10px] font-bold text-on-surface-variant uppercase block mb-1">Site Location</label>
                  <input
                    type="text"
                    value={location}
                    onChange={(e) => setLocation(e.target.value)}
                    placeholder="Duliajan, Assam"
                    className="w-full p-2 bg-surface-container-low border border-surface-container-high rounded-sm text-on-surface"
                  />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-on-surface-variant uppercase block mb-1">Contract Type</label>
                  <input
                    type="text"
                    value={contractType}
                    onChange={(e) => setContractType(e.target.value)}
                    placeholder="FIDIC Red Book Cl. 8.4"
                    className="w-full p-2 bg-surface-container-low border border-surface-container-high rounded-sm text-on-surface"
                  />
                </div>
              </div>

              <div className="flex justify-end gap-2 mt-2">
                <button type="button" onClick={onClose} className="px-4 py-2 text-on-surface-variant font-semibold">Cancel</button>
                <button type="submit" disabled={loading} className="px-5 py-2 bg-primary hover:bg-primary-container text-on-primary font-bold rounded-DEFAULT shadow-sm">
                  {loading ? 'Creating...' : 'Create & Save to Database'}
                </button>
              </div>
            </form>
          )}

          {tab === 'IMPORT_P6' && (
            <div className="flex flex-col gap-3">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="text-[10px] font-bold text-on-surface-variant uppercase block mb-1">
                    Target Project ID *
                  </label>
                  <input
                    type="text"
                    value={targetProjectId}
                    onChange={(e) => setTargetProjectId(e.target.value.toUpperCase())}
                    placeholder="e.g. PRJ-8840 or OIL-PL-024"
                    className="w-full p-2 bg-surface-container-low border border-surface-container-high rounded-sm text-on-surface font-mono font-bold"
                  />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-on-surface-variant uppercase block mb-1">
                    Schedule Format
                  </label>
                  <select
                    value={importFormat}
                    onChange={(e) => setImportFormat(e.target.value as any)}
                    className="w-full p-2 bg-surface-container-low border border-surface-container-high rounded-sm text-on-surface"
                  >
                    <option value="CSV_TABLE">CSV / Table (ActivityID, Name, WBS...)</option>
                    <option value="P6_XML">Primavera P6 XML Export</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="text-[10px] font-bold text-on-surface-variant uppercase block mb-1">
                  Paste Schedule Content (Or drop P6 export)
                </label>
                <textarea
                  rows={6}
                  value={scheduleText}
                  onChange={(e) => setScheduleText(e.target.value)}
                  className="w-full p-2.5 bg-surface-container-low border border-surface-container-high rounded-sm font-mono text-[11px] text-on-surface focus:outline-none focus:ring-1 focus:ring-primary"
                />
              </div>

              <div className="flex justify-end gap-2">
                <button type="button" onClick={onClose} className="px-4 py-2 text-on-surface-variant font-semibold">Cancel</button>
                <button onClick={handleImportSchedule} disabled={loading} className="px-5 py-2 bg-primary hover:bg-primary-container text-on-primary font-bold rounded-DEFAULT shadow-sm">
                  {loading ? 'Importing...' : 'Parse & Save Real Activities'}
                </button>
              </div>
            </div>
          )}

          {tab === 'MANAGEMENT' && (
            <div className="flex flex-col gap-4">
              <div className="p-4 bg-surface-container-low rounded-DEFAULT border border-surface-container-high flex flex-col gap-2">
                <span className="font-bold text-xs text-on-surface uppercase">Wipe All Data (100% Clean Empty Slate)</span>
                <p className="text-on-surface-variant text-[11px]">
                  Removes all existing mock/test data from the local SQLite database (`data/nirmaan.db`). The app will show true production empty states until you enter real project data.
                </p>
                <div>
                  <button
                    onClick={onWipeData}
                    className="px-4 py-2 bg-error text-white font-bold rounded-sm hover:opacity-90 transition-opacity"
                  >
                    Wipe Database Clean (Zero Dummy Data)
                  </button>
                </div>
              </div>

              <div className="p-4 bg-surface-container-low rounded-DEFAULT border border-primary/30 flex flex-col gap-2">
                <span className="font-bold text-xs text-primary uppercase">Load Oil India Limited (OIL) SIH26122 Dataset</span>
                <p className="text-on-surface-variant text-[11px]">
                  Loads the official SIH26122 benchmark project (`Trunk Crude Oil Pipeline & Terminal Expansion Package II`, `PIP-L5-024`, ASTM lab break tests, and 6G welding gang).
                </p>
                <div>
                  <button
                    onClick={onLoadBenchmark}
                    className="px-4 py-2 bg-primary text-on-primary font-bold rounded-sm hover:bg-primary-container transition-all"
                  >
                    Load Official OIL Benchmark Data
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
