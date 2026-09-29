'use client';

import React, { useState } from 'react';

interface WorkerRegistrationModalProps {
  isOpen: boolean;
  onClose: () => void;
  projectId: string;
  onWorkerRegistered: (worker: any) => void;
}

export const WorkerRegistrationModal: React.FC<WorkerRegistrationModalProps> = ({
  isOpen,
  onClose,
  projectId,
  onWorkerRegistered,
}) => {
  const [name, setName] = useState('');
  const [badgeNumber, setBadgeNumber] = useState('');
  const [trade, setTrade] = useState('WELDER');
  const [skills, setSkills] = useState('6G Pipe TIG/MIG, API 1104');
  const [contractor, setContractor] = useState('');
  const [phone, setPhone] = useState('');
  const [safetyExpiry, setSafetyExpiry] = useState('2027-12-31');
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !trade) {
      setErr('Name and Trade are required');
      return;
    }
    setLoading(true);
    try {
      const res = await fetch('/api/workforce', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          projectId,
          name,
          badgeNumber: badgeNumber || `LAB-${Date.now().toString().slice(-4)}`,
          trade,
          skills: skills.split(',').map(s => s.trim()).filter(Boolean),
          contractor: contractor || 'Site Contractor',
          safetyCertValidTill: safetyExpiry,
        }),
      });
      const data = await res.json();
      if (data.success) {
        onWorkerRegistered(data.worker);
        onClose();
      } else {
        setErr(data.error);
      }
    } catch (e: any) {
      setErr(e.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-background/85 backdrop-blur-md animate-fade-in">
      <div className="w-full max-w-md bg-surface-container-lowest border border-surface-container-high rounded-xl shadow-2xl overflow-hidden flex flex-col">
        <div className="p-4 bg-surface-container flex items-center justify-between border-b border-surface-container-high">
          <div className="flex items-center gap-2">
            <span className="w-8 h-8 rounded-DEFAULT bg-primary-container text-white flex items-center justify-center font-bold">
              <span className="material-symbols-outlined text-[19px]">person_add</span>
            </span>
            <h3 className="font-bold text-sm text-on-surface">Enroll Real Worker / Labour</h3>
          </div>
          <button onClick={onClose} className="text-on-surface-variant hover:text-on-surface text-xs">Close</button>
        </div>

        <form onSubmit={handleSubmit} className="p-5 flex flex-col gap-3 text-xs">
          {err && <div className="p-2 bg-error-container/20 text-error rounded-sm">{err}</div>}
          
          <div>
            <label className="text-[10px] uppercase font-bold text-on-surface-variant block mb-1">Worker Full Name *</label>
            <input
              type="text" required value={name} onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Ramesh Kumar"
              className="w-full p-2 bg-surface-container-low border border-surface-container-high rounded-sm text-on-surface"
            />
          </div>

          <div className="grid grid-cols-2 gap-2">
            <div>
              <label className="text-[10px] uppercase font-bold text-on-surface-variant block mb-1">Badge Number</label>
              <input
                type="text" value={badgeNumber} onChange={(e) => setBadgeNumber(e.target.value)}
                placeholder="LAB-0442"
                className="w-full p-2 bg-surface-container-low border border-surface-container-high rounded-sm text-on-surface font-mono"
              />
            </div>
            <div>
              <label className="text-[10px] uppercase font-bold text-on-surface-variant block mb-1">Trade / Role</label>
              <select
                value={trade} onChange={(e) => setTrade(e.target.value)}
                className="w-full p-2 bg-surface-container-low border border-surface-container-high rounded-sm text-on-surface"
              >
                <option value="WELDER">Welder</option>
                <option value="FITTER">Fitter</option>
                <option value="RIGGER">Rigger</option>
                <option value="OPERATOR">Equipment Operator</option>
                <option value="ELECTRICIAN">Electrician</option>
                <option value="SURVEYOR">Surveyor</option>
                <option value="LABOUR">General Labour</option>
              </select>
            </div>
          </div>

          <div>
            <label className="text-[10px] uppercase font-bold text-on-surface-variant block mb-1">Contractor / Employer</label>
            <input
              type="text" value={contractor} onChange={(e) => setContractor(e.target.value)}
              placeholder="e.g. PetroFab Infrastructure Ltd"
              className="w-full p-2 bg-surface-container-low border border-surface-container-high rounded-sm text-on-surface"
            />
          </div>

          <div>
            <label className="text-[10px] uppercase font-bold text-on-surface-variant block mb-1">Skills & Certifications (Comma separated)</label>
            <input
              type="text" value={skills} onChange={(e) => setSkills(e.target.value)}
              placeholder="6G Pipe, API 1104, SMAW"
              className="w-full p-2 bg-surface-container-low border border-surface-container-high rounded-sm text-on-surface"
            />
          </div>

          <div className="flex justify-end gap-2 mt-2">
            <button type="button" onClick={onClose} className="px-3 py-1.5 text-on-surface-variant">Cancel</button>
            <button type="submit" disabled={loading} className="px-4 py-1.5 bg-primary text-on-primary font-bold rounded-sm">
              {loading ? 'Saving...' : 'Register Worker'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
