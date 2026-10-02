'use client';

import React, { createContext, useContext, useState, useEffect, ReactNode, useCallback } from 'react';
import { 
  Project, 
  ScheduleActivity, 
  WorkerProfile, 
  MaterialTransaction, 
  ConflictItem, 
  AuditRecord, 
  UserProfile 
} from '../types';

interface RegisterParams {
  name: string;
  role: string;
  department: string;
  projectId: string;
  phone?: string;
  email?: string;
  badgeNumber?: string;
  trade?: string;
}

interface WorkspaceContextType {
  // State
  user: UserProfile;
  projects: Project[];
  currentProject: Project | null;
  activities: ScheduleActivity[];
  workers: WorkerProfile[];
  materials: MaterialTransaction[];
  conflicts: ConflictItem[];
  auditLogs: AuditRecord[];
  loading: boolean;
  toastMessage: string | null;

  // Authentication & Layout
  isAuthenticated: boolean;
  sidebarCollapsed: boolean;
  toggleSidebar: () => void;
  setSidebarCollapsed: (v: boolean) => void;
  loginAsPersona: (user: UserProfile, project?: Project) => void;
  logout: () => void;

  // Role detection helpers
  isLabour: boolean;
  isSupervisor: boolean;
  isPlanning: boolean;
  isQAQC: boolean;
  isHSE: boolean;
  isMaterials: boolean;
  isDirector: boolean;

  // Actions
  refreshData: (projectId?: string) => Promise<void>;
  switchProject: (projectId: string) => Promise<void>;
  switchUserRole: (user: UserProfile, project?: Project) => void;
  registerAndConnect: (params: RegisterParams) => Promise<boolean>;
  wipeAllData: () => Promise<void>;
  loadBenchmark: () => Promise<void>;
  createProject: (data: Partial<Project>) => Promise<Project | null>;
  importSchedule: (projectId: string, rawContent: string, format: string) => Promise<any>;
  enrollWorker: (workerData: Partial<WorkerProfile>) => Promise<WorkerProfile | null>;
  clockInWorker: (workerId: string) => Promise<boolean>;
  createMaterialTx: (txData: Partial<MaterialTransaction>) => Promise<boolean>;
  submitDpr: (actCode: string, qty: number, unit?: string, delay?: string, notes?: string) => Promise<boolean>;
  resolveConflict: (conflictId: string, notes?: string) => Promise<boolean>;
  submitVoiceUpdate: (actCode: string, progress: number, delayReason?: string) => Promise<boolean>;
  showToast: (msg: string) => void;
}

const DEFAULT_USER: UserProfile = {
  id: 'USR-DEFAULT',
  name: 'Marcus Vance, P.E.',
  email: 'm.vance@oil.in',
  role: 'Project Director',
  discipline: 'Project Controls',
  organization: 'Universal Construction & Consortium',
  avatarUrl: '',
  fidicDesignation: "Engineer's Representative (FIDIC 3.1)",
  currentProjectRole: 'Project Director',
};

const WorkspaceContext = createContext<WorkspaceContextType | undefined>(undefined);

export const WorkspaceProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUserState] = useState<UserProfile>(DEFAULT_USER);
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const [sidebarCollapsed, setSidebarCollapsedState] = useState<boolean>(false);
  const [projects, setProjects] = useState<Project[]>([]);
  const [currentProject, setCurrentProject] = useState<Project | null>(null);
  const [activities, setActivities] = useState<ScheduleActivity[]>([]);
  const [workers, setWorkers] = useState<WorkerProfile[]>([]);
  const [materials, setMaterials] = useState<MaterialTransaction[]>([]);
  const [conflicts, setConflicts] = useState<ConflictItem[]>([]);
  const [auditLogs, setAuditLogs] = useState<AuditRecord[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const showToast = useCallback((msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 4000);
  }, []);

  // Load state from local storage on client mount
  useEffect(() => {
    try {
      const savedAuth = localStorage.getItem('nirmaan_authenticated');
      const savedUser = localStorage.getItem('nirmaan_user');
      const savedSidebar = localStorage.getItem('nirmaan_sidebar_collapsed');

      if (savedAuth === 'true') {
        setIsAuthenticated(true);
      }
      if (savedUser) {
        setUserState(JSON.parse(savedUser));
      }
      if (savedSidebar === 'true') {
        setSidebarCollapsedState(true);
      }
    } catch (e) {
      console.warn('Could not read session from local storage:', e);
    }
  }, []);

  // Sync user state changes to local storage
  const setUser = (u: UserProfile) => {
    setUserState(u);
    try {
      localStorage.setItem('nirmaan_user', JSON.stringify(u));
    } catch (e) {
      console.warn('Could not write user to local storage:', e);
    }
  };

  const loginAsPersona = (newUser: UserProfile, newProject?: Project) => {
    setUser(newUser);
    setIsAuthenticated(true);
    try {
      localStorage.setItem('nirmaan_authenticated', 'true');
      localStorage.setItem('nirmaan_user', JSON.stringify(newUser));
    } catch (e) {}
    if (newProject && newProject.id !== currentProject?.id) {
      refreshData(newProject.id);
    }
    showToast(`Logged in as ${newUser.name} (${newUser.role})`);
  };

  const logout = () => {
    setIsAuthenticated(false);
    try {
      localStorage.removeItem('nirmaan_authenticated');
    } catch (e) {}
    showToast('Logged out of project workspace.');
  };

  const toggleSidebar = () => {
    setSidebarCollapsedState(prev => {
      const next = !prev;
      try {
        localStorage.setItem('nirmaan_sidebar_collapsed', String(next));
      } catch (e) {}
      return next;
    });
  };

  const setSidebarCollapsed = (v: boolean) => {
    setSidebarCollapsedState(v);
    try {
      localStorage.setItem('nirmaan_sidebar_collapsed', String(v));
    } catch (e) {}
  };

  // Primary Data Loading Engine from real SQLite database
  const refreshData = useCallback(async (targetProjectId?: string) => {
    try {
      setLoading(true);
      // 1. Fetch real projects
      const pRes = await fetch('/api/projects');
      const pData = await pRes.json();
      const loadedProjects: Project[] = pData.projects || [];
      setProjects(loadedProjects);

      let active: Project | null = null;
      if (targetProjectId) {
        active = loadedProjects.find(p => p.id === targetProjectId || p.code === targetProjectId) || null;
      }
      if (!active && loadedProjects.length > 0) {
        active = loadedProjects[0];
      }

      setCurrentProject(active);

      if (active) {
        // Fetch all related entities for this project in parallel
        const [aRes, wRes, mRes, cRes, lRes] = await Promise.all([
          fetch(`/api/activities?projectId=${active.id}`),
          fetch(`/api/workforce?projectId=${active.id}`),
          fetch(`/api/materials?projectId=${active.id}`),
          fetch(`/api/conflicts?projectId=${active.id}`),
          fetch(`/api/audit?projectId=${active.id}`),
        ]);

        const [aData, wData, mData, cData, lData] = await Promise.all([
          aRes.json(),
          wRes.json(),
          mRes.json(),
          cRes.json(),
          lRes.json(),
        ]);

        setActivities(aData.activities || []);
        setWorkers(wData.workers || []);
        setMaterials(mData.materials || []);
        setConflicts(cData.conflicts || []);
        setAuditLogs(lData.auditLogs || []);
      } else {
        setActivities([]);
        setWorkers([]);
        setMaterials([]);
        setConflicts([]);
        setAuditLogs([]);
      }
    } catch (err: any) {
      console.error('Failed to load workspace data from SQLite:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  // Initial load
  useEffect(() => {
    refreshData();
  }, [refreshData]);

  // Switch Project
  const switchProject = async (projectId: string) => {
    await refreshData(projectId);
    showToast(`Switched workspace to Project ${projectId}`);
  };

  // Switch User Role
  const switchUserRole = (newUser: UserProfile, newProject?: Project) => {
    setUser(newUser);
    setIsAuthenticated(true);
    try {
      localStorage.setItem('nirmaan_authenticated', 'true');
      localStorage.setItem('nirmaan_user', JSON.stringify(newUser));
    } catch (e) {}
    if (newProject && newProject.id !== currentProject?.id) {
      refreshData(newProject.id);
    }
    showToast(`Switched active persona to ${newUser.role} (${newUser.name})`);
  };

  // Register and Connect User to Project Workspace
  const registerAndConnect = async (params: RegisterParams): Promise<boolean> => {
    try {
      const res = await fetch('/api/auth', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(params),
      });
      const data = await res.json();
      if (!data.success) {
        showToast(`Registration failed: ${data.error}`);
        return false;
      }

      // Update user state
      const newUser: UserProfile = {
        id: data.user.id,
        name: data.user.name,
        email: data.user.email || `${data.user.id.toLowerCase()}@workspace.local`,
        role: data.user.role,
        discipline: data.user.department,
        organization: `Project Workspace ${data.user.project_id}`,
        avatarUrl: '',
        fidicDesignation: data.user.role,
        currentProjectRole: data.user.role,
      };

      setUser(newUser);
      setIsAuthenticated(true);
      try {
        localStorage.setItem('nirmaan_authenticated', 'true');
        localStorage.setItem('nirmaan_user', JSON.stringify(newUser));
      } catch (e) {}
      await refreshData(data.user.project_id);
      showToast(`Welcome ${params.name}! Connected to Project ${params.projectId} workspace as ${params.role}.`);
      return true;
    } catch (e: any) {
      console.error('Registration failed:', e);
      showToast(`Registration error: ${e.message}`);
      return false;
    }
  };

  // Wipe All Data (Pure Empty State, No Dummy Data)
  const wipeAllData = async () => {
    try {
      await fetch('/api/reset', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'WIPE_ALL' }),
      });
      await refreshData();
      showToast('All records wiped from database. Workspace is in 100% clean state.');
    } catch (e: any) {
      showToast(`Wipe error: ${e.message}`);
    }
  };

  // Load Benchmark Dataset
  const loadBenchmark = async () => {
    try {
      await fetch('/api/reset', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'LOAD_BENCHMARK' }),
      });
      await refreshData();
      showToast('Loaded official Oil India Limited SIH26122 Benchmark Data.');
    } catch (e: any) {
      showToast(`Benchmark load error: ${e.message}`);
    }
  };

  // Create Project
  const createProject = async (data: Partial<Project>): Promise<Project | null> => {
    try {
      const res = await fetch('/api/projects', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      const resData = await res.json();
      if (resData.success) {
        await refreshData(resData.project.id);
        showToast(`Created project ${resData.project.name} (${resData.project.id})`);
        return resData.project;
      } else {
        showToast(`Project creation failed: ${resData.error}`);
        return null;
      }
    } catch (e: any) {
      showToast(`Error: ${e.message}`);
      return null;
    }
  };

  // Import Schedule
  const importSchedule = async (projectId: string, rawContent: string, format: string) => {
    try {
      const res = await fetch('/api/activities', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          projectId,
          importMode: true,
          rawScheduleContent: rawContent,
          format,
        }),
      });
      const data = await res.json();
      if (data.success) {
        await refreshData(projectId);
        showToast(`Imported ${data.activitiesCount} real activities into schedule!`);
        return data;
      } else {
        showToast(`Import failed: ${data.error}`);
        return null;
      }
    } catch (e: any) {
      showToast(`Error: ${e.message}`);
      return null;
    }
  };

  // Enroll Worker
  const enrollWorker = async (workerData: Partial<WorkerProfile>): Promise<WorkerProfile | null> => {
    if (!currentProject) {
      showToast('No active project to enroll worker in.');
      return null;
    }
    try {
      const res = await fetch('/api/workforce', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          projectId: currentProject.id,
          ...workerData,
        }),
      });
      const data = await res.json();
      if (data.success) {
        await refreshData(currentProject.id);
        showToast(`Worker ${data.worker.name} (${data.worker.badgeNumber}) enrolled!`);
        return data.worker;
      } else {
        showToast(`Enrollment failed: ${data.error}`);
        return null;
      }
    } catch (e: any) {
      showToast(`Error: ${e.message}`);
      return null;
    }
  };

  // Clock In Worker
  const clockInWorker = async (workerId: string): Promise<boolean> => {
    try {
      const res = await fetch('/api/workforce', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ workerId }),
      });
      const data = await res.json();
      if (data.success) {
        if (currentProject) await refreshData(currentProject.id);
        showToast('Clock-in verified at GPS Geofence & recorded in SQLite database!');
        return true;
      } else {
        showToast(`Clock-in failed: ${data.error}`);
        return false;
      }
    } catch (e: any) {
      showToast(`Error: ${e.message}`);
      return false;
    }
  };

  // Material Transaction
  const createMaterialTx = async (txData: Partial<MaterialTransaction>): Promise<boolean> => {
    if (!currentProject) return false;
    try {
      const res = await fetch('/api/materials', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          projectId: currentProject.id,
          ...txData,
        }),
      });
      const data = await res.json();
      if (data.success) {
        await refreshData(currentProject.id);
        showToast(`Material transaction posted to real ledger!`);
        return true;
      } else {
        showToast(`Failed: ${data.error}`);
        return false;
      }
    } catch (e: any) {
      showToast(`Error: ${e.message}`);
      return false;
    }
  };

  // DPR Submission
  const submitDpr = async (actCode: string, qty: number, unit?: string, delay?: string, notes?: string): Promise<boolean> => {
    if (!currentProject) return false;
    try {
      const res = await fetch('/api/dpr', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          projectId: currentProject.id,
          activityCode: actCode,
          completedQuantity: qty,
          unit,
          delayReason: delay,
          notes,
          reportedBy: user.name,
          supervisorRole: user.currentProjectRole,
        }),
      });
      const data = await res.json();
      if (data.success) {
        await refreshData(currentProject.id);
        showToast(`DPR recorded: +${qty} ${unit || ''} on ${actCode}`);
        return true;
      } else {
        showToast(`DPR failed: ${data.error}`);
        return false;
      }
    } catch (e: any) {
      showToast(`Error: ${e.message}`);
      return false;
    }
  };

  // Resolve Conflict
  const resolveConflict = async (conflictId: string, notes?: string): Promise<boolean> => {
    try {
      const res = await fetch('/api/conflicts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          conflictId,
          resolutionNote: notes || 'Resolved via Project Controls Consensus',
        }),
      });
      const data = await res.json();
      if (data.success) {
        if (currentProject) await refreshData(currentProject.id);
        showToast(`Conflict marked as resolved in SQLite ledger`);
        return true;
      }
      return false;
    } catch (e: any) {
      showToast(`Error: ${e.message}`);
      return false;
    }
  };

  // Voice Update
  const submitVoiceUpdate = async (actCode: string, progress: number, delayReason?: string): Promise<boolean> => {
    try {
      const res = await fetch('/api/truth', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ activityCode: actCode, progress, delayReason }),
      });
      const data = await res.json();
      if (data.success) {
        if (currentProject) await refreshData(currentProject.id);
        showToast(`Linked: ${actCode} progress updated to ${progress}%`);
        return true;
      }
      return false;
    } catch (e: any) {
      showToast(`Error: ${e.message}`);
      return false;
    }
  };

  // Role detection helpers
  const roleStr = (user.role || '').toLowerCase();
  const isLabour = roleStr.includes('labour') || roleStr.includes('weld') || roleStr.includes('trade') || roleStr.includes('fitter') || roleStr.includes('operator');
  const isSupervisor = roleStr.includes('supervisor') || roleStr.includes('foreman') || roleStr.includes('section in-charge');
  const isPlanning = roleStr.includes('planning') || roleStr.includes('controls') || roleStr.includes('scheduler');
  const isQAQC = roleStr.includes('qa') || roleStr.includes('qc') || roleStr.includes('inspector') || roleStr.includes('quality');
  const isHSE = roleStr.includes('hse') || roleStr.includes('safety') || roleStr.includes('environment');
  const isMaterials = roleStr.includes('material') || roleStr.includes('store') || roleStr.includes('inventory') || roleStr.includes('supply');
  const isDirector = roleStr.includes('director') || roleStr.includes('manager') || roleStr.includes('representative') || (!isLabour && !isSupervisor && !isPlanning && !isQAQC && !isHSE && !isMaterials);

  return (
    <WorkspaceContext.Provider
      value={{
        user,
        projects,
        currentProject,
        activities,
        workers,
        materials,
        conflicts,
        auditLogs,
        loading,
        toastMessage,

        isAuthenticated,
        sidebarCollapsed,
        toggleSidebar,
        setSidebarCollapsed,
        loginAsPersona,
        logout,

        isLabour,
        isSupervisor,
        isPlanning,
        isQAQC,
        isHSE,
        isMaterials,
        isDirector,

        refreshData,
        switchProject,
        switchUserRole,
        registerAndConnect,
        wipeAllData,
        loadBenchmark,
        createProject,
        importSchedule,
        enrollWorker,
        clockInWorker,
        createMaterialTx,
        submitDpr,
        resolveConflict,
        submitVoiceUpdate,
        showToast,
      }}
    >
      {children}
    </WorkspaceContext.Provider>
  );
};

export const useWorkspace = () => {
  const context = useContext(WorkspaceContext);
  if (!context) {
    throw new Error('useWorkspace must be used within a WorkspaceProvider');
  }
  return context;
};
