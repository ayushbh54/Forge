'use client';

import React, { useState } from 'react';
import { MaterialTransaction } from '../types';

interface MaterialsStoresViewProps {
  materials: MaterialTransaction[];
  onCreateTransaction: (tx: Omit<MaterialTransaction, 'id' | 'date'>) => void;
}

export const MaterialsStoresView: React.FC<MaterialsStoresViewProps> = ({
  materials,
  onCreateTransaction,
}) => {
  const [activeTab, setActiveTab] = useState<'ALL' | 'GRN' | 'GIN'>('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [isHistoryExpanded, setIsHistoryExpanded] = useState(true);

  // Form State
  const [docType, setDocType] = useState<'GRN' | 'GIN'>('GIN');
  const [materialCode, setMaterialCode] = useState('MAT-PIPE-12X52');
  const [quantity, setQuantity] = useState(24);
  const [unit, setUnit] = useState('meters');
  const [description, setDescription] = useState('12" Line pipe spools issued to Line 24 welding gang');
  const [destination, setDestination] = useState('Line 24 Trench Corridor');
  const [associatedAct, setAssociatedAct] = useState('PIP-L5-024');

  const filtered = materials.filter((m) => {
    const matchesTab = activeTab === 'ALL' || m.docType === activeTab;
    if (!matchesTab) return false;
    if (!searchQuery.trim()) return true;
    const q = searchQuery.toLowerCase();
    return (
      m.docNumber.toLowerCase().includes(q) ||
      m.materialCode.toLowerCase().includes(q) ||
      m.description.toLowerCase().includes(q) ||
      m.destinationLocation.toLowerCase().includes(q) ||
      (m.associatedActivityCode && m.associatedActivityCode.toLowerCase().includes(q))
    );
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onCreateTransaction({
      docType,
      docNumber: `${docType}-${Date.now().toString().slice(-4)}`,
      materialCode,
      description,
      quantity,
      unit,
      destinationLocation: destination,
      associatedActivityCode: associatedAct,
      status: docType === 'GRN' ? 'INSPECTED_ACCEPTED' : 'DISPATCHED',
    });
    setShowModal(false);
  };

  return (
    <div className="flex flex-col gap-6">
      {/* Top Banner & Quick Action */}
      <div className="bg-surface-container-low p-5 rounded-xl border border-surface-container-high flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-primary text-[24px]">inventory_2</span>
            <h2 className="text-base font-bold text-on-surface">
              Materials, Stores & Digital Supply Chain Ledger
            </h2>
          </div>
          <p className="text-xs text-on-surface-variant mt-0.5">
            Real-time tracking of Goods Receipt Notes (GRN) and Goods Issue Notes (GIN) linked to WBS & site operations
          </p>
        </div>

        <button
          onClick={() => setShowModal(true)}
          className="h-9 px-4 bg-primary hover:bg-primary/90 text-on-primary font-bold text-xs rounded-lg flex items-center gap-2 transition-all shadow-sm shrink-0"
        >
          <span className="material-symbols-outlined text-[18px]">add_box</span>
          <span>Post GRN / GIN Transaction</span>
        </button>
      </div>

      {/* Stock Health Summary Chips */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <div className="p-4 bg-surface-container-lowest rounded-xl border border-surface-container-high flex flex-col justify-between shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-[11px] uppercase font-bold text-on-surface-variant">12" X52 Line Pipe Stock</span>
            <span className="material-symbols-outlined text-tertiary text-[18px]">verified</span>
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-2xl font-bold font-mono text-tertiary">180 m</span>
            <span className="text-[11px] text-on-surface-variant font-mono">Yard Verified</span>
          </div>
          <span className="text-[11px] text-tertiary font-mono mt-1">✓ 60m currently issued to Line 24</span>
        </div>

        <div className="p-4 bg-surface-container-lowest rounded-xl border border-secondary/40 flex flex-col justify-between shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-[11px] uppercase font-bold text-secondary">Forged Elbow Spools Shortage</span>
            <span className="material-symbols-outlined text-secondary text-[18px]">warning</span>
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-2xl font-bold font-mono text-secondary">8 / 14 Available</span>
            <span className="text-[11px] text-error font-mono font-bold">Shortage: 6 Units</span>
          </div>
          <span className="text-[11px] text-secondary font-mono mt-1">⚠ Critical Path bottleneck for tie-in</span>
        </div>

        <div className="p-4 bg-surface-container-lowest rounded-xl border border-surface-container-high flex flex-col justify-between shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-[11px] uppercase font-bold text-on-surface-variant">Fe500D Rebar Steel</span>
            <span className="material-symbols-outlined text-primary text-[18px]">inventory</span>
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-2xl font-bold font-mono text-on-surface">42.5 MT</span>
            <span className="text-[11px] text-on-surface-variant font-mono">Store Yard Assam</span>
          </div>
          <span className="text-[11px] text-on-surface-variant font-mono mt-1">✓ Sufficient for Pier 24-26 Caps</span>
        </div>
      </div>

      {/* Inline Structured Materials Transaction & Ledger History (Right below Summary) */}
      <div className="border border-surface-container-high rounded-xl bg-surface-container-lowest overflow-hidden shadow-sm">
        <div className="p-4 bg-surface-container-low/70 flex flex-col md:flex-row md:items-center justify-between gap-3 border-b border-surface-container-high">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center text-primary">
              <span className="material-symbols-outlined text-[18px]">receipt_long</span>
            </div>
            <div>
              <h3 className="text-sm font-bold text-on-surface flex items-center gap-2">
                Materials Transaction & Ledger History (GRN / GIN)
                <span className="px-2 py-0.5 rounded-full bg-primary/10 text-primary text-[10px] font-mono font-bold">
                  {materials.length} Transactions
                </span>
              </h3>
              <p className="text-[11px] text-on-surface-variant">
                Immutable goods receipts and site issues mapped to heat numbers and activity codes
              </p>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            {/* Filter Pills */}
            <div className="flex bg-surface-container rounded-lg p-0.5 border border-surface-container-high text-xs">
              <button
                onClick={() => setActiveTab('ALL')}
                className={`px-3 py-1 rounded font-semibold transition-all ${
                  activeTab === 'ALL'
                    ? 'bg-primary text-on-primary shadow-sm'
                    : 'text-on-surface-variant hover:text-on-surface'
                }`}
              >
                All ({materials.length})
              </button>
              <button
                onClick={() => setActiveTab('GRN')}
                className={`px-3 py-1 rounded font-semibold transition-all ${
                  activeTab === 'GRN'
                    ? 'bg-tertiary text-on-tertiary shadow-sm'
                    : 'text-on-surface-variant hover:text-on-surface'
                }`}
              >
                GRN ({materials.filter((m) => m.docType === 'GRN').length})
              </button>
              <button
                onClick={() => setActiveTab('GIN')}
                className={`px-3 py-1 rounded font-semibold transition-all ${
                  activeTab === 'GIN'
                    ? 'bg-primary text-on-primary shadow-sm'
                    : 'text-on-surface-variant hover:text-on-surface'
                }`}
              >
                GIN ({materials.filter((m) => m.docType === 'GIN').length})
              </button>
            </div>

            {/* Search Input */}
            <div className="relative">
              <span className="material-symbols-outlined absolute left-2.5 top-2 text-[14px] text-on-surface-variant">
                search
              </span>
              <input
                type="text"
                placeholder="Search ledger / heat / code..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-8 pr-3 py-1.5 text-xs bg-surface-container-lowest text-on-surface rounded-lg border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary w-40 sm:w-56"
              />
            </div>

            {/* Collapse Toggle */}
            <button
              onClick={() => setIsHistoryExpanded(!isHistoryExpanded)}
              className="px-3 py-1.5 bg-surface-container hover:bg-surface-container-high text-on-surface rounded-lg text-xs font-semibold flex items-center gap-1 transition-colors"
            >
              <span className="material-symbols-outlined text-[16px]">
                {isHistoryExpanded ? 'expand_less' : 'expand_more'}
              </span>
              <span>{isHistoryExpanded ? 'Collapse' : 'Show All'}</span>
            </button>
          </div>
        </div>

        {isHistoryExpanded && (
          <div className="overflow-x-auto">
            {filtered.length === 0 ? (
              <div className="py-10 text-center text-on-surface-variant text-xs">
                {searchQuery ? 'No materials records found matching your search.' : 'No materials transactions recorded yet.'}
              </div>
            ) : (
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="border-b border-surface-container-high bg-surface-container-low/40 text-on-surface-variant font-mono uppercase text-[11px]">
                    <th className="py-3 px-4">Doc #</th>
                    <th className="py-3 px-3">Type</th>
                    <th className="py-3 px-3">Material & Description</th>
                    <th className="py-3 px-3">Quantity</th>
                    <th className="py-3 px-3">Location / Destination</th>
                    <th className="py-3 px-3">Associated Activity</th>
                    <th className="py-3 px-4 text-right">Verification Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-surface-container-high/40">
                  {filtered.map((tx) => (
                    <tr key={tx.id} className="hover:bg-surface-container-low transition-colors">
                      <td className="py-3.5 px-4 font-mono font-bold text-primary whitespace-nowrap">
                        {tx.docNumber}
                      </td>
                      <td className="py-3.5 px-3">
                        <span
                          className={`px-2 py-0.5 rounded font-mono text-[10px] font-bold ${
                            tx.docType === 'GRN'
                              ? 'bg-tertiary/20 text-tertiary border border-tertiary/30'
                              : 'bg-primary/20 text-primary border border-primary/30'
                          }`}
                        >
                          {tx.docType}
                        </span>
                      </td>
                      <td className="py-3.5 px-3">
                        <span className="font-semibold text-on-surface block">{tx.materialCode}</span>
                        <span className="text-[11px] text-on-surface-variant truncate block max-w-sm mt-0.5">
                          {tx.description}
                        </span>
                      </td>
                      <td className="py-3.5 px-3 font-mono font-bold text-on-surface whitespace-nowrap">
                        {tx.quantity} {tx.unit}
                      </td>
                      <td className="py-3.5 px-3 text-on-surface-variant text-[11px]">
                        {tx.destinationLocation}
                      </td>
                      <td className="py-3.5 px-3 font-mono text-secondary text-[11px] whitespace-nowrap">
                        {tx.associatedActivityCode || 'General Site'}
                      </td>
                      <td className="py-3.5 px-4 text-right whitespace-nowrap">
                        <span
                          className={`px-2.5 py-1 rounded-full font-mono text-[10px] font-bold ${
                            tx.status.includes('ACCEPTED') || tx.status.includes('DISPATCHED')
                              ? 'bg-tertiary/15 text-tertiary'
                              : 'bg-surface-container text-on-surface-variant'
                          }`}
                        >
                          {tx.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        )}
      </div>

      {/* Post Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-background/80 backdrop-blur-sm animate-fadeIn">
          <div className="w-full max-w-md bg-surface-container-lowest border border-surface-container-high rounded-xl p-5 shadow-2xl flex flex-col gap-4">
            <div className="flex items-center justify-between border-b border-surface-container-high pb-3">
              <h3 className="font-bold text-sm text-on-surface flex items-center gap-2">
                <span className="material-symbols-outlined text-primary text-[18px]">add_box</span>
                Post Materials Transaction (GRN / GIN)
              </h3>
              <button
                onClick={() => setShowModal(false)}
                className="text-on-surface-variant hover:text-on-surface text-sm"
              >
                ✕
              </button>
            </div>
            <form onSubmit={handleSubmit} className="flex flex-col gap-3 text-xs">
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => setDocType('GIN')}
                  className={`flex-1 py-2 font-bold rounded-lg border transition-all ${
                    docType === 'GIN'
                      ? 'bg-primary text-on-primary border-primary shadow-sm'
                      : 'bg-surface-container border-surface-container-high text-on-surface-variant'
                  }`}
                >
                  GIN (Issue to Site Gang)
                </button>
                <button
                  type="button"
                  onClick={() => setDocType('GRN')}
                  className={`flex-1 py-2 font-bold rounded-lg border transition-all ${
                    docType === 'GRN'
                      ? 'bg-tertiary text-on-tertiary border-tertiary shadow-sm'
                      : 'bg-surface-container border-surface-container-high text-on-surface-variant'
                  }`}
                >
                  GRN (Goods Receipt)
                </button>
              </div>

              <div>
                <label className="text-on-surface-variant block mb-1 font-medium">Material Code / Heat #</label>
                <input
                  type="text"
                  value={materialCode}
                  onChange={(e) => setMaterialCode(e.target.value)}
                  className="w-full p-2.5 bg-surface-container-low border border-surface-container-high rounded-lg text-on-surface focus:outline-none focus:ring-1 focus:ring-primary"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="text-on-surface-variant block mb-1 font-medium">Quantity</label>
                  <input
                    type="number"
                    value={quantity}
                    onChange={(e) => setQuantity(Number(e.target.value))}
                    className="w-full p-2.5 bg-surface-container-low border border-surface-container-high rounded-lg text-on-surface focus:outline-none focus:ring-1 focus:ring-primary"
                  />
                </div>
                <div>
                  <label className="text-on-surface-variant block mb-1 font-medium">Unit</label>
                  <input
                    type="text"
                    value={unit}
                    onChange={(e) => setUnit(e.target.value)}
                    className="w-full p-2.5 bg-surface-container-low border border-surface-container-high rounded-lg text-on-surface focus:outline-none focus:ring-1 focus:ring-primary"
                  />
                </div>
              </div>

              <div>
                <label className="text-on-surface-variant block mb-1 font-medium">Description</label>
                <input
                  type="text"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className="w-full p-2.5 bg-surface-container-low border border-surface-container-high rounded-lg text-on-surface focus:outline-none focus:ring-1 focus:ring-primary"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="text-on-surface-variant block mb-1 font-medium">Destination / Source</label>
                  <input
                    type="text"
                    value={destination}
                    onChange={(e) => setDestination(e.target.value)}
                    className="w-full p-2.5 bg-surface-container-low border border-surface-container-high rounded-lg text-on-surface focus:outline-none focus:ring-1 focus:ring-primary"
                  />
                </div>
                <div>
                  <label className="text-on-surface-variant block mb-1 font-medium">Associated Act Code</label>
                  <input
                    type="text"
                    value={associatedAct}
                    onChange={(e) => setAssociatedAct(e.target.value)}
                    className="w-full p-2.5 bg-surface-container-low border border-surface-container-high rounded-lg text-on-surface focus:outline-none focus:ring-1 focus:ring-primary"
                  />
                </div>
              </div>

              <div className="flex justify-end gap-2 mt-3 pt-2 border-t border-surface-container-high">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="px-4 py-2 text-on-surface-variant hover:text-on-surface rounded-lg"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-primary text-on-primary font-bold rounded-lg shadow-sm hover:brightness-110"
                >
                  Save Transaction
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
