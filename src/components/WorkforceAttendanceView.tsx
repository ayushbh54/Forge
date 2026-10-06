'use client';

import React, { useState } from 'react';
import { WorkerProfile } from '../types';
import { useWorkspace } from '../context/WorkspaceContext';

interface WorkforceAttendanceViewProps {
  workers: WorkerProfile[];
  onClockIn: (workerId: string) => void;
}

export const WorkforceAttendanceView: React.FC<WorkforceAttendanceViewProps> = ({
  workers,
  onClockIn,
}) => {
  const workspace = useWorkspace();

  // Tab State: Tab 1 (Labour Muster Roll) vs Tab 2 (Site Visitor Spoken Captcha Verification)
  const [activeTab, setActiveTab] = useState<'MUSTER_ROLL' | 'VISITOR_VERIFICATION'>('MUSTER_ROLL');

  // Tab 1 (Labour Attendance) State
  const [selectedTrade, setSelectedTrade] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [historySearch, setHistorySearch] = useState('');
  const [isAttendanceHistoryExpanded, setIsAttendanceHistoryExpanded] = useState(true);

  // Tab 2 (Site Visitor Verification) State
  const [activeLocationMode, setActiveLocationMode] = useState<'LIVE_GPS' | 'ON_SITE' | 'OFF_SITE' | 'MOCK_SPOOF'>('ON_SITE');
  const [challengeCaptcha, setChallengeCaptcha] = useState(742);
  const [isRecordingVideo, setIsRecordingVideo] = useState(false);
  const [videoSecondsRemaining, setVideoSecondsRemaining] = useState(5);
  const [videoRecorded, setVideoRecorded] = useState(false);
  const [transcribedSpokenWords, setTranscribedSpokenWords] = useState<string | null>(null);
  const [spokenCaptchaVerified, setSpokenCaptchaVerified] = useState(false);
  const [selectedActivity, setSelectedActivity] = useState('Pier 24 Well Foundation Sinking (-48.5m)');
  const [remarks, setRemarks] = useState('');
  const [isVisitorHistoryExpanded, setIsVisitorHistoryExpanded] = useState(true);
  const [submissionSuccess, setSubmissionSuccess] = useState(false);

  // Available unique trades for filter
  const trades = ['ALL', ...Array.from(new Set(workers.map((w) => w.trade).filter(Boolean)))];

  const filteredWorkers = workers.filter((w) => {
    const matchesTrade = selectedTrade === 'ALL' || w.trade === selectedTrade;
    const matchesSearch =
      !searchQuery ||
      w.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      w.badgeNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
      w.contractor.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesTrade && matchesSearch;
  });

  // Extract attendance punch history from workers
  const attendanceHistory = workers
    .filter((w) => w.lastClockIn && w.lastClockIn !== 'Clock-in pending today')
    .map((w) => {
      const isVerified = w.attendanceStatus === 'VERIFIED_PRESENT';
      return {
        id: `ATT-${w.id}`,
        workerId: w.id,
        name: w.name,
        badgeNumber: w.badgeNumber,
        trade: w.trade,
        contractor: w.contractor,
        time: w.lastClockIn,
        location:
          w.latitude && w.longitude
            ? `${w.latitude.toFixed(4)}° N, ${w.longitude.toFixed(4)}° E (Bridge Pier P-24 Caisson Station)`
            : '27.4825° N, 95.3225° E (Brahmaputra Bridge Geofence)',
        method: w.verificationMethod || 'RTK_GEOFENCE_BIOMETRIC',
        confidenceScore: w.confidenceScore || 96,
        status: isVerified ? 'VERIFIED_PRESENT' : 'FLAGGED_REVIEW',
      };
    })
    .filter((h) => {
      if (!historySearch) return true;
      return (
        h.name.toLowerCase().includes(historySearch.toLowerCase()) ||
        h.badgeNumber.toLowerCase().includes(historySearch.toLowerCase()) ||
        h.trade.toLowerCase().includes(historySearch.toLowerCase()) ||
        h.contractor.toLowerCase().includes(historySearch.toLowerCase())
      );
    });

  const verifiedCount = workers.filter((w) => w.attendanceStatus === 'VERIFIED_PRESENT').length;
  const reviewCount = workers.filter((w) => w.attendanceStatus === 'PRESENT_NEEDS_REVIEW').length;

  // Site Visitor Verification History
  const [visitorHistory, setVisitorHistory] = useState([
    {
      id: 'VISIT-BRG-9021',
      supervisor: 'Vikram Joshi (Resident Engineer)',
      role: 'Site Operations Supervisor',
      activity: 'Pier 24 Well Foundation Sinking (-48.5m)',
      time: 'Today, 09:45 AM',
      distance: '18.4m',
      spokenCode: '742',
      spokenVerified: true,
      hash: 'sha256-8f9a2b1c4e7d0f3a',
      status: 'VERIFIED ON-SITE',
    },
    {
      id: 'VISIT-BRG-8814',
      supervisor: 'Ananya Roy (QA/QC Lead)',
      role: 'Lead Inspector',
      activity: 'M60 HPC Pier Cap Rebar Binding Inspection',
      time: 'Yesterday, 04:15 PM',
      distance: '22.1m',
      spokenCode: '519',
      spokenVerified: true,
      hash: 'sha256-4c7b8e1a9f0d2c3e',
      status: 'VERIFIED ON-SITE',
    },
    {
      id: 'VISIT-BRG-8650',
      supervisor: 'Kavita Iyer (HSE Lead)',
      role: 'Safety Lead',
      activity: 'Barge Floating Crane Fall-Arrest Lifebuoy Audit',
      time: '04 Oct, 11:30 AM',
      distance: '14.0m',
      spokenCode: '384',
      spokenVerified: true,
      hash: 'sha256-1d9c3a7e5f8b2a0c',
      status: 'VERIFIED ON-SITE',
    },
  ]);

  const generateFreshCaptcha = () => {
    const code = Math.floor(100 + Math.random() * 900);
    setChallengeCaptcha(code);
    setVideoRecorded(false);
    setSpokenCaptchaVerified(false);
    setTranscribedSpokenWords(null);
    setSubmissionSuccess(false);
  };

  const handleStart5SecVideo = () => {
    setIsRecordingVideo(true);
    setVideoSecondsRemaining(5);
    setTranscribedSpokenWords(null);
    setSpokenCaptchaVerified(false);

    let sec = 5;
    const timer = setInterval(() => {
      sec -= 1;
      setVideoSecondsRemaining(sec);
      if (sec <= 0) {
        clearInterval(timer);
        setIsRecordingVideo(false);
        setVideoRecorded(true);
        // Simulate speech recognition verifying the challenge token
        const transcribed = `Site visit verification at Pier P-24 caisson. Spoken code challenge: ${challengeCaptcha}`;
        setTranscribedSpokenWords(transcribed);
        setSpokenCaptchaVerified(true);
      }
    }, 1000);
  };

  const handleSubmitVisit = () => {
    if (!spokenCaptchaVerified || activeLocationMode === 'OFF_SITE' || activeLocationMode === 'MOCK_SPOOF') return;

    const newVisit = {
      id: `VISIT-BRG-${Math.floor(1000 + Math.random() * 9000)}`,
      supervisor: workspace.user?.name || 'Aarav Patel (Senior Project Engineer)',
      role: workspace.user?.role || 'Senior Project Engineer',
      activity: selectedActivity,
      time: 'Just Now',
      distance: activeLocationMode === 'ON_SITE' ? '18.4m' : '24.2m',
      spokenCode: `${challengeCaptcha}`,
      spokenVerified: true,
      hash: `sha256-${Math.random().toString(36).substring(2, 18)}`,
      status: 'VERIFIED ON-SITE',
    };

    setVisitorHistory([newVisit, ...visitorHistory]);
    setSubmissionSuccess(true);
    setTimeout(() => {
      generateFreshCaptcha();
    }, 2500);
  };

  return (
    <div className="flex flex-col gap-6">
      {/* Top Banner & Tab Navigation */}
      <div className="bg-surface-container-lowest p-5 sm:p-6 rounded-2xl border border-surface-container-high shadow-sm flex flex-col gap-4">
        <div className="flex flex-wrap items-center justify-between gap-4 border-b border-surface-container-high/60 pb-4">
          <div>
            <div className="flex items-center gap-2.5">
              <div className="w-9 h-9 rounded-xl bg-primary/15 border border-primary/30 flex items-center justify-center text-primary">
                <span className="material-symbols-outlined text-[22px]">badge</span>
              </div>
              <div>
                <h2 className="text-base font-bold text-white tracking-tight flex items-center gap-2">
                  <span>Workforce Muster Roll & Multi-Factor Physical Verification</span>
                </h2>
                <p className="text-xs text-on-surface-variant mt-0.5">
                  Biometric Labour Attendance · Anti-Spoof Live Video & Spoken Captcha Site Visit Verification
                </p>
              </div>
            </div>
          </div>

          {/* Dual Tab Buttons */}
          <div className="flex items-center gap-1.5 p-1 bg-surface-container rounded-xl border border-surface-container-high">
            <button
              onClick={() => setActiveTab('MUSTER_ROLL')}
              className={`px-4 py-2 rounded-lg text-xs font-bold transition-all flex items-center gap-2 ${
                activeTab === 'MUSTER_ROLL'
                  ? 'bg-primary text-white shadow-sm'
                  : 'text-on-surface-variant hover:text-white'
              }`}
            >
              <span className="material-symbols-outlined text-[16px]">how_to_reg</span>
              <span>1. Labour Attendance & Gangs</span>
            </button>
            <button
              onClick={() => setActiveTab('VISITOR_VERIFICATION')}
              className={`px-4 py-2 rounded-lg text-xs font-bold transition-all flex items-center gap-2 ${
                activeTab === 'VISITOR_VERIFICATION'
                  ? 'bg-primary text-white shadow-sm'
                  : 'text-on-surface-variant hover:text-white'
              }`}
            >
              <span className="material-symbols-outlined text-[16px]">videocam</span>
              <span>2. Site Visitor Spoken Captcha Verification</span>
            </button>
          </div>
        </div>
      </div>

      {/* ========================================================= */}
      {/* TAB 1: DIGITAL WORKFORCE MUSTER ROLL & LABOUR ATTENDANCE  */}
      {/* ========================================================= */}
      {activeTab === 'MUSTER_ROLL' && (
        <div className="flex flex-col gap-6 animate-fade-in">
          {/* Main Workforce Grid */}
          <div className="bg-surface-container-lowest p-5 sm:p-6 rounded-2xl border border-surface-container-high shadow-sm flex flex-col gap-5">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h3 className="text-sm font-bold text-white uppercase tracking-wider">
                  Active Site Gangs & Biometric Clock-In
                </h3>
                <p className="text-xs text-on-surface-variant">
                  Geofence + Biometric multi-factor verification correlated with P6 production rates
                </p>
              </div>
              <div className="flex items-center gap-2">
                <span className="px-3 py-1 rounded-full bg-tertiary/15 text-tertiary border border-tertiary/30 text-xs font-mono font-bold flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-tertiary animate-pulse" />
                  {verifiedCount} Verified Present
                </span>
                {reviewCount > 0 && (
                  <span className="px-3 py-1 rounded-full bg-secondary/20 text-secondary border border-secondary/30 text-xs font-mono font-bold">
                    {reviewCount} Needs Review
                  </span>
                )}
              </div>
            </div>

            {/* Toolbar: Search & Trade Filters */}
            <div className="flex flex-col sm:flex-row items-center justify-between gap-3 bg-surface-container-low p-3 rounded-xl border border-surface-container-high">
              <div className="relative w-full sm:w-72">
                <span className="material-symbols-outlined absolute left-3 top-2.5 text-on-surface-variant text-[18px]">
                  search
                </span>
                <input
                  type="text"
                  placeholder="Search personnel by name, badge..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-9 pr-3 py-1.5 bg-surface-container text-white text-xs rounded-lg border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary placeholder:text-on-surface-variant/60"
                />
              </div>

              <div className="flex items-center gap-1.5 w-full sm:w-auto overflow-x-auto text-xs scrollbar-thin">
                {trades.map((t) => (
                  <button
                    key={t}
                    onClick={() => setSelectedTrade(t)}
                    className={`px-3 py-1 rounded-md font-semibold transition-colors whitespace-nowrap ${
                      selectedTrade === t
                        ? 'bg-primary-container text-white font-bold'
                        : 'bg-surface-container text-on-surface-variant hover:text-white'
                    }`}
                  >
                    {t === 'ALL' ? 'All Personnel' : t}
                  </button>
                ))}
              </div>
            </div>

            {/* Workforce Cards Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {filteredWorkers.map((worker) => {
                const isVerified = worker.attendanceStatus === 'VERIFIED_PRESENT';
                return (
                  <div
                    key={worker.id}
                    className="p-4 rounded-xl bg-surface-container-low border border-surface-container-high/80 hover:border-primary/40 transition-all flex flex-col justify-between shadow-sm relative overflow-hidden"
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-surface-container border border-surface-container-high overflow-hidden flex-shrink-0 flex items-center justify-center font-bold text-xs text-primary shadow-inner">
                          {worker.name
                            .split(' ')
                            .map((n) => n[0])
                            .join('')}
                        </div>
                        <div>
                          <h4 className="font-bold text-xs text-white leading-tight">{worker.name}</h4>
                          <span className="text-[10px] text-tertiary font-mono font-semibold">
                            {worker.badgeNumber}
                          </span>
                        </div>
                      </div>
                      <span className="px-2 py-0.5 rounded-md bg-primary/20 text-primary border border-primary/30 text-[10px] font-mono font-bold whitespace-nowrap">
                        {worker.trade}
                      </span>
                    </div>

                    <div className="my-3 flex flex-col gap-1.5 text-xs">
                      <div className="flex items-center justify-between text-on-surface-variant">
                        <span className="text-[11px]">Contractor:</span>
                        <span className="text-white font-medium truncate max-w-[140px] text-[11px]">
                          {worker.contractor}
                        </span>
                      </div>
                      <div className="flex items-center justify-between text-on-surface-variant">
                        <span className="text-[11px]">Assigned Activity:</span>
                        <span className="font-mono text-secondary font-semibold text-[11px]">
                          {worker.assignedActivityId}
                        </span>
                      </div>
                      <div className="flex items-center justify-between text-on-surface-variant">
                        <span className="text-[11px]">Safety Induction:</span>
                        <span className="text-tertiary font-mono text-[11px]">
                          Valid till {worker.safetyCertValidTill}
                        </span>
                      </div>
                    </div>

                    <div className="pt-3 border-t border-surface-container-high/60 flex flex-col gap-2">
                      <div className="flex items-center justify-between text-xs">
                        <span className="text-[11px] text-on-surface-variant">Geofence Confidence:</span>
                        <span
                          className={`font-mono font-bold text-[11px] ${
                            isVerified ? 'text-tertiary' : 'text-secondary'
                          }`}
                        >
                          {worker.confidenceScore}% ({isVerified ? 'Strong' : 'Review'})
                        </span>
                      </div>
                      <div className="flex items-center justify-between gap-2">
                        <span className="text-[10px] text-on-surface-variant font-mono truncate max-w-[150px]">
                          {worker.lastClockIn}
                        </span>
                        <button
                          onClick={() => onClockIn(worker.id)}
                          className="px-3 py-1.5 bg-primary-container hover:bg-blue-600 text-white font-bold text-xs rounded-lg transition-all shadow-sm active:scale-95 flex items-center gap-1"
                        >
                          <span className="material-symbols-outlined text-[14px]">how_to_reg</span>
                          <span>{isVerified ? 'Re-Verify' : 'Clock-In'}</span>
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* INLINE EXPANDABLE LABOUR ATTENDANCE HISTORY SECTION RIGHT BELOW */}
          <div className="bg-surface-container-lowest p-5 sm:p-6 rounded-2xl border border-surface-container-high shadow-sm flex flex-col gap-4">
            <div className="flex flex-wrap items-center justify-between gap-3 border-b border-surface-container-high/60 pb-3">
              <div className="flex items-center gap-2.5">
                <span className="material-symbols-outlined text-primary text-[22px]">history_toggle_off</span>
                <div>
                  <h3 className="text-sm font-bold text-white uppercase tracking-wider flex items-center gap-2">
                    <span>Shift Attendance & Clock-in History</span>
                    <span className="px-2 py-0.5 rounded-full bg-primary/20 text-primary text-[10px] font-mono font-bold">
                      {attendanceHistory.length} Punches
                    </span>
                  </h3>
                  <p className="text-xs text-on-surface-variant">
                    Live biometric & GPS geofenced shift log recorded in SQLite database
                  </p>
                </div>
              </div>

              <button
                onClick={() => setIsAttendanceHistoryExpanded(!isAttendanceHistoryExpanded)}
                className="px-3 py-1.5 rounded-lg bg-surface-container hover:bg-surface-container-high text-xs font-semibold text-on-surface flex items-center gap-1.5 transition-colors border border-surface-container-high"
              >
                <span className="material-symbols-outlined text-[16px]">
                  {isAttendanceHistoryExpanded ? 'unfold_less' : 'unfold_more'}
                </span>
                <span>{isAttendanceHistoryExpanded ? 'Collapse History' : 'Expand History'}</span>
              </button>
            </div>

            {isAttendanceHistoryExpanded && (
              <div className="flex flex-col gap-4 animate-fade-in">
                <div className="flex items-center justify-between gap-3 bg-surface-container-low p-3 rounded-xl border border-surface-container-high">
                  <div className="relative w-full sm:w-80">
                    <span className="material-symbols-outlined absolute left-3 top-2.5 text-on-surface-variant text-[18px]">
                      search
                    </span>
                    <input
                      type="text"
                      placeholder="Filter attendance history by worker, badge..."
                      value={historySearch}
                      onChange={(e) => setHistorySearch(e.target.value)}
                      className="w-full pl-9 pr-3 py-1.5 bg-surface-container text-white text-xs rounded-lg border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary placeholder:text-on-surface-variant/60"
                    />
                  </div>
                  <span className="text-xs text-on-surface-variant font-mono hidden sm:inline">
                    Showing {attendanceHistory.length} verified punches
                  </span>
                </div>

                {attendanceHistory.length === 0 ? (
                  <div className="py-12 text-center flex flex-col items-center justify-center gap-2 bg-surface-container-low/50 rounded-xl border border-surface-container-high border-dashed">
                    <span className="material-symbols-outlined text-[36px] text-on-surface-variant">badge</span>
                    <p className="text-xs font-semibold text-on-surface">No attendance punch history logged yet</p>
                    <span className="text-[11px] text-on-surface-variant">
                      Tap "Clock-In" on any worker above to record GPS geofenced attendance.
                    </span>
                  </div>
                ) : (
                  <div className="flex flex-col gap-2.5">
                    {attendanceHistory.map((punch) => (
                      <div
                        key={punch.id}
                        className="p-3.5 rounded-xl bg-surface-container-low border border-surface-container-high/80 hover:border-primary/40 transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-sm"
                      >
                        <div className="flex items-center gap-3">
                          <div className="w-9 h-9 rounded-lg bg-surface-container flex items-center justify-center font-bold text-xs text-tertiary border border-surface-container-high">
                            {punch.name
                              .split(' ')
                              .map((n) => n[0])
                              .join('')}
                          </div>
                          <div className="flex flex-col">
                            <div className="flex items-center gap-2">
                              <span className="text-xs font-bold text-white">{punch.name}</span>
                              <span className="px-1.5 py-0.2 rounded bg-primary/20 text-primary text-[10px] font-mono font-bold">
                                {punch.badgeNumber}
                              </span>
                              <span className="text-[11px] text-on-surface-variant font-medium">
                                · {punch.trade}
                              </span>
                            </div>
                            <div className="flex items-center gap-2 text-[10px] text-on-surface-variant mt-0.5 font-mono">
                              <span className="text-tertiary font-semibold flex items-center gap-0.5">
                                <span className="material-symbols-outlined text-[13px]">pin_drop</span>
                                <span>{punch.location}</span>
                              </span>
                              <span>•</span>
                              <span>{punch.contractor}</span>
                            </div>
                          </div>
                        </div>

                        <div className="flex items-center gap-3 sm:justify-end border-t sm:border-t-0 pt-2 sm:pt-0 border-surface-container-high/40">
                          <div className="flex flex-col items-end text-right">
                            <span className="text-xs font-mono font-bold text-white">{punch.time}</span>
                            <span className="text-[10px] text-tertiary font-mono">
                              Confidence: {punch.confidenceScore}%
                            </span>
                          </div>
                          <span className="px-2.5 py-1 rounded-full bg-tertiary/15 text-tertiary border border-tertiary/30 text-[10px] font-mono font-bold whitespace-nowrap">
                            ✓ VERIFIED PRESENT
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* TAB 2: SITE VISITOR PHYSICAL VISIT SPOKEN CAPTCHA PROTOCOL */}
      {/* ========================================================= */}
      {activeTab === 'VISITOR_VERIFICATION' && (
        <div className="flex flex-col gap-6 animate-fade-in">
          {/* Geofence Mode Selector Chip Banner */}
          <div className="p-4 bg-surface-container-low rounded-2xl border border-surface-container-high flex flex-col gap-3">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <span className="text-xs font-bold uppercase tracking-wider text-on-surface-variant">
                Auditor Geofence & Anti-Spoof Test Environment:
              </span>
              <span className="text-[10px] text-primary font-mono font-bold">
                Center: 27.4825° N, 95.3225° E (Pier P-24 Caisson)
              </span>
            </div>

            <div className="flex flex-wrap gap-2">
              {[
                { mode: 'LIVE_GPS', label: 'Live Device GPS', icon: 'my_location' },
                { mode: 'ON_SITE', label: 'Inside Geofence (~18m)', icon: 'location_on' },
                { mode: 'OFF_SITE', label: 'Outside Perimeter (~520m)', icon: 'location_off' },
                { mode: 'MOCK_SPOOF', label: 'Mock GPS Spoof Attack', icon: 'warning' },
              ].map((item) => (
                <button
                  key={item.mode}
                  onClick={() => setActiveLocationMode(item.mode as any)}
                  className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 ${
                    activeLocationMode === item.mode
                      ? 'bg-primary text-white shadow-sm'
                      : 'bg-surface-container text-on-surface-variant hover:text-white'
                  }`}
                >
                  <span className="material-symbols-outlined text-[16px]">{item.icon}</span>
                  <span>{item.label}</span>
                </button>
              ))}
            </div>

            {/* Geofence Status Alert Banner */}
            <div
              className={`p-3 rounded-xl border flex items-center gap-3 ${
                activeLocationMode === 'ON_SITE' || activeLocationMode === 'LIVE_GPS'
                  ? 'bg-tertiary/10 border-tertiary/30 text-tertiary'
                  : 'bg-red-500/10 border-red-500/30 text-red-400'
              }`}
            >
              <span className="material-symbols-outlined text-[24px]">
                {activeLocationMode === 'ON_SITE' || activeLocationMode === 'LIVE_GPS'
                  ? 'verified'
                  : activeLocationMode === 'MOCK_SPOOF'
                  ? 'gpp_bad'
                  : 'wrong_location'}
              </span>
              <div>
                <h4 className="text-xs font-bold">
                  {activeLocationMode === 'ON_SITE' || activeLocationMode === 'LIVE_GPS'
                    ? 'Inside Geofence (18.4m from Pier 24 Center)'
                    : activeLocationMode === 'MOCK_SPOOF'
                    ? 'GEOFENCE BREACH: Mock Location Spoof Detected!'
                    : 'Outside Geofence (520.0m from Pier 24 Center)'}
                </h4>
                <p className="text-[11px] opacity-80 font-mono">
                  {activeLocationMode === 'ON_SITE' || activeLocationMode === 'LIVE_GPS'
                    ? 'Site verified within allowed 100m radius · Hardware satellite lock acquired'
                    : activeLocationMode === 'MOCK_SPOOF'
                    ? 'Fake GPS provider hook detected. Visit submission strictly prohibited.'
                    : 'Maximum allowed boundary is 100 meters. Move closer to the bridge pier to verify.'}
                </p>
              </div>
            </div>
          </div>

          {/* DYNAMIC SPOKEN CAPTCHA VIDEO VERIFICATION SUITE */}
          <div className="bg-surface-container-lowest p-5 sm:p-6 rounded-2xl border border-surface-container-high shadow-sm flex flex-col gap-5">
            <div className="flex flex-wrap items-center justify-between gap-3 border-b border-surface-container-high/60 pb-4">
              <div>
                <h3 className="text-sm font-bold text-white uppercase tracking-wider flex items-center gap-2">
                  <span>Dynamic 3-Digit Spoken Captcha & Video Recording Protocol</span>
                  <span className="px-2 py-0.5 rounded-full bg-secondary/20 text-secondary text-[10px] font-mono font-bold">
                    Defeats AI & Photoshop Face Spoofing
                  </span>
                </h3>
                <p className="text-xs text-on-surface-variant mt-0.5">
                  Visitor must record a 5-second selfie video speaking the dynamic code aloud at the site coordinates
                </p>
              </div>

              <button
                onClick={generateFreshCaptcha}
                className="px-3 py-1.5 bg-surface-container hover:bg-surface-container-high text-xs font-bold text-on-surface rounded-lg border border-surface-container-high flex items-center gap-1.5 transition-colors"
              >
                <span className="material-symbols-outlined text-[16px]">refresh</span>
                <span>Regenerate Code</span>
              </button>
            </div>

            {/* Dynamic Challenge Card */}
            <div className="p-4 bg-gradient-to-r from-primary/10 via-surface-container to-secondary/10 rounded-xl border border-primary/30 flex flex-col sm:flex-row items-center justify-between gap-4 text-center sm:text-left">
              <div>
                <span className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">
                  Current Random Voice Verification Challenge
                </span>
                <p className="text-xs text-on-surface-variant mt-0.5">
                  Hold camera, look directly into lens, and clearly say this 3-digit number:
                </p>
              </div>

              <div className="flex items-center gap-3">
                <div className="px-5 py-2.5 rounded-xl bg-surface-container-lowest border-2 border-primary shadow-lg">
                  <span className="text-2xl font-black text-primary font-mono tracking-widest">
                    #{challengeCaptcha}
                  </span>
                </div>
              </div>
            </div>

            {/* 5-Second Video Simulator Screen */}
            <div className="p-4 bg-surface-container-low rounded-xl border border-surface-container-high flex flex-col items-center justify-center gap-4 py-8">
              {isRecordingVideo ? (
                <div className="flex flex-col items-center gap-3 animate-pulse">
                  <div className="w-16 h-16 rounded-full bg-red-500/20 border-2 border-red-500 flex items-center justify-center text-red-500">
                    <span className="material-symbols-outlined text-[32px]">videocam</span>
                  </div>
                  <div className="flex items-center gap-2 text-red-400 font-mono font-bold text-sm">
                    <span className="w-2.5 h-2.5 rounded-full bg-red-500 animate-ping" />
                    <span>RECORDING LIVE SITE VIDEO... 00:0{videoSecondsRemaining}</span>
                  </div>
                  {/* Waveform Animation */}
                  <div className="flex items-center gap-1 h-8">
                    {[16, 28, 20, 32, 12, 24, 30, 18, 26, 14].map((h, i) => (
                      <div
                        key={i}
                        className="w-1.5 bg-red-400 rounded-full animate-bounce"
                        style={{ height: `${h}px`, animationDelay: `${i * 80}ms` }}
                      />
                    ))}
                  </div>
                  <span className="text-xs text-white font-mono">
                    Speak Code "#{challengeCaptcha}" aloud clearly into the microphone
                  </span>
                </div>
              ) : videoRecorded ? (
                <div className="flex flex-col items-center gap-3 text-center max-w-md">
                  <div className="w-16 h-16 rounded-full bg-tertiary/20 border-2 border-tertiary flex items-center justify-center text-tertiary">
                    <span className="material-symbols-outlined text-[32px]">check_circle</span>
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-white">5-Second Video Captured & Analyzed</h4>
                    <p className="text-xs text-on-surface-variant font-mono mt-1">
                      Audio Spectrogram: {transcribedSpokenWords}
                    </p>
                  </div>

                  <div className="p-2.5 bg-tertiary/15 border border-tertiary/30 rounded-lg text-tertiary text-xs font-mono font-bold flex items-center gap-2">
                    <span className="material-symbols-outlined text-[18px]">verified</span>
                    <span>Spoken Code #{challengeCaptcha} Confirmed & Matched (99.4% Confidence)</span>
                  </div>

                  <button
                    onClick={handleStart5SecVideo}
                    className="text-xs text-primary underline hover:text-white transition-colors"
                  >
                    Re-record video if needed
                  </button>
                </div>
              ) : (
                <div className="flex flex-col items-center gap-3 text-center max-w-sm">
                  <div className="w-16 h-16 rounded-full bg-surface-container border border-surface-container-high flex items-center justify-center text-primary">
                    <span className="material-symbols-outlined text-[32px]">videocam</span>
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-white">Record 5-Second Verification Video</h4>
                    <p className="text-xs text-on-surface-variant mt-1">
                      Camera will activate and capture your live presence speaking code #{challengeCaptcha} on site.
                    </p>
                  </div>
                  <button
                    onClick={handleStart5SecVideo}
                    className="px-6 py-2.5 bg-primary hover:bg-primary-container text-white font-bold text-xs rounded-xl shadow-sm transition-all flex items-center gap-2 mt-2"
                  >
                    <span className="material-symbols-outlined text-[18px]">play_circle</span>
                    <span>Start 5-Second Video Verification</span>
                  </button>
                </div>
              )}
            </div>

            {/* Visit Details & Remarks Form */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="flex flex-col gap-1.5">
                <label className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">
                  Inspected Activity / Structure
                </label>
                <select
                  value={selectedActivity}
                  onChange={(e) => setSelectedActivity(e.target.value)}
                  className="px-3 py-2 bg-surface-container text-white text-xs rounded-lg border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary"
                >
                  <option value="Pier 24 Well Foundation Sinking (-48.5m)">
                    Pier 24 Well Foundation Sinking (-48.5m)
                  </option>
                  <option value="M60 HPC Pier Cap Rebar Binding Inspection">
                    M60 HPC Pier Cap Rebar Binding Inspection
                  </option>
                  <option value="Barge Floating Crane Fall-Arrest Lifebuoy Audit">
                    Barge Floating Crane Fall-Arrest Lifebuoy Audit
                  </option>
                  <option value="Stay Cable Strand Tensioning P-24 North">
                    Stay Cable Strand Tensioning P-24 North
                  </option>
                </select>
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">
                  Supervisor On-Site Remarks
                </label>
                <input
                  type="text"
                  value={remarks}
                  onChange={(e) => setRemarks(e.target.value)}
                  placeholder="e.g. Scour depth verified with sonar plumb line..."
                  className="px-3 py-2 bg-surface-container text-white text-xs rounded-lg border border-surface-container-high focus:outline-none focus:ring-1 focus:ring-primary placeholder:text-on-surface-variant/60"
                />
              </div>
            </div>

            {/* Telemetry & Cryptographic Audit Proof Card */}
            <div className="p-4 bg-surface-container-low rounded-xl border border-surface-container-high flex flex-col gap-2 font-mono text-xs">
              <div className="flex items-center justify-between text-on-surface-variant pb-2 border-b border-surface-container-high/60">
                <span className="font-bold text-[10px] uppercase">Telemetry & Cryptographic Audit Proof</span>
                <span className="material-symbols-outlined text-[16px] text-primary">lock_clock</span>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-[11px]">
                <div className="flex justify-between">
                  <span className="text-on-surface-variant">Target Coordinates:</span>
                  <span className="text-white font-bold">27.4825° N, 95.3225° E</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-on-surface-variant">Distance to Pier:</span>
                  <span className="text-white font-bold">
                    {activeLocationMode === 'ON_SITE' ? '18.4 meters' : '520.0 meters'}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-on-surface-variant">Mock GPS Detection:</span>
                  <span
                    className={
                      activeLocationMode === 'MOCK_SPOOF' ? 'text-red-400 font-bold' : 'text-tertiary font-bold'
                    }
                  >
                    {activeLocationMode === 'MOCK_SPOOF' ? 'SPOOF DETECTED' : 'Clean Satellite Lock'}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-on-surface-variant">Spoken Code Token:</span>
                  <span
                    className={
                      spokenCaptchaVerified ? 'text-tertiary font-bold' : 'text-secondary font-bold'
                    }
                  >
                    {spokenCaptchaVerified ? `#${challengeCaptcha} Verified ✓` : 'Pending Recording'}
                  </span>
                </div>
              </div>
            </div>

            {/* Submit Verification Action */}
            <div className="flex flex-col sm:flex-row items-center justify-between gap-3 pt-2">
              <span className="text-xs text-on-surface-variant">
                Requires: (1) GPS Geofence &lt; 100m, (2) Clean mock check, (3) Spoken captcha video verified.
              </span>

              <button
                onClick={handleSubmitVisit}
                disabled={
                  !spokenCaptchaVerified ||
                  activeLocationMode === 'OFF_SITE' ||
                  activeLocationMode === 'MOCK_SPOOF'
                }
                className="px-6 py-2.5 bg-tertiary hover:bg-emerald-600 disabled:opacity-40 disabled:pointer-events-none text-white font-bold text-xs rounded-xl shadow-sm transition-all flex items-center gap-2"
              >
                <span className="material-symbols-outlined text-[18px]">verified_user</span>
                <span>Submit Authenticated Visit Record</span>
              </button>
            </div>

            {submissionSuccess && (
              <div className="p-3 bg-tertiary/20 border border-tertiary text-tertiary rounded-xl text-xs font-bold flex items-center gap-2 animate-fade-in">
                <span className="material-symbols-outlined text-[18px]">check_circle</span>
                <span>Visit successfully sealed into blockchain audit log! Fresh code generated.</span>
              </div>
            )}
          </div>

          {/* INLINE EXPANDABLE SITE VISITOR AUDIT HISTORY LOG RIGHT BELOW */}
          <div className="bg-surface-container-lowest p-5 sm:p-6 rounded-2xl border border-surface-container-high shadow-sm flex flex-col gap-4">
            <div className="flex flex-wrap items-center justify-between gap-3 border-b border-surface-container-high/60 pb-3">
              <div className="flex items-center gap-2.5">
                <span className="material-symbols-outlined text-primary text-[22px]">history</span>
                <div>
                  <h3 className="text-sm font-bold text-white uppercase tracking-wider flex items-center gap-2">
                    <span>Site Visit Verification History & Audit Log</span>
                    <span className="px-2 py-0.5 rounded-full bg-primary/20 text-primary text-[10px] font-mono font-bold">
                      {visitorHistory.length} Verified Visits
                    </span>
                  </h3>
                  <p className="text-xs text-on-surface-variant">
                    Each record captures GPS distance, dynamic spoken code, and cryptographic anti-spoof proof
                  </p>
                </div>
              </div>

              <button
                onClick={() => setIsVisitorHistoryExpanded(!isVisitorHistoryExpanded)}
                className="px-3 py-1.5 rounded-lg bg-surface-container hover:bg-surface-container-high text-xs font-semibold text-on-surface flex items-center gap-1.5 transition-colors border border-surface-container-high"
              >
                <span className="material-symbols-outlined text-[16px]">
                  {isVisitorHistoryExpanded ? 'unfold_less' : 'unfold_more'}
                </span>
                <span>{isVisitorHistoryExpanded ? 'Collapse History' : 'Expand History'}</span>
              </button>
            </div>

            {isVisitorHistoryExpanded && (
              <div className="flex flex-col gap-2.5 animate-fade-in">
                {visitorHistory.map((item) => (
                  <div
                    key={item.id}
                    className="p-3.5 rounded-xl bg-surface-container-low border border-surface-container-high/80 hover:border-primary/40 transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-sm"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-lg bg-surface-container flex items-center justify-center font-bold text-xs text-primary border border-surface-container-high">
                        <span className="material-symbols-outlined text-[18px]">verified_user</span>
                      </div>

                      <div className="flex flex-col">
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-bold text-white">{item.supervisor}</span>
                          <span className="px-1.5 py-0.2 rounded bg-primary/20 text-primary text-[10px] font-mono font-bold">
                            {item.id}
                          </span>
                          <span className="text-[11px] text-on-surface-variant font-medium">
                            · {item.role}
                          </span>
                        </div>

                        <div className="flex items-center gap-2 text-[10px] text-on-surface-variant mt-0.5 font-mono">
                          <span className="text-white font-medium">{item.activity}</span>
                          <span>•</span>
                          <span className="text-tertiary font-bold">
                            Spoken Code: #{item.spokenCode} Verified ✓
                          </span>
                          <span>•</span>
                          <span>Dist: {item.distance}</span>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-3 sm:justify-end border-t sm:border-t-0 pt-2 sm:pt-0 border-surface-container-high/40">
                      <div className="flex flex-col items-end text-right">
                        <span className="text-xs font-mono font-bold text-white">{item.time}</span>
                        <span className="text-[9px] text-outline font-mono">{item.hash}</span>
                      </div>

                      <span className="px-2.5 py-1 rounded-full bg-tertiary/15 text-tertiary border border-tertiary/30 text-[10px] font-mono font-bold whitespace-nowrap">
                        ✓ {item.status}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
