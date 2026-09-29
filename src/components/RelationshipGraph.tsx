'use client';

import React, { useState } from 'react';
import { ScheduleActivity } from '../types';

interface RelationshipGraphProps {
  activity: ScheduleActivity;
}

export const RelationshipGraph: React.FC<RelationshipGraphProps> = ({ activity }) => {
  const [selectedNode, setSelectedNode] = useState<string | null>('ACT');

  const nodes = [
    {
      id: 'ACT',
      title: 'Schedule Activity',
      code: activity.activityCode,
      sub: activity.name,
      icon: 'calendar_month',
      color: 'border-primary text-primary bg-primary/10',
      details: `P6 Activity Code: ${activity.activityCode} · Planned: ${activity.plannedProgress}% · Consensus: ${activity.validatedConsensusProgress}% · Float: ${activity.totalFloatDays}d`,
    },
    {
      id: 'WBS',
      title: 'WBS Level 5',
      code: activity.wbsCode,
      sub: 'WP-104 Pier 24-26 Foundations & Line 24 Trunk',
      icon: 'account_tree',
      color: 'border-blue-400 text-blue-400 bg-blue-400/10',
      details: `WBS Code: ${activity.wbsCode} · Parent: 03.02 Corridor Crossings · Discipline: ${activity.discipline}`,
    },
    {
      id: 'BOQ',
      title: 'Commercial & BOQ',
      code: 'BOQ-118',
      sub: 'Fe500D Rebar & API 5L X52 Pipe Spools',
      icon: 'request_quote',
      color: 'border-amber-400 text-amber-400 bg-amber-400/10',
      details: `Unit Rate Contract · Total Scope: ${activity.plannedQuantity} ${activity.unit} · Certified: ${activity.installedQuantity} ${activity.unit}`,
    },
    {
      id: 'DPR',
      title: 'Field Daily Log',
      code: 'DPR-2026-0929',
      sub: 'Shift Log by Supervisor R. K. Sharma',
      icon: 'history_edu',
      color: 'border-emerald-400 text-emerald-400 bg-emerald-400/10',
      details: 'Daily Construction Log verified with GPS Geofence at Chainage 14+450 · Weather: Fair · Shift: Day',
    },
    {
      id: 'EVD',
      title: 'Physical Evidence',
      code: 'EVD-LIDAR-094',
      sub: 'Point Cloud LiDAR Flight FL-094-14 (142M Points)',
      icon: 'scanner',
      color: 'border-cyan-400 text-cyan-400 bg-cyan-400/10',
      details: 'Volumetric scan confirmed 304m of placed pipe · Freshness: CURRENT (4 hours ago) · Confidence: 98.6%',
    },
    {
      id: 'QC',
      title: 'QA/QC Inspection',
      code: 'ITP-PIP-24-03',
      sub: 'NDT Radiographic Testing & ASTM Lab Break',
      icon: 'fact_check',
      color: 'border-teal-400 text-teal-400 bg-teal-400/10',
      details: 'Weld joints #W24-01 to #W24-04 cleared RT · Joints #W24-05 & #W24-06 pending darkroom development',
    },
    {
      id: 'MAT',
      title: 'Materials (GRN/GIN)',
      code: 'GRN-441 / GIN-812',
      sub: '12" API 5L Gr. X52 PSL2 Seamless Line Pipe',
      icon: 'inventory_2',
      color: 'border-orange-400 text-orange-400 bg-orange-400/10',
      details: 'Goods Receipt Note GRN-441 (120m received) · Goods Issue Note GIN-812 (60m issued to site gang)',
    },
    {
      id: 'EQP',
      title: 'Plant & Equipment',
      code: 'EQ-CRANE-04',
      sub: 'Tadano 50T Rough Terrain Mobile Crane',
      icon: 'precision_manufacturing',
      color: 'border-purple-400 text-purple-400 bg-purple-400/10',
      details: 'Operator: Biren Chetia · Operating Hours: 6.5h · Fuel: 85L · Telemetry GPS stream active',
    },
    {
      id: 'WRK',
      title: 'Verified Workforce',
      code: 'GANG-PIP-02',
      sub: '18 Workers (Lead Welder: Tapan Das, 6G API 1104)',
      icon: 'badge',
      color: 'border-pink-400 text-pink-400 bg-pink-400/10',
      details: 'Biometric & Geofenced Attendance: 18 verified present · Average Confidence: 96% · Zero safety violations',
    },
  ];

  const activeNode = nodes.find(n => n.id === selectedNode) || nodes[0];

  return (
    <div className="bg-surface-container-lowest p-5 rounded-DEFAULT border border-surface-container-high shadow-sm flex flex-col gap-4">
      {/* Top Banner */}
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-surface-container-high/60 pb-3">
        <div>
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-primary text-[20px]">hub</span>
            <h2 className="text-sm font-bold uppercase tracking-wider text-on-surface">
              Universal Work ID (UWID) & Semantic Topology
            </h2>
          </div>
          <p className="text-xs text-on-surface-variant">
            Cross-discipline linkage between Schedule, BOQ, Field Observations, Materials, QC, and People
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="font-mono text-xs bg-primary/10 text-primary border border-primary/20 px-2.5 py-1 rounded-DEFAULT font-bold">
            {activity.uwid}
          </span>
          <span className="px-2 py-0.5 rounded-full bg-tertiary/20 text-tertiary font-mono text-[11px] font-bold">
            9 Linked Entities · 14 Edges
          </span>
        </div>
      </div>

      {/* 9-Node Topology Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
        {nodes.map((node) => {
          const isSelected = selectedNode === node.id;
          return (
            <div
              key={node.id}
              onClick={() => setSelectedNode(node.id)}
              className={`p-3.5 rounded-DEFAULT border cursor-pointer transition-all ${
                isSelected 
                  ? 'border-primary bg-primary/15 shadow-md scale-[1.01]' 
                  : 'border-surface-container-high bg-surface-container-low hover:bg-surface-container hover:border-surface-container-highest'
              }`}
            >
              <div className="flex items-center justify-between mb-2">
                <span className={`w-8 h-8 rounded-DEFAULT flex items-center justify-center border ${node.color}`}>
                  <span className="material-symbols-outlined text-[18px]">{node.icon}</span>
                </span>
                <span className="font-mono text-[10px] font-bold text-on-surface-variant bg-surface-container px-2 py-0.5 rounded-sm">
                  {node.code}
                </span>
              </div>
              <h4 className="font-semibold text-xs text-on-surface leading-tight">{node.title}</h4>
              <p className="text-[11px] text-on-surface-variant truncate mt-0.5">{node.sub}</p>
            </div>
          );
        })}
      </div>

      {/* Selected Node Semantic Inspector Drawer */}
      <div className="p-4 bg-surface-container-low rounded-DEFAULT border border-primary/30 flex flex-col gap-2 mt-1">
        <div className="flex items-center justify-between">
          <span className="text-xs uppercase font-bold text-primary flex items-center gap-1.5 font-mono">
            <span className="material-symbols-outlined text-[16px]">verified</span>
            Semantic Link Inspector: {activeNode.title} ({activeNode.code})
          </span>
          <span className="text-[11px] text-on-surface-variant font-mono">Tamper-Proof Ledger Signed</span>
        </div>
        <p className="text-xs text-on-surface font-medium leading-relaxed">
          {activeNode.details}
        </p>
      </div>
    </div>
  );
};
