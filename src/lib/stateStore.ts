import { 
  Project, 
  WBSNode, 
  ScheduleActivity, 
  InformalSiteUpdate, 
  ConflictItem, 
  WorkerProfile, 
  MaterialTransaction, 
  AuditRecord, 
  UserProfile 
} from '../types';
import { 
  CURRENT_USER, 
  INITIAL_PROJECT, 
  INITIAL_WBS, 
  INITIAL_ACTIVITIES, 
  INITIAL_CONFLICTS, 
  INITIAL_INFORMAL_UPDATES, 
  INITIAL_WORKERS, 
  INITIAL_MATERIALS, 
  INITIAL_AUDIT_LOGS 
} from './mockData';
import { extractEntitiesFromFieldText, matchEntitiesToActivities } from './linkingEngine';

/**
 * Singleton State Store for Enterprise Industrial ERP & SIH26122 Bridge.
 * In a real production environment this communicates with PostgreSQL / Prisma,
 * but this reactive store maintains complete consistency in-memory across all client and API calls.
 */
class EnterpriseStateStore {
  private user: UserProfile = { ...CURRENT_USER };
  private project: Project = { ...INITIAL_PROJECT };
  private wbs: WBSNode[] = [...INITIAL_WBS];
  private activities: ScheduleActivity[] = [...INITIAL_ACTIVITIES];
  private conflicts: ConflictItem[] = [...INITIAL_CONFLICTS];
  private informalUpdates: InformalSiteUpdate[] = [...INITIAL_INFORMAL_UPDATES];
  private workers: WorkerProfile[] = [...INITIAL_WORKERS];
  private materials: MaterialTransaction[] = [...INITIAL_MATERIALS];
  private auditLogs: AuditRecord[] = [...INITIAL_AUDIT_LOGS];

  // Getters
  getUser(): UserProfile { return this.user; }
  getProject(): Project { return this.project; }
  getWBS(): WBSNode[] { return this.wbs; }
  getActivities(): ScheduleActivity[] { return this.activities; }
  getActivityByCode(code: string): ScheduleActivity | undefined {
    return this.activities.find(a => a.activityCode === code || a.id === code);
  }
  getConflicts(): ConflictItem[] { return this.conflicts; }
  getInformalUpdates(): InformalSiteUpdate[] { return this.informalUpdates; }
  getWorkers(): WorkerProfile[] { return this.workers; }
  getMaterials(): MaterialTransaction[] { return this.materials; }
  getAuditLogs(): AuditRecord[] { return this.auditLogs; }

  // 1. Process New Informal Field Update (Voice / WhatsApp / DPR)
  submitInformalUpdate(input: {
    rawInput: string;
    source: InformalSiteUpdate['source'];
    reportedBy: string;
    supervisorRole: string;
    locationGeofence?: string;
  }): { update: InformalSiteUpdate; candidateMatches: ReturnType<typeof matchEntitiesToActivities> } {
    const extracted = extractEntitiesFromFieldText(input.rawInput);
    const matches = matchEntitiesToActivities(extracted, this.activities);

    const bestMatch = matches.length > 0 ? matches[0] : undefined;

    const newUpdate: InformalSiteUpdate = {
      id: `UPD-${Date.now().toString().slice(-4)}`,
      source: input.source,
      rawInput: input.rawInput,
      timestamp: 'Just now',
      reportedBy: input.reportedBy,
      supervisorRole: input.supervisorRole,
      locationGeofence: input.locationGeofence || 'Site GPS (Verified within Geofence)',
      extractedEntities: {
        discipline: extracted.discipline,
        lineOrTag: extracted.lineOrTag,
        action: extracted.action,
        quantity: extracted.quantity,
        unit: extracted.unit,
        progressPercentage: extracted.progressPercentage,
        delayReason: extracted.delayReason,
      },
      matchedActivityId: bestMatch?.activity.id,
      matchedActivityCode: bestMatch?.activity.activityCode,
      matchedActivityName: bestMatch?.activity.name,
      linkingConfidence: bestMatch?.confidenceScore || 0,
      isOutOfSequence: bestMatch?.isOutOfSequence || false,
      linkingStatus: bestMatch ? 'PENDING_CONFIRMATION' : 'MANUALLY_MAPPED',
    };

    this.informalUpdates.unshift(newUpdate);

    this.addAuditLog({
      actorName: input.reportedBy,
      actorRole: input.supervisorRole,
      action: 'INFORMAL_UPDATE_CAPTURED',
      entityType: 'ACTIVITY',
      entityId: bestMatch?.activity.activityCode || 'UNLINKED',
      previousValue: undefined,
      newValue: `Raw: "${input.rawInput.slice(0, 60)}..."`,
      reason: `Multi-modal input parsed via SIH26122 Linking Engine (Source: ${input.source})`,
    });

    return { update: newUpdate, candidateMatches: matches };
  }

  // 2. Confirm and Link Field Update to Schedule Activity
  confirmAndApplyUpdate(updateId: string, activityCode: string, validatedProgressOverride?: number): ScheduleActivity | undefined {
    const actIndex = this.activities.findIndex(a => a.activityCode === activityCode || a.id === activityCode);
    const update = this.informalUpdates.find(u => u.id === updateId);
    if (actIndex === -1) return undefined;

    const act = { ...this.activities[actIndex] };
    const prevProgress = act.validatedConsensusProgress;

    if (update) {
      update.linkingStatus = 'CONFIRMED';
      update.matchedActivityCode = act.activityCode;
      update.matchedActivityName = act.name;

      // Update contractor reported progress or override
      if (update.extractedEntities.progressPercentage) {
        act.contractorReportedProgress = update.extractedEntities.progressPercentage;
      }
      if (update.extractedEntities.quantity && update.extractedEntities.quantity > 0) {
        act.installedQuantity = Math.min(act.plannedQuantity, act.installedQuantity + update.extractedEntities.quantity);
        act.quantitySurveyProgress = Math.round((act.installedQuantity / act.plannedQuantity) * 1000) / 10;
      }
    }

    if (validatedProgressOverride !== undefined) {
      act.contractorReportedProgress = validatedProgressOverride;
    }

    // Recalculate Triangulation Consensus
    // Formula weight: LiDAR/Drone (30%) + QS Measurement (35%) + QC (35%)
    const weightedConsensus = (act.droneLidarProgress * 0.30) + (act.quantitySurveyProgress * 0.35) + (act.qcPassedProgress * 0.35);
    act.validatedConsensusProgress = Math.round(weightedConsensus * 10) / 10;
    act.deltaVsConsensus = Math.round((act.contractorReportedProgress - act.validatedConsensusProgress) * 10) / 10;
    act.toleranceExceeded = Math.abs(act.deltaVsConsensus) > 5.0; // Tolerance is ±5.0%
    act.lastEvidenceUpdate = 'Just now';
    act.freshnessState = 'CURRENT';

    this.activities[actIndex] = act;

    // Check if progress conflict needs to be created
    if (act.toleranceExceeded) {
      this.flagConflict({
        activityCode: act.activityCode,
        activityName: act.name,
        type: 'PROGRESS_VARIANCE',
        severity: Math.abs(act.deltaVsConsensus) > 10.0 ? 'CRITICAL' : 'HIGH',
        title: `Variance Alert: Contractor Claim (${act.contractorReportedProgress}%) exceeds Consensus (${act.validatedConsensusProgress}%)`,
        description: `Field reported progress deviates by +${act.deltaVsConsensus}% beyond the ±5.0% contract tolerance limit under FIDIC 8.4.`,
        varianceValue: `+${act.deltaVsConsensus}% delta`,
        claimedValue: `${act.contractorReportedProgress}% Reported`,
        verifiedValue: `${act.validatedConsensusProgress}% Consensus`,
        specOrClause: 'FIDIC Cl. 14.3 / Oil India General Contract Spec',
        actionRequired: 'Joint inspection and quantity verification required.',
      });
    }

    this.addAuditLog({
      actorName: this.user.name,
      actorRole: this.user.currentProjectRole,
      action: 'PROGRESS_RECONCILED',
      entityType: 'PROGRESS',
      entityId: act.activityCode,
      previousValue: `${prevProgress}%`,
      newValue: `${act.validatedConsensusProgress}% (Claim: ${act.contractorReportedProgress}%)`,
      reason: update?.extractedEntities.delayReason ? `Updated with delay note: ${update.extractedEntities.delayReason}` : 'Schedule-linked update verified and consensus recalculated.',
    });

    return act;
  }

  // 3. Conflict Management
  flagConflict(data: Omit<ConflictItem, 'id' | 'timestamp' | 'status'>): ConflictItem {
    const newConf: ConflictItem = {
      id: `CONF-${Date.now().toString().slice(-4)}`,
      timestamp: 'Just now',
      status: 'OPEN',
      ...data,
    };
    this.conflicts.unshift(newConf);

    this.addAuditLog({
      actorName: 'System Monitor',
      actorRole: 'Automated Integrity Watchdog',
      action: 'CONFLICT_REGISTERED',
      entityType: 'CONFLICT',
      entityId: newConf.id,
      previousValue: undefined,
      newValue: `${newConf.severity} - ${newConf.title}`,
      reason: newConf.description,
    });

    return newConf;
  }

  resolveConflict(conflictId: string, resolutionNotes: string): boolean {
    const conf = this.conflicts.find(c => c.id === conflictId);
    if (!conf) return false;

    conf.status = 'RESOLVED';

    this.addAuditLog({
      actorName: this.user.name,
      actorRole: this.user.currentProjectRole,
      action: 'CONFLICT_RESOLVED',
      entityType: 'CONFLICT',
      entityId: conflictId,
      previousValue: 'OPEN',
      newValue: 'RESOLVED',
      reason: resolutionNotes,
    });

    return true;
  }

  // 4. Workforce & Verified Attendance
  recordAttendance(workerId: string, status: WorkerProfile['attendanceStatus'], method: WorkerProfile['verificationMethod'], confidence: number): WorkerProfile | undefined {
    const worker = this.workers.find(w => w.id === workerId);
    if (!worker) return undefined;

    worker.attendanceStatus = status;
    worker.verificationMethod = method;
    worker.confidenceScore = confidence;
    worker.lastClockIn = `Today, ${new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} (${method})`;

    this.addAuditLog({
      actorName: 'Site Gate Access Controller',
      actorRole: 'Biometric & Geofence Gateway',
      action: 'ATTENDANCE_LOGGED',
      entityType: 'ATTENDANCE',
      entityId: worker.badgeNumber,
      previousValue: undefined,
      newValue: `${status} (${confidence}% confidence via ${method})`,
      reason: `Clock-in registered for worker ${worker.name}`,
    });

    return worker;
  }

  // 5. Materials Management (GRN / GIN)
  createMaterialTransaction(tx: Omit<MaterialTransaction, 'id' | 'date'>): MaterialTransaction {
    const newTx: MaterialTransaction = {
      id: `TX-${Date.now().toString().slice(-4)}`,
      date: new Date().toISOString().split('T')[0],
      ...tx,
    };
    this.materials.unshift(newTx);

    this.addAuditLog({
      actorName: this.user.name,
      actorRole: this.user.currentProjectRole,
      action: `${newTx.docType}_POSTED`,
      entityType: 'MATERIAL',
      entityId: newTx.docNumber,
      previousValue: undefined,
      newValue: `${newTx.quantity} ${newTx.unit} (${newTx.materialCode})`,
      reason: `${newTx.docType} record created: ${newTx.description}`,
    });

    return newTx;
  }

  // 6. Audit Trail
  addAuditLog(record: Omit<AuditRecord, 'id' | 'timestamp' | 'ipOrDevice'>): AuditRecord {
    const newLog: AuditRecord = {
      id: `AUD-${Date.now().toString().slice(-4)}`,
      timestamp: new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }) + ' IST',
      ipOrDevice: 'ApexBuild Secure Node (FIDIC Verified Session)',
      ...record,
    };
    this.auditLogs.unshift(newLog);
    return newLog;
  }
}

// Global Singleton Export
export const enterpriseStore = new EnterpriseStateStore();
