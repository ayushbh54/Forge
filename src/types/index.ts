// Core Industrial Project Management & SIH26122 Domain Entities

export type WorkContextType = 
  | 'INDIVIDUAL' 
  | 'ORG_EMPLOYEE' 
  | 'CONTRACTOR' 
  | 'SUBCONTRACTOR' 
  | 'CONSULTANT' 
  | 'CLIENT_REP' 
  | 'INSPECTOR';

export type ProjectLifecycleStage = 
  | 'PRE_PROJECT' 
  | 'PLANNING' 
  | 'MOBILIZATION' 
  | 'EXECUTION' 
  | 'MONITORING' 
  | 'COMMISSIONING' 
  | 'HANDOVER' 
  | 'CLOSEOUT';

export type EvidenceFreshnessState = 
  | 'CURRENT'    // < 24h
  | 'RECENT'     // 1-3 days
  | 'AGING'      // 3-7 days
  | 'STALE'      // > 7 days
  | 'CRITICAL'   // missing / overdue
  | 'UNKNOWN';

export type AttendanceConfidenceState = 
  | 'STRONGLY_VERIFIED' // 90-100%
  | 'VERIFIED'          // 75-89%
  | 'NEEDS_REVIEW'      // 40-74%
  | 'SUSPICIOUS';       // < 40%

export type ConflictSeverity = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';

export interface UserProfile {
  id: string;
  name: string;
  email: string;
  role: string;
  discipline: string;
  organization: string;
  avatarUrl: string;
  fidicDesignation?: string;
  currentProjectRole: string;
}

export interface Project {
  id: string;
  code: string;
  name: string;
  client: string;
  contractorJV: string;
  contractType: string; // e.g. "FIDIC Red Book Cl. 8.4"
  lifecycle: ProjectLifecycleStage;
  location: string;
  budget: number;
  currency: string;
  startDate: string;
  plannedFinishDate: string;
  spi: number;
  cpi: number;
  evidenceCoverage: number; // percentage
  telemetryFreshness: number; // percentage
  status: 'PLANNING' | 'ON_TRACK' | 'AT_RISK' | 'DELAYED';
}

export interface WBSNode {
  id: string;
  code: string; // e.g. "03.02.04"
  name: string;
  level: 1 | 2 | 3 | 4 | 5 | 6;
  parentId?: string;
  discipline: 'CIVIL' | 'PIPING' | 'MECHANICAL' | 'ELECTRICAL' | 'INSTRUMENTATION' | 'HSE' | 'COMMISSIONING';
}

export interface ActivityStep {
  id: string;
  name: string;
  weight: number; // percentage of activity
  completed: boolean;
  completionDate?: string;
}

export interface ScheduleActivity {
  id: string;
  activityCode: string; // e.g. "PIP-L5-024" or "ACT-3088"
  uwid: string; // Universal Work ID, e.g. "UWID-EXP-2024-03088"
  wbsId: string;
  wbsCode: string;
  name: string;
  description: string;
  discipline: 'CIVIL' | 'PIPING' | 'MECHANICAL' | 'ELECTRICAL' | 'INSTRUMENTATION' | 'HSE';
  plannedStart: string;
  plannedFinish: string;
  actualStart?: string;
  actualFinish?: string;
  durationDays: number;
  totalFloatDays: number;
  isCriticalPath: boolean;
  predecessorCodes: string[];
  successorCodes: string[];
  steps?: ActivityStep[];
  
  // Triangulation & Multi-factor Progress
  plannedProgress: number; // e.g. 75%
  contractorReportedProgress: number; // e.g. 80%
  quantitySurveyProgress: number; // e.g. 74.5%
  qcPassedProgress: number; // e.g. 70.0%
  droneLidarProgress: number; // e.g. 68.2%
  validatedConsensusProgress: number; // e.g. 72.4%
  progressConfidence: number; // e.g. 94.2%
  
  toleranceExceeded: boolean;
  deltaVsConsensus: number;
  
  // Physical Metrics
  plannedQuantity: number;
  installedQuantity: number;
  unit: string; // e.g. "meters", "MT", "cu.m"
  
  // Associated resources
  assignedSupervisor: string;
  workforceCount: number;
  equipmentIds: string[];
  materialCodes: string[];
  
  lastEvidenceUpdate: string;
  freshnessState: EvidenceFreshnessState;
}

export interface InformalSiteUpdate {
  id: string;
  source: 'VOICE_HINDI' | 'VOICE_ENGLISH' | 'WHATSAPP' | 'DPR_TEXT' | 'SITE_DIARY' | 'PHOTO_SCAN';
  rawInput: string;
  timestamp: string;
  reportedBy: string;
  supervisorRole: string;
  locationGeofence?: string;
  
  // AI NLP Extraction Results
  extractedEntities: {
    discipline?: string;
    lineOrTag?: string;
    action?: string;
    quantity?: number;
    unit?: string;
    progressPercentage?: number;
    delayReason?: string;
    materialsMentioned?: string[];
  };
  
  // Schedule-Linking Matching
  matchedActivityId?: string;
  matchedActivityCode?: string;
  matchedActivityName?: string;
  linkingConfidence: number; // e.g. 0.96 (96%)
  isOutOfSequence: boolean;
  linkingStatus: 'PENDING_CONFIRMATION' | 'CONFIRMED' | 'REJECTED' | 'MANUALLY_MAPPED';
}

export interface ConflictItem {
  id: string;
  activityCode: string;
  activityName: string;
  type: 'PROGRESS_VARIANCE' | 'SILENT_RISK' | 'OUT_OF_SEQUENCE' | 'MATERIAL_SHORTAGE' | 'TEST_PENDING';
  severity: ConflictSeverity;
  title: string;
  description: string;
  varianceValue?: string;
  claimedValue?: string;
  verifiedValue?: string;
  specOrClause: string;
  timestamp: string;
  actionRequired: string;
  status: 'OPEN' | 'INVESTIGATING' | 'RESOLVED' | 'EXCEPTION_ADDED';
}

export interface WorkerProfile {
  id: string;
  badgeNumber: string;
  name: string;
  trade: 'WELDER' | 'FITTER' | 'RIGGER' | 'ELECTRICIAN' | 'MASON' | 'SURVEYOR' | 'OPERATOR' | 'LABOUR';
  skills: string[];
  contractor: string;
  activeProject: string;
  assignedActivityId: string;
  safetyCertValidTill: string;
  medicalClearance: boolean;
  photoUrl: string;
  
  // Attendance Verification
  lastClockIn?: string;
  attendanceStatus: 'VERIFIED_PRESENT' | 'PRESENT_NEEDS_REVIEW' | 'ABSENT';
  verificationMethod: 'GEOFENCE_BIOMETRIC' | 'SUPERVISOR_ROSTER' | 'PHOTO_BADGE';
  confidenceScore: number; // e.g. 96%
  latitude?: number;
  longitude?: number;
}

export interface MaterialTransaction {
  id: string;
  docType: 'MR' | 'PO' | 'GRN' | 'GIN' | 'RETURN'; // MR: Requisition, GRN: Goods Receipt, GIN: Goods Issue
  docNumber: string;
  materialCode: string;
  description: string;
  quantity: number;
  unit: string;
  sourceSupplier?: string;
  destinationLocation: string; // e.g. "Zone B Warehouse" or "Line 24 Trench"
  associatedActivityCode?: string;
  issuedToSupervisor?: string;
  date: string;
  status: 'SUBMITTED' | 'INSPECTED_ACCEPTED' | 'REJECTED' | 'DISPATCHED';
}

export interface AuditRecord {
  id: string;
  timestamp: string;
  actorName: string;
  actorRole: string;
  action: string;
  entityType: 'ACTIVITY' | 'PROGRESS' | 'EVIDENCE' | 'DPR' | 'MATERIAL' | 'CONFLICT' | 'ATTENDANCE' | 'WEATHER';
  entityId: string;
  previousValue?: string;
  newValue?: string;
  reason: string;
  ipOrDevice: string;
  sha256Hash?: string;
  previousHash?: string;
}

export interface SuspendedActivity {
  id?: string;
  activityCode: string;
  name: string;
  location?: string;
  reason: string;
  isCriticalPath: boolean;
  crewSize?: number;
  estimatedSlippage?: string;
  mitigationAction?: string;
}

export interface WeatherTelemetry {
  siteName: string;
  coordinates: {
    latitude: number;
    longitude: number;
    formatted: string;
  };
  temperature: number;
  rainfallMM: number;
  windSpeedKmh: number;
  humidity: number;
  workSuspensionActive: boolean;
  affectedActivities: SuspendedActivity[];
  historicalSeasonDaysLost: number;
  baselineAllowedDays?: number;
  netClaimableEotDays?: number;
  contractualClause?: string;
  lastUpdated?: string;
}


export type EquipmentCategory = 'CRANE' | 'EXCAVATOR' | 'WELDING_RIG' | 'DG_SET';
export type EquipmentStatus = 'ACTIVE' | 'STANDBY' | 'MAINTENANCE' | 'BREAKDOWN' | 'ACTIVE_DEPLOYED';

export interface EquipmentTelemetryData {
  gps?: { lat: number; lng: number };
  rpm?: number;
  fuelRateLph?: number;
  hydraulicPressurePsi?: number;
  oilPressurePsi?: number;
  engineLoadPct?: number;
  outputFrequency?: number;
  lineVoltage?: number;
  powerFactor?: number;
  arcTimeTodayHours?: number;
  amperageAvg?: number;
  voltageAvg?: number;
  connectivity?: '4G_IOT_CONNECTED' | 'SATELLITE_LINK' | 'OFFLINE';
  lastHeartbeat?: string;
}

export interface EquipmentItem {
  id: string;
  projectId: string;
  name: string;
  category: EquipmentCategory;
  categoryName: string;
  tag: string;
  operator: string;
  status: EquipmentStatus;
  location: string;
  operatingHours: string;
  hoursToday: string;
  fuelLevel: number;
  engineTemp: string;
  batteryVoltage?: string;
  vibrationLevel?: string;
  maintenanceDue: string;
  associatedAct?: string;
  telemetry?: EquipmentTelemetryData;
  lastBreakdownReason?: string;
  lastBreakdownAt?: string;
  createdAt?: string;
}

export interface DPRRecord {
  id: string;
  projectId: string;
  activityCode?: string;
  equipmentId?: string;
  reportDate: string;
  completedQuantity: number;
  unit: string;
  delayReason?: string;
  notes?: string;
  reportedBy: string;
  supervisorRole?: string;
  createdAt: string;
}

// Risk Radar & Delay Forecasting
export interface DisciplineRiskSummary {
  discipline: 'Civil' | 'Piping' | 'Electrical' | 'HSE';
  riskProbability: number; // 0-100%
  riskLevel: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  projectedDelayDays: number;
  activitiesCount: number;
  criticalPathCount: number;
  variancePct: number;
  primaryThreats: string[];
  recommendedAction: string;
  mitigatedDays: number;
}

export interface RiskBottleneckItem {
  id: string;
  activityCode: string;
  activityName: string;
  title: string;
  wbs: string;
  wbsCode: string;
  discipline: string;
  probability: number;
  delayProbability: number;
  impactDays: number;
  projectedDelayDays: number;
  severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  criticality: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  isCriticalPath: boolean;
  totalFloatDays: number;
  plannedStart: string;
  plannedFinish: string;
  plannedProgress: number;
  consensusProgress: number;
  progressVariance: number;
  riskDrivers: string[];
  mitigation: string;
  recommendedRecoveryAction: string;
  mitigatedDays: number;
  mitigatedDelayDays: number;
}

export interface RecoveryActionItem {
  id: string;
  discipline: 'Civil' | 'Piping' | 'Electrical' | 'HSE' | 'Overall';
  priority: 'CRITICAL' | 'HIGH' | 'MEDIUM';
  action: string;
  targetActivity: string;
  expectedDaysSaved: number;
  contractualClause: string;
  implementationCostEstimate: string;
  actionOwner: string;
}

export interface RiskRadarReport {
  success: boolean;
  projectId: string;
  projectName: string;
  evaluatedAt: string;
  horizon: string;
  horizonWeeks: number;
  asOfDate: string;
  summary: {
    overallDelayProbability: number;
    overallRiskLevel: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
    criticalPathSlippageDays: number;
    activeBottlenecksCount: number;
    highRiskDisciplinesCount: number;
    monteCarlo: {
      runs: number;
      p50DelayDays: number;
      p80DelayDays: number;
      p95DelayDays: number;
      confidenceBand: string;
    };
  };
  disciplines: DisciplineRiskSummary[];
  topBottlenecks: RiskBottleneckItem[];
  recommendedRecoveryActions: RecoveryActionItem[];
}

// Earned Value Management (EVM) & S-Curve Analytics
export interface EvmMetrics {
  pv: number; // Planned Value (BCWS)
  ev: number; // Earned Value (BCWP)
  ac: number; // Actual Cost (ACWP)
  bac: number; // Budget At Completion
  sv: number; // Schedule Variance (EV - PV)
  cv: number; // Cost Variance (EV - AC)
  spi: number; // Schedule Performance Index (EV / PV)
  cpi: number; // Cost Performance Index (EV / AC)
  eac: number; // Estimate At Completion (BAC / CPI)
  etc: number; // Estimate To Complete (EAC - AC)
  vac: number; // Variance At Completion (BAC - EAC)
  tcpi: number; // To-Complete Performance Index ((BAC - EV) / (BAC - AC))
}

export interface EvmMonthlyRecord {
  month: string; // e.g. "Jan 26"
  isoMonth: string; // e.g. "2026-01"
  date: string; // e.g. "2026-01-31"
  cumPV: number;
  cumEV: number;
  cumAC: number;
  incPV: number;
  incEV: number;
  incAC: number;
  spi: number;
  cpi: number;
  status: 'AHEAD' | 'ON_TRACK' | 'WARNING' | 'DELAYED' | 'CRITICAL' | 'CURRENT' | 'FORECAST';
  isCurrent: boolean;
  isForecast: boolean;
}

export interface EvmSCurveData {
  months: string[];
  pv: number[];
  ev: number[];
  ac: number[];
  forecastEv?: number[];
  forecastAc?: number[];
  records: EvmMonthlyRecord[];
}

export interface DisciplineEvmBreakdown {
  discipline: string;
  name: string;
  code: string;
  pv: number;
  ev: number;
  ac: number;
  spi: number;
  cpi: number;
  critical: boolean;
  activityCount: number;
}

export interface EvmAnalyticsResponse {
  success: boolean;
  projectId: string;
  projectCode: string;
  projectName: string;
  currency: string;
  budgetAtCompletion: number;
  startDate: string;
  plannedFinishDate: string;
  statusDate: string;
  cutoffMonthIndex: number;
  metrics: EvmMetrics;
  metricsInCrores?: Partial<EvmMetrics>;
  rawMetrics?: Partial<EvmMetrics>;
  sCurve: EvmSCurveData;
  disciplineBreakdown: DisciplineEvmBreakdown[];
  activitiesCount: number;
  criticalActivitiesCount: number;
  overallHealth: 'HEALTHY' | 'WARNING' | 'CRITICAL';
}



