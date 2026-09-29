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
  const [showModal, setShowModal] = useState(false);
  const [docType, setDocType] = useState<'GRN' | 'GIN'>('GIN');
  const [materialCode, setMaterialCode] = useState('MAT-PIPE-12X52');
  const [quantity, setQuantity] = useState(24);
  const [unit, setUnit] = useState('meters');
  const [description, setDescription] = useState('12" Line pipe spools issued to Line 24 welding gang');
  const [destination, setDestination] = useState('Line 24 Trench Corridor');

  const filtered = materials.filter(m => activeTab === 'ALL' || m.docType === activeTab);

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
      associatedActivityCode: 'PIP-L5-024',
      status: docType === 'GRN' ? 'INSPECTED_ACCEPTED' : 'DISPATCHED',
    });
    setShowModal(false);
  };

  return (
    <div className="bg-surface-container-lowest p-5 rounded-DEFAULT border border-surface-container-high shadow-sm flex flex-col gap-4">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-surface-container-high/60 pb-3">
        <div>
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-primary text-[20px]">inventory_2</span>
            <h2 className="text-sm font-bold uppercase tracking-wider text-on-surface">
              Materials, Stores & Logistics (GRN / GIN Matrix)
            </h2>
          </div>
          <p className="text-xs text-on-surface-variant">
            Goods Receipt Notes (GRN) & Goods Issue Notes (GIN) linked to WBS and Schedule Activities
          </p>
        </div>
        <div className="flex items-center gap-2">
          {/* Tab Selector */}
          <div className="flex items-center bg-surface-container rounded-sm p-0.5 border border-surface-container-high text-xs">
            <button
              onClick={() => setActiveTab('ALL')}
              className={`px-3 py-1 rounded-sm font-semibold transition-all ${activeTab === 'ALL' ? 'bg-primary text-on-primary' : 'text-on-surface-variant'}`}
            >
              All Ledgers
            </button>
            <button
              onClick={() => setActiveTab('GRN')}
              className={`px-3 py-1 rounded-sm font-semibold transition-all ${activeTab === 'GRN' ? 'bg-primary text-on-primary' : 'text-on-surface-variant'}`}
            >
              GRN (Receipts)
            </button>
            <button
              onClick={() => setActiveTab('GIN')}
              className={`px-3 py-1 rounded-sm font-semibold transition-all ${activeTab === 'GIN' ? 'bg-primary text-on-primary' : 'text-on-surface-variant'}`}
            >
              GIN (Issues)
            </button>
          </div>

          <button
            onClick={() => setShowModal(true)}
            className="h-8 px-3 bg-primary hover:bg-primary-container text-on-primary font-semibold text-xs rounded-sm flex items-center gap-1 transition-all shadow-sm"
          >
            <span className="material-symbols-outlined text-[16px]">add_box</span>
            <span>Post GRN / GIN</span>
          </button>
        </div>
      </div>

      {/* Stock Health Summary Chips */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <div className="p-3 bg-surface-container-low rounded-DEFAULT border border-surface-container-high flex flex-col justify-between">
          <span className="text-[11px] uppercase font-bold text-on-surface-variant">12" X52 Line Pipe Stock</span>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-xl font-bold font-mono text-tertiary">180 m</span>
            <span className="text-[11px] text-on-surface-variant font-mono">Total Verified</span>
          </div>
          <span className="text-[10px] text-tertiary font-mono mt-1">✓ 60m currently issued to Line 24</span>
        </div>

        <div className="p-3 bg-surface-container-low rounded-DEFAULT border border-secondary/30 flex flex-col justify-between">
          <span className="text-[11px] uppercase font-bold text-secondary">Forged Elbow Spools Shortage</span>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-xl font-bold font-mono text-secondary">8 / 14 Available</span>
            <span className="text-[11px] text-error font-mono font-bold">Shortage: 6 Units</span>
          </div>
          <span className="text-[10px] text-secondary font-mono mt-1">⚠ Critical Path bottleneck for tie-in</span>
        </div>

        <div className="p-3 bg-surface-container-low rounded-DEFAULT border border-surface-container-high flex flex-col justify-between">
          <span className="text-[11px] uppercase font-bold text-on-surface-variant">Fe500D Rebar Steel</span>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-xl font-bold font-mono text-on-surface">42.5 MT</span>
            <span className="text-[11px] text-on-surface-variant font-mono">Store Yard Assam</span>
          </div>
          <span className="text-[10px] text-on-surface-variant font-mono mt-1">✓ Sufficient for Pier 24-26 Caps</span>
        </div>
      </div>

      {/* Transactions Table */}
      <div className="overflow-x-auto">
        <table className="w-full text-left text-xs border-collapse">
          <thead>
            <tr className="border-b border-surface-container-high text-on-surface-variant font-mono uppercase text-[11px]">
              <th className="py-2.5 px-3">Doc #</th>
              <th className="py-2.5 px-3">Type</th>
              <th className="py-2.5 px-3">Material & Description</th>
              <th className="py-2.5 px-3">Qty & Unit</th>
              <th className="py-2.5 px-3">Destination / Source</th>
              <th className="py-2.5 px-3">Associated Act</th>
              <th className="py-2.5 px-3 text-right">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-surface-container-high/40">
            {filtered.map((tx) => (
              <tr key={tx.id} className="hover:bg-surface-container transition-colors">
                <td className="py-3 px-3 font-mono font-bold text-primary whitespace-nowrap">
                  {tx.docNumber}
                </td>
                <td className="py-3 px-3">
                  <span className={`px-2 py-0.5 rounded-sm font-mono text-[10px] font-bold ${
                    tx.docType === 'GRN' 
                      ? 'bg-tertiary/20 text-tertiary border border-tertiary/30' 
                      : 'bg-primary/20 text-primary border border-primary/30'
                  }`}>
                    {tx.docType}
                  </span>
                </td>
                <td className="py-3 px-3">
                  <span className="font-semibold text-on-surface block">{tx.materialCode}</span>
                  <span className="text-[11px] text-on-surface-variant truncate block max-w-sm">{tx.description}</span>
                </td>
                <td className="py-3 px-3 font-mono font-bold text-on-surface whitespace-nowrap">
                  {tx.quantity} {tx.unit}
                </td>
                <td className="py-3 px-3 text-on-surface-variant text-[11px]">
                  {tx.destinationLocation}
                </td>
                <td className="py-3 px-3 font-mono text-secondary text-[11px] whitespace-nowrap">
                  {tx.associatedActivityCode || 'General'}
                </td>
                <td className="py-3 px-3 text-right whitespace-nowrap">
                  <span className="px-2 py-0.5 rounded-full bg-surface-container text-on-surface-variant font-mono text-[10px]">
                    {tx.status}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Post Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-background/80 backdrop-blur-sm">
          <div className="w-full max-w-md bg-surface-container-lowest border border-surface-container-high rounded-DEFAULT p-5 shadow-2xl flex flex-col gap-4">
            <div className="flex items-center justify-between border-b border-surface-container-high pb-2">
              <h3 className="font-bold text-sm text-on-surface uppercase">Create Materials Transaction</h3>
              <button onClick={() => setShowModal(false)} className="text-on-surface-variant hover:text-on-surface text-xs">Close</button>
            </div>
            <form onSubmit={handleSubmit} className="flex flex-col gap-3 text-xs">
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => setDocType('GIN')}
                  className={`flex-1 py-1.5 font-bold rounded-sm border ${docType === 'GIN' ? 'bg-primary text-on-primary border-primary' : 'bg-surface-container border-surface-container-high'}`}
                >
                  GIN (Issue to Site)
                </button>
                <button
                  type="button"
                  onClick={() => setDocType('GRN')}
                  className={`flex-1 py-1.5 font-bold rounded-sm border ${docType === 'GRN' ? 'bg-primary text-on-primary border-primary' : 'bg-surface-container border-surface-container-high'}`}
                >
                  GRN (Goods Receipt)
                </button>
              </div>
              <div>
                <label className="text-on-surface-variant block mb-1">Material Code</label>
                <input type="text" value={materialCode} onChange={(e) => setMaterialCode(e.target.value)} className="w-full p-2 bg-surface-container-low border border-surface-container-high rounded-sm text-on-surface" />
              </div>
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="text-on-surface-variant block mb-1">Quantity</label>
                  <input type="number" value={quantity} onChange={(e) => setQuantity(Number(e.target.value))} className="w-full p-2 bg-surface-container-low border border-surface-container-high rounded-sm text-on-surface" />
                </div>
                <div>
                  <label className="text-on-surface-variant block mb-1">Unit</label>
                  <input type="text" value={unit} onChange={(e) => setUnit(e.target.value)} className="w-full p-2 bg-surface-container-low border border-surface-container-high rounded-sm text-on-surface" />
                </div>
              </div>
              <div>
                <label className="text-on-surface-variant block mb-1">Description</label>
                <input type="text" value={description} onChange={(e) => setDescription(e.target.value)} className="w-full p-2 bg-surface-container-low border border-surface-container-high rounded-sm text-on-surface" />
              </div>
              <div>
                <label className="text-on-surface-variant block mb-1">Destination Location</label>
                <input type="text" value={destination} onChange={(e) => setDestination(e.target.value)} className="w-full p-2 bg-surface-container-low border border-surface-container-high rounded-sm text-on-surface" />
              </div>
              <div className="flex justify-end gap-2 mt-2">
                <button type="button" onClick={() => setShowModal(false)} className="px-3 py-1.5 text-on-surface-variant">Cancel</button>
                <button type="submit" className="px-4 py-1.5 bg-primary text-on-primary font-bold rounded-sm">Save Transaction</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
