import { DatabaseSync } from 'node:sqlite';
import path from 'path';
import fs from 'fs';
import crypto from 'crypto';
import { 
  Project, 
  WBSNode, 
  ScheduleActivity, 
  WorkerProfile, 
  MaterialTransaction, 
  ConflictItem, 
  InformalSiteUpdate, 
  AuditRecord,
  EquipmentItem,
  DPRRecord
} from '../types/index';
import { getDefaultFleet } from './equipmentData';

const DB_PATH = path.join(process.cwd(), 'data', 'nirmaan.db');

class RealDatabase {
  private db: DatabaseSync;
  private txDepth: number = 0;

  constructor() {
    const dataDir = path.dirname(DB_PATH);
    if (!fs.existsSync(dataDir)) {
      fs.mkdirSync(dataDir, { recursive: true });
    }
    this.db = new DatabaseSync(DB_PATH);
    try {
      this.db.exec('PRAGMA journal_mode = WAL;');
      this.db.exec('PRAGMA synchronous = NORMAL;');
      this.db.exec('PRAGMA busy_timeout = 10000;');
      this.db.exec('PRAGMA cache_size = -64000;');
      this.db.exec('PRAGMA foreign_keys = ON;');
    } catch (_) {}

    this.initTables();

    // Auto-seed if database is empty so benchmark is immediately active
    try {
      const pCount = this.db.prepare('SELECT COUNT(*) as count FROM projects').get() as { count: number };
      if (!pCount || pCount.count === 0) {
        this.loadOilBenchmark();
      }
    } catch (_) {}
  }

  transaction<T>(fn: () => T): T {
    if (this.txDepth > 0) {
      const sp = `sp_${this.txDepth++}`;
      this.db.exec(`SAVEPOINT ${sp}`);
      try {
        const result = fn();
        this.db.exec(`RELEASE ${sp}`);
        return result;
      } catch (err) {
        this.db.exec(`ROLLBACK TO ${sp}`);
        throw err;
      } finally {
        this.txDepth--;
      }
    }

    this.txDepth++;
    this.db.exec('BEGIN IMMEDIATE');
    try {
      const result = fn();
      this.db.exec('COMMIT');
      return result;
    } catch (err) {
      this.db.exec('ROLLBACK');
      throw err;
    } finally {
      this.txDepth--;
    }
  }

  private initTables() {
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS projects (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        client TEXT,
        contractor_jv TEXT,
        contract_type TEXT,
        lifecycle TEXT,
        location TEXT,
        budget REAL DEFAULT 0,
        currency TEXT DEFAULT 'INR (₹)',
        start_date TEXT,
        planned_finish_date TEXT,
        spi REAL DEFAULT 1.0,
        cpi REAL DEFAULT 1.0,
        evidence_coverage REAL DEFAULT 0.0,
        telemetry_freshness REAL DEFAULT 0.0,
        status TEXT DEFAULT 'PLANNING',
        created_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS wbs_nodes (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        level INTEGER NOT NULL,
        parent_id TEXT,
        discipline TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS schedule_activities (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        activity_code TEXT NOT NULL,
        uwid TEXT,
        wbs_code TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        discipline TEXT NOT NULL,
        planned_start TEXT,
        planned_finish TEXT,
        actual_start TEXT,
        actual_finish TEXT,
        duration_days INTEGER DEFAULT 0,
        total_float_days INTEGER DEFAULT 0,
        is_critical_path INTEGER DEFAULT 0,
        predecessor_codes TEXT DEFAULT '[]',
        successor_codes TEXT DEFAULT '[]',
        planned_progress REAL DEFAULT 0.0,
        contractor_reported_progress REAL DEFAULT 0.0,
        quantity_survey_progress REAL DEFAULT 0.0,
        qc_passed_progress REAL DEFAULT 0.0,
        drone_lidar_progress REAL DEFAULT 0.0,
        validated_consensus_progress REAL DEFAULT 0.0,
        progress_confidence REAL DEFAULT 0.0,
        tolerance_exceeded INTEGER DEFAULT 0,
        delta_vs_consensus REAL DEFAULT 0.0,
        planned_quantity REAL DEFAULT 0.0,
        installed_quantity REAL DEFAULT 0.0,
        unit TEXT DEFAULT 'units',
        assigned_supervisor TEXT,
        workforce_count INTEGER DEFAULT 0,
        last_evidence_update TEXT DEFAULT 'No evidence yet',
        freshness_state TEXT DEFAULT 'UNKNOWN',
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS activity_steps (
        id TEXT PRIMARY KEY,
        activity_id TEXT NOT NULL,
        name TEXT NOT NULL,
        weight REAL NOT NULL,
        completed INTEGER DEFAULT 0,
        completion_date TEXT,
        FOREIGN KEY (activity_id) REFERENCES schedule_activities(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS workers (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        badge_number TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        trade TEXT NOT NULL,
        skills TEXT DEFAULT '[]',
        contractor TEXT NOT NULL,
        safety_cert_valid_till TEXT,
        medical_clearance INTEGER DEFAULT 1,
        photo_url TEXT,
        last_clock_in TEXT DEFAULT 'Not clocked in today',
        attendance_status TEXT DEFAULT 'ABSENT',
        verification_method TEXT DEFAULT 'NOT_VERIFIED',
        confidence_score REAL DEFAULT 0.0,
        latitude REAL DEFAULT 27.4825,
        longitude REAL DEFAULT 95.3225,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS materials_ledger (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        doc_type TEXT NOT NULL,
        doc_number TEXT NOT NULL,
        material_code TEXT NOT NULL,
        description TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        source_supplier TEXT,
        destination_location TEXT NOT NULL,
        associated_activity_code TEXT,
        issued_to_supervisor TEXT,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS conflicts (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        activity_code TEXT NOT NULL,
        activity_name TEXT NOT NULL,
        type TEXT NOT NULL,
        severity TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        variance_value TEXT,
        claimed_value TEXT,
        verified_value TEXT,
        spec_or_clause TEXT,
        timestamp TEXT NOT NULL,
        action_required TEXT NOT NULL,
        status TEXT DEFAULT 'OPEN',
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS informal_site_updates (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        source TEXT NOT NULL,
        raw_input TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        reported_by TEXT NOT NULL,
        supervisor_role TEXT NOT NULL,
        location_geofence TEXT,
        extracted_entities TEXT DEFAULT '{}',
        matched_activity_code TEXT,
        linking_confidence REAL DEFAULT 0.0,
        is_out_of_sequence INTEGER DEFAULT 0,
        linking_status TEXT DEFAULT 'PENDING_CONFIRMATION',
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS audit_logs (
        id TEXT PRIMARY KEY,
        project_id TEXT,
        timestamp TEXT NOT NULL,
        actor_name TEXT NOT NULL,
        actor_role TEXT NOT NULL,
        action TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        previous_value TEXT,
        new_value TEXT,
        reason TEXT,
        ip_or_device TEXT NOT NULL,
        sha256_hash TEXT
      );

      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        role TEXT NOT NULL,
        department TEXT NOT NULL,
        project_id TEXT NOT NULL,
        badge_number TEXT,
        trade TEXT,
        created_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS equipment (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        category_name TEXT NOT NULL,
        tag TEXT NOT NULL,
        operator TEXT NOT NULL,
        status TEXT DEFAULT 'ACTIVE',
        location TEXT NOT NULL,
        operating_hours TEXT NOT NULL,
        hours_today TEXT DEFAULT '0.0 hrs',
        fuel_level INTEGER DEFAULT 100,
        engine_temp TEXT DEFAULT '85°C (Normal)',
        battery_voltage TEXT DEFAULT '24.2 V',
        vibration_level TEXT DEFAULT '0.8 mm/s',
        maintenance_due TEXT NOT NULL,
        associated_act TEXT,
        telemetry_json TEXT DEFAULT '{}',
        last_breakdown_reason TEXT,
        last_breakdown_at TEXT,
        created_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS dpr (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        activity_code TEXT,
        equipment_id TEXT,
        report_date TEXT NOT NULL,
        completed_quantity REAL DEFAULT 0,
        unit TEXT DEFAULT 'units',
        delay_reason TEXT,
        notes TEXT,
        reported_by TEXT NOT NULL,
        supervisor_role TEXT,
        created_at TEXT NOT NULL
      );
    `);

    // Safe column migrations for existing SQLite databases
    try { this.db.exec("ALTER TABLE workers ADD COLUMN latitude REAL DEFAULT 27.4825;"); } catch (_) {}
    try { this.db.exec("ALTER TABLE workers ADD COLUMN longitude REAL DEFAULT 95.3225;"); } catch (_) {}
    try { this.db.exec("ALTER TABLE audit_logs ADD COLUMN sha256_hash TEXT;"); } catch (_) {}
  }

  getDatabase(): DatabaseSync {
    return this.db;
  }

  // --- PROJECTS ---
  getProjects(): Project[] {
    const rows = this.db.prepare('SELECT * FROM projects ORDER BY created_at DESC').all() as any[];
    return rows.map(r => ({
      id: r.id,
      code: r.code,
      name: r.name,
      client: r.client || 'Client Not Specified',
      contractorJV: r.contractor_jv || 'Not Assigned',
      contractType: r.contract_type || 'EPC Standard',
      lifecycle: r.lifecycle as any || 'EXECUTION',
      location: r.location || 'Location Pending',
      budget: r.budget,
      currency: r.currency,
      startDate: r.start_date || '',
      plannedFinishDate: r.planned_finish_date || '',
      spi: r.spi,
      cpi: r.cpi,
      evidenceCoverage: r.evidence_coverage,
      telemetryFreshness: r.telemetry_freshness,
      status: r.status as any,
    }));
  }

  getProjectById(id: string): Project | undefined {
    const r = this.db.prepare('SELECT * FROM projects WHERE id = ?').get(id) as any;
    if (!r) return undefined;
    return {
      id: r.id,
      code: r.code,
      name: r.name,
      client: r.client || '',
      contractorJV: r.contractor_jv || '',
      contractType: r.contract_type || '',
      lifecycle: r.lifecycle as any,
      location: r.location || '',
      budget: r.budget,
      currency: r.currency,
      startDate: r.start_date || '',
      plannedFinishDate: r.planned_finish_date || '',
      spi: r.spi,
      cpi: r.cpi,
      evidenceCoverage: r.evidence_coverage,
      telemetryFreshness: r.telemetry_freshness,
      status: r.status as any,
    };
  }

  createProject(p: Omit<Project, 'evidenceCoverage' | 'telemetryFreshness' | 'spi' | 'cpi'>): Project {
    return this.transaction(() => {
      const newProj: Project = {
        ...p,
        spi: 1.0,
        cpi: 1.0,
        evidenceCoverage: 0.0,
        telemetryFreshness: 0.0,
      };

      this.db.prepare(`
        INSERT OR REPLACE INTO projects (
          id, code, name, client, contractor_jv, contract_type, lifecycle, location,
          budget, currency, start_date, planned_finish_date, spi, cpi, evidence_coverage,
          telemetry_freshness, status, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        newProj.id, newProj.code, newProj.name, newProj.client, newProj.contractorJV,
        newProj.contractType, newProj.lifecycle, newProj.location, newProj.budget,
        newProj.currency, newProj.startDate, newProj.plannedFinishDate, newProj.spi,
        newProj.cpi, newProj.evidenceCoverage, newProj.telemetryFreshness, newProj.status,
        new Date().toISOString()
      );

      this.addAuditLog({
        projectId: newProj.id,
        actorName: 'Administrator',
        actorRole: 'Project Controller',
        action: 'PROJECT_INITIALIZED',
        entityType: 'ACTIVITY',
        entityId: newProj.id,
        previousValue: undefined,
        newValue: newProj.name,
        reason: `Project created in workspace with code ${newProj.code}`,
      });

      return newProj;
    });
  }

  // --- ACTIVITIES ---
  getActivities(projectId?: string): ScheduleActivity[] {
    let query = 'SELECT * FROM schedule_activities';
    const params: any[] = [];
    if (projectId) {
      query += ' WHERE project_id = ?';
      params.push(projectId);
    }
    query += ' ORDER BY planned_start ASC';

    const rows = this.db.prepare(query).all(...params) as any[];
    return rows.map(r => {
      const steps = this.db.prepare('SELECT * FROM activity_steps WHERE activity_id = ?').all(r.id) as any[];
      return {
        id: r.id,
        activityCode: r.activity_code,
        uwid: r.uwid || `UWID-${r.activity_code}`,
        wbsId: r.wbs_code,
        wbsCode: r.wbs_code,
        name: r.name,
        description: r.description || '',
        discipline: r.discipline as any,
        plannedStart: r.planned_start || '',
        plannedFinish: r.planned_finish || '',
        actualStart: r.actual_start,
        actualFinish: r.actual_finish,
        durationDays: r.duration_days,
        totalFloatDays: r.total_float_days,
        isCriticalPath: Boolean(r.is_critical_path),
        predecessorCodes: JSON.parse(r.predecessor_codes || '[]'),
        successorCodes: JSON.parse(r.successor_codes || '[]'),
        steps: steps.map(s => ({
          id: s.id,
          name: s.name,
          weight: s.weight,
          completed: Boolean(s.completed),
          completionDate: s.completion_date,
        })),
        plannedProgress: r.planned_progress,
        contractorReportedProgress: r.contractor_reported_progress,
        quantitySurveyProgress: r.quantity_survey_progress,
        qcPassedProgress: r.qc_passed_progress,
        droneLidarProgress: r.drone_lidar_progress,
        validatedConsensusProgress: r.validated_consensus_progress,
        progressConfidence: r.progress_confidence,
        toleranceExceeded: Boolean(r.tolerance_exceeded),
        deltaVsConsensus: r.delta_vs_consensus,
        plannedQuantity: r.planned_quantity,
        installedQuantity: r.installed_quantity,
        unit: r.unit,
        assignedSupervisor: r.assigned_supervisor || 'Unassigned',
        workforceCount: r.workforce_count,
        equipmentIds: [],
        materialCodes: [],
        lastEvidenceUpdate: r.last_evidence_update,
        freshnessState: r.freshness_state as any,
      };
    });
  }

  createActivity(projectId: string, a: Partial<ScheduleActivity>): ScheduleActivity {
    return this.transaction(() => {
      const id = a.id || `ACT-${Date.now().toString().slice(-6)}`;
      const actCode = a.activityCode || `ACT-${Date.now().toString().slice(-4)}`;
      
      this.db.prepare(`
        INSERT INTO schedule_activities (
          id, project_id, activity_code, uwid, wbs_code, name, description, discipline,
          planned_start, planned_finish, duration_days, total_float_days, is_critical_path,
          planned_progress, contractor_reported_progress, planned_quantity, unit, assigned_supervisor
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        id, projectId, actCode, a.uwid || `UWID-${actCode}`, a.wbsCode || '01',
        a.name || 'Untitled Activity', a.description || '', a.discipline || 'CIVIL',
        a.plannedStart || '', a.plannedFinish || '', a.durationDays || 10,
        a.totalFloatDays || 0, a.isCriticalPath ? 1 : 0, a.plannedProgress || 0,
        a.contractorReportedProgress || 0, a.plannedQuantity || 100, a.unit || 'units',
        a.assignedSupervisor || 'Unassigned'
      );

      this.addAuditLog({
        projectId,
        actorName: 'Schedule Importer',
        actorRole: 'Planning & Project Controls',
        action: 'ACTIVITY_CREATED',
        entityType: 'ACTIVITY',
        entityId: actCode,
        previousValue: undefined,
        newValue: a.name || 'New Activity',
        reason: 'Schedule activity added to project baseline',
      });

      return this.getActivities(projectId).find(x => x.id === id)!;
    });
  }

  createActivitiesBatch(projectId: string, activities: Partial<ScheduleActivity>[]): ScheduleActivity[] {
    return this.transaction(() => {
      return activities.map(a => this.createActivity(projectId, a));
    });
  }

  // --- WORKFORCE ---
  getWorkers(projectId?: string): WorkerProfile[] {
    let query = 'SELECT * FROM workers';
    const params: any[] = [];
    if (projectId) {
      query += ' WHERE project_id = ?';
      params.push(projectId);
    }
    const rows = this.db.prepare(query).all(...params) as any[];
    return rows.map(r => ({
      id: r.id,
      badgeNumber: r.badge_number,
      name: r.name,
      trade: r.trade as any,
      skills: JSON.parse(r.skills || '[]'),
      contractor: r.contractor,
      activeProject: r.project_id,
      assignedActivityId: 'PIP-L5-024',
      safetyCertValidTill: r.safety_cert_valid_till || '2027-01-01',
      medicalClearance: Boolean(r.medical_clearance),
      photoUrl: r.photo_url || '',
      lastClockIn: r.last_clock_in,
      attendanceStatus: r.attendance_status as any,
      verificationMethod: r.verification_method as any,
      confidenceScore: r.confidence_score,
      latitude: r.latitude ?? 27.4825,
      longitude: r.longitude ?? 95.3225,
    }));
  }

  createWorker(projectId: string, w: Partial<WorkerProfile>): WorkerProfile {
    return this.transaction(() => {
      const id = w.id || `WRK-${Date.now().toString().slice(-4)}`;
      const badge = w.badgeNumber || `LAB-${Date.now().toString().slice(-4)}`;
      const lat = w.latitude ?? 27.4825;
      const lng = w.longitude ?? 95.3225;
      const clockIn = w.lastClockIn || `07:45 AM (Duliajan Geofence: ${lat.toFixed(4)}° N, ${lng.toFixed(4)}° E)`;
      
      this.db.prepare(`
        INSERT INTO workers (
          id, project_id, badge_number, name, trade, skills, contractor,
          safety_cert_valid_till, medical_clearance, attendance_status, verification_method, confidence_score,
          latitude, longitude, last_clock_in
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        id, projectId, badge, w.name || 'Unnamed Worker', w.trade || 'LABOUR',
        JSON.stringify(w.skills || ['General Construction']), w.contractor || 'Site Contractor',
        w.safetyCertValidTill || '2027-12-31', 1, w.attendanceStatus || 'VERIFIED_PRESENT',
        w.verificationMethod || 'GEOFENCE_BIOMETRIC', w.confidenceScore ?? 95.0,
        lat, lng, clockIn
      );

      this.addAuditLog({
        projectId,
        actorName: 'HR / Gate Controller',
        actorRole: 'Access Gateway',
        action: 'WORKER_REGISTERED',
        entityType: 'ATTENDANCE',
        entityId: badge,
        previousValue: undefined,
        newValue: `${w.name} (${w.trade})`,
        reason: `Digital Labour Identity created and enrolled with GPS (${lat.toFixed(4)}° N, ${lng.toFixed(4)}° E)`,
      });

      return this.getWorkers(projectId).find(x => x.id === id)!;
    });
  }

  createWorkersBatch(projectId: string, workers: Partial<WorkerProfile>[]): WorkerProfile[] {
    return this.transaction(() => {
      return workers.map(w => this.createWorker(projectId, w));
    });
  }

  recordAttendance(workerId: string, status: string = 'VERIFIED_PRESENT', method: string = 'GEOFENCE_BIOMETRIC', confidence: number = 98.0) {
    return this.transaction(() => {
      const timestamp = new Date().toLocaleTimeString('en-IN', { timeZone: 'Asia/Kolkata', hour: '2-digit', minute: '2-digit' }) + ' IST (Duliajan Gate 1 Geofence: 27.4825° N, 95.3225° E)';
      this.db.prepare(`
        UPDATE workers 
        SET attendance_status = ?, verification_method = ?, confidence_score = ?, last_clock_in = ?
        WHERE id = ? OR badge_number = ?
      `).run(status, method, confidence, timestamp, workerId, workerId);

      const worker = this.db.prepare('SELECT * FROM workers WHERE id = ? OR badge_number = ?').get(workerId, workerId) as any;
      if (worker) {
        this.addAuditLog({
          projectId: worker.project_id,
          actorName: worker.name,
          actorRole: worker.trade,
          action: 'CLOCK_IN_VERIFIED',
          entityType: 'ATTENDANCE',
          entityId: worker.badge_number,
          previousValue: 'ABSENT',
          newValue: `${status} (${confidence}%)`,
          reason: `GPS Geofence + Biometric timestamped at ${timestamp}`,
        });
      }
      return worker;
    });
  }

  recordAttendanceBatch(items: Array<{ workerId: string; status?: string; method?: string; confidence?: number }>): any[] {
    return this.transaction(() => {
      return items.map(item => this.recordAttendance(item.workerId, item.status, item.method, item.confidence));
    });
  }

  // --- MATERIALS ---
  getMaterials(projectId?: string): MaterialTransaction[] {
    let query = 'SELECT * FROM materials_ledger';
    const params: any[] = [];
    if (projectId) {
      query += ' WHERE project_id = ?';
      params.push(projectId);
    }
    query += ' ORDER BY date DESC';
    const rows = this.db.prepare(query).all(...params) as any[];
    return rows.map(r => ({
      id: r.id,
      docType: r.doc_type as any,
      docNumber: r.doc_number,
      materialCode: r.material_code,
      description: r.description,
      quantity: r.quantity,
      unit: r.unit,
      sourceSupplier: r.source_supplier,
      destinationLocation: r.destination_location,
      associatedActivityCode: r.associated_activity_code,
      issuedToSupervisor: r.issued_to_supervisor,
      date: r.date,
      status: r.status as any,
    }));
  }

  createMaterialTx(projectId: string, tx: Partial<MaterialTransaction>): MaterialTransaction {
    return this.transaction(() => {
      const id = tx.id || `TX-${Date.now().toString().slice(-4)}`;
      const docNo = tx.docNumber || `${tx.docType || 'GIN'}-${Date.now().toString().slice(-4)}`;
      const date = tx.date || new Date().toISOString().split('T')[0];

      this.db.prepare(`
        INSERT INTO materials_ledger (
          id, project_id, doc_type, doc_number, material_code, description,
          quantity, unit, source_supplier, destination_location, associated_activity_code,
          issued_to_supervisor, date, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        id, projectId, tx.docType || 'GIN', docNo, tx.materialCode || 'MAT-GEN',
        tx.description || 'Material transaction', tx.quantity || 1, tx.unit || 'units',
        tx.sourceSupplier || 'Central Store', tx.destinationLocation || 'Site',
        tx.associatedActivityCode || 'General', tx.issuedToSupervisor || 'Supervisor',
        date, tx.status || 'DISPATCHED'
      );

      this.addAuditLog({
        projectId,
        actorName: 'Materials Controller',
        actorRole: 'Warehouse & Stores',
        action: `${tx.docType || 'TX'}_POSTED`,
        entityType: 'MATERIAL',
        entityId: docNo,
        previousValue: undefined,
        newValue: `${tx.quantity} ${tx.unit} (${tx.materialCode})`,
        reason: tx.description || 'Materials issued / received',
      });

      return this.getMaterials(projectId).find(x => x.id === id)!;
    });
  }

  createMaterialTxBatch(projectId: string, txs: Partial<MaterialTransaction>[]): MaterialTransaction[] {
    return this.transaction(() => {
      return txs.map(tx => this.createMaterialTx(projectId, tx));
    });
  }

  // --- CONFLICTS ---
  getConflicts(projectId?: string): ConflictItem[] {
    let query = 'SELECT * FROM conflicts';
    const params: any[] = [];
    if (projectId) {
      query += ' WHERE project_id = ?';
      params.push(projectId);
    }
    const rows = this.db.prepare(query).all(...params) as any[];
    return rows.map(r => ({
      id: r.id,
      activityCode: r.activity_code,
      activityName: r.activity_name,
      type: r.type as any,
      severity: r.severity as any,
      title: r.title,
      description: r.description,
      varianceValue: r.variance_value,
      claimedValue: r.claimed_value,
      verifiedValue: r.verified_value,
      specOrClause: r.spec_or_clause,
      timestamp: r.timestamp,
      actionRequired: r.action_required,
      status: r.status as any,
    }));
  }

  resolveConflict(conflictId: string, resolutionNote: string) {
    return this.transaction(() => {
      this.db.prepare('UPDATE conflicts SET status = ? WHERE id = ?').run('RESOLVED', conflictId);
      this.addAuditLog({
        actorName: 'Engineer Representative',
        actorRole: 'Project Assurance',
        action: 'CONFLICT_RESOLVED',
        entityType: 'CONFLICT',
        entityId: conflictId,
        previousValue: 'OPEN',
        newValue: 'RESOLVED',
        reason: resolutionNote,
      });
    });
  }

  createConflict(data: {
    id: string;
    projectId: string;
    activityCode: string;
    activityName?: string;
    type?: string;
    severity?: string;
    title: string;
    description: string;
    varianceValue?: string;
    claimedValue?: string;
    verifiedValue?: string;
    specOrClause?: string;
    actionRequired?: string;
    status?: string;
  }) {
    return this.transaction(() => {
      const timestamp = new Date().toISOString();
      this.db.prepare(`
        INSERT OR REPLACE INTO conflicts (
          id, project_id, activity_code, activity_name, type, severity, title,
          description, variance_value, claimed_value, verified_value, spec_or_clause,
          timestamp, action_required, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        data.id,
        data.projectId,
        data.activityCode,
        data.activityName || 'Field Operations',
        data.type || 'SPEC_VARIATION',
        data.severity || 'MEDIUM',
        data.title,
        data.description,
        data.varianceValue || 'N/A',
        data.claimedValue || 'N/A',
        data.verifiedValue || 'N/A',
        data.specOrClause || 'FIDIC Cl. 4.21',
        timestamp,
        data.actionRequired || 'Inspection required',
        data.status || 'OPEN'
      );

      this.addAuditLog({
        projectId: data.projectId,
        actorName: 'Field Inspector',
        actorRole: 'Quality Assurance',
        action: 'CONFLICT_RAISED',
        entityType: 'CONFLICT',
        entityId: data.id,
        reason: data.title,
      });
    });
  }

  // --- AUDIT LOGS ---
  getAuditLogs(projectId?: string): AuditRecord[] {
    let query = 'SELECT * FROM audit_logs';
    const params: any[] = [];
    if (projectId) {
      query += ' WHERE project_id = ?';
      params.push(projectId);
    }
    query += ' ORDER BY rowid DESC LIMIT 100';

    const rows = this.db.prepare(query).all(...params) as any[];
    return rows.map(r => ({
      id: r.id,
      timestamp: r.timestamp,
      actorName: r.actor_name,
      actorRole: r.actor_role,
      action: r.action,
      entityType: r.entity_type as any,
      entityId: r.entity_id,
      previousValue: r.previous_value,
      newValue: r.new_value,
      reason: r.reason || '',
      ipOrDevice: r.ip_or_device,
      sha256Hash: r.sha256_hash,
    }));
  }

  addAuditLog(log: {
    projectId?: string;
    actorName: string;
    actorRole: string;
    action: string;
    entityType: AuditRecord['entityType'];
    entityId: string;
    previousValue?: string;
    newValue?: string;
    reason?: string;
    ipOrDevice?: string;
    sha256Hash?: string;
  }): AuditRecord {
    const id = `AUD-${Date.now().toString().slice(-6)}`;
    const timestamp = new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }) + ' IST';
    const payload = `${id}|${log.projectId || ''}|${timestamp}|${log.actorName}|${log.actorRole}|${log.action}|${log.entityType}|${log.entityId}|${log.previousValue || ''}|${log.newValue || ''}|${log.reason || ''}`;
    const hash = log.sha256Hash || crypto.createHash('sha256').update(payload).digest('hex');
    const ipOrDevice = log.ipOrDevice || `ApexBuild Node-01 (SHA-256: ${hash.substring(0, 16)}...)`;

    this.db.prepare(`
      INSERT INTO audit_logs (
        id, project_id, timestamp, actor_name, actor_role, action,
        entity_type, entity_id, previous_value, new_value, reason, ip_or_device, sha256_hash
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      id, log.projectId || null, timestamp, log.actorName, log.actorRole, log.action,
      log.entityType, log.entityId, log.previousValue || null, log.newValue || null,
      log.reason || '', ipOrDevice, hash
    );

    return {
      id,
      timestamp,
      actorName: log.actorName,
      actorRole: log.actorRole,
      action: log.action,
      entityType: log.entityType,
      entityId: log.entityId,
      previousValue: log.previousValue,
      newValue: log.newValue,
      reason: log.reason || '',
      ipOrDevice,
      sha256Hash: hash,
    };
  }

  // --- DPR (DAILY PROGRESS REPORTING) ---
  recordDpr(projectId: string, data: {
    activityCode: string;
    completedQuantity: number;
    unit?: string;
    delayReason?: string;
    notes?: string;
    reportedBy: string;
    supervisorRole: string;
  }) {
    return this.transaction(() => {
      const act = this.db.prepare('SELECT * FROM schedule_activities WHERE activity_code = ? AND project_id = ?').get(data.activityCode, projectId) as any;
      const unit = data.unit || (act ? act.unit : 'units');
      if (act) {
        const newInstalled = (act.installed_quantity || 0) + Number(data.completedQuantity);
        const plannedQty = act.planned_quantity || 100;
        const calculatedProgress = Math.min(100, Math.round((newInstalled / plannedQty) * 100));
        
        this.db.prepare(`
          UPDATE schedule_activities 
          SET installed_quantity = ?, contractor_reported_progress = ?, last_evidence_update = ?
          WHERE activity_code = ? AND project_id = ?
        `).run(
          newInstalled,
          calculatedProgress,
          `DPR Submitted by ${data.reportedBy} (+${data.completedQuantity} ${unit})`,
          data.activityCode,
          projectId
        );
      }

      const updId = `UPD-DPR-${Date.now().toString().slice(-4)}`;
      this.db.prepare(`
        INSERT INTO informal_site_updates (
          id, project_id, source, raw_input, timestamp, reported_by, supervisor_role,
          matched_activity_code, linking_confidence, linking_status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        updId, projectId, 'DPR_TEXT',
        `DPR: ${data.completedQuantity} ${unit} installed. Notes: ${data.notes || 'None'}. Delay: ${data.delayReason || 'None'}`,
        new Date().toLocaleTimeString('en-IN', { timeZone: 'Asia/Kolkata', hour: '2-digit', minute: '2-digit' }) + ' IST',
        data.reportedBy, data.supervisorRole, data.activityCode, 99.0, 'CONFIRMED'
      );

      const dprRecordId = `DPR-${Date.now().toString().slice(-6)}`;
      try {
        this.db.prepare(`
          INSERT INTO dpr (
            id, project_id, activity_code, equipment_id, report_date,
            completed_quantity, unit, delay_reason, notes, reported_by, supervisor_role, created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).run(
          dprRecordId,
          projectId,
          data.activityCode,
          null,
          new Date().toISOString().split('T')[0],
          Number(data.completedQuantity) || 0,
          unit,
          data.delayReason || null,
          data.notes || null,
          data.reportedBy,
          data.supervisorRole,
          new Date().toISOString()
        );
      } catch (_) {}

      if (data.delayReason && data.delayReason !== 'NONE' && data.delayReason.toLowerCase() !== 'no delay') {
        const confId = `CNF-${Date.now().toString().slice(-4)}`;
        this.db.prepare(`
          INSERT INTO conflicts (
            id, project_id, activity_code, activity_name, type, severity, title,
            description, variance_value, claimed_value, verified_value, spec_or_clause,
            timestamp, action_required, status
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).run(
          confId, projectId, data.activityCode, act ? act.name : data.activityCode,
          'PHYSICAL_PROGRESS', 'MEDIUM', `Site Delay: ${data.delayReason}`,
          `Reported in DPR: ${data.notes || data.delayReason}`,
          '-12%', `${data.completedQuantity} ${unit}`, 'Delayed',
          'FIDIC Cl. 8.4 (Notice of Delay)', new Date().toISOString(),
          'Expedite required from contractor', 'OPEN'
        );
      }

      this.addAuditLog({
        projectId,
        actorName: data.reportedBy,
        actorRole: data.supervisorRole,
        action: 'DPR_SUBMITTED',
        entityType: 'ACTIVITY',
        entityId: data.activityCode,
        newValue: `+${data.completedQuantity} ${unit}`,
        reason: data.notes || data.delayReason || 'Daily construction log entry',
      });

      return { success: true };
    });
  }

  recordDprBatch(projectId: string, reports: Array<{
    activityCode: string;
    completedQuantity: number;
    unit?: string;
    delayReason?: string;
    notes?: string;
    reportedBy?: string;
    supervisorRole?: string;
  }>) {
    return this.transaction(() => {
      const results: any[] = [];
      for (const r of reports) {
        results.push(this.recordDpr(projectId, {
          activityCode: r.activityCode,
          completedQuantity: r.completedQuantity,
          unit: r.unit,
          delayReason: r.delayReason,
          notes: r.notes,
          reportedBy: r.reportedBy || 'Field Supervisor',
          supervisorRole: r.supervisorRole || 'Section In-Charge',
        }));
      }
      return { success: true, count: results.length, results };
    });
  }

  // --- EQUIPMENT & FLEET TELEMETRY ---
  getEquipment(projectId: string = 'PRJ-OIL-2026'): EquipmentItem[] {
    let rows = this.db.prepare('SELECT * FROM equipment WHERE project_id = ? ORDER BY id ASC').all(projectId) as any[];
    if (rows.length === 0) {
      this.seedDefaultEquipment(projectId);
      rows = this.db.prepare('SELECT * FROM equipment WHERE project_id = ? ORDER BY id ASC').all(projectId) as any[];
    }

    return rows.map(r => ({
      id: r.id,
      projectId: r.project_id,
      name: r.name,
      category: r.category as any,
      categoryName: r.category_name,
      tag: r.tag,
      operator: r.operator,
      status: r.status as any,
      location: r.location,
      operatingHours: r.operating_hours,
      hoursToday: r.hours_today,
      fuelLevel: Number(r.fuel_level),
      engineTemp: r.engine_temp,
      batteryVoltage: r.battery_voltage || undefined,
      vibrationLevel: r.vibration_level || undefined,
      maintenanceDue: r.maintenance_due,
      associatedAct: r.associated_act || undefined,
      telemetry: JSON.parse(r.telemetry_json || '{}'),
      lastBreakdownReason: r.last_breakdown_reason || undefined,
      lastBreakdownAt: r.last_breakdown_at || undefined,
      createdAt: r.created_at,
    }));
  }

  seedDefaultEquipment(projectId: string = 'PRJ-OIL-2026') {
    return this.transaction(() => {
      const fleet = getDefaultFleet(projectId);
      const stmt = this.db.prepare(`
        INSERT OR REPLACE INTO equipment (
          id, project_id, name, category, category_name, tag, operator, status,
          location, operating_hours, hours_today, fuel_level, engine_temp,
          battery_voltage, vibration_level, maintenance_due, associated_act,
          telemetry_json, last_breakdown_reason, last_breakdown_at, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `);

      for (const eq of fleet) {
        stmt.run(
          eq.id,
          eq.projectId,
          eq.name,
          eq.category,
          eq.categoryName,
          eq.tag,
          eq.operator,
          eq.status,
          eq.location,
          eq.operatingHours,
          eq.hoursToday,
          eq.fuelLevel,
          eq.engineTemp,
          eq.batteryVoltage || '24.2 V',
          eq.vibrationLevel || '0.8 mm/s',
          eq.maintenanceDue,
          eq.associatedAct || null,
          JSON.stringify(eq.telemetry || {}),
          eq.lastBreakdownReason || null,
          eq.lastBreakdownAt || null,
          eq.createdAt || new Date().toISOString()
        );
      }
    });
  }

  recordEquipmentBreakdown(params: {
    projectId?: string;
    equipmentId: string;
    breakdownReason: string;
    delayReason?: string;
    activityCode?: string;
    reportedBy?: string;
    supervisorRole?: string;
    estimatedDowntimeHours?: number;
    notes?: string;
  }) {
    return this.transaction(() => {
      const projectId = params.projectId || 'PRJ-OIL-2026';
      
      // Ensure equipment is seeded if not present
      let eq = this.db.prepare('SELECT * FROM equipment WHERE id = ? AND project_id = ?').get(params.equipmentId, projectId) as any;
      if (!eq) {
        eq = this.db.prepare('SELECT * FROM equipment WHERE id = ?').get(params.equipmentId) as any;
      }
      if (!eq) {
        this.seedDefaultEquipment(projectId);
        eq = this.db.prepare('SELECT * FROM equipment WHERE id = ? AND project_id = ?').get(params.equipmentId, projectId) as any;
      }

      const previousStatus = eq?.status || 'ACTIVE';
      const nowIso = new Date().toISOString();
      const timestampStr = new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }) + ' IST';
      const todayDate = nowIso.split('T')[0];

      // 1. Update equipment breakdown state in SQLite
      this.db.prepare(`
        UPDATE equipment 
        SET status = 'BREAKDOWN',
            last_breakdown_reason = ?,
            last_breakdown_at = ?
        WHERE id = ?
      `).run(params.breakdownReason, timestampStr, params.equipmentId);

      // 2. Prepare delay reason and notes for DPR
      const equipmentName = eq?.name || params.equipmentId;
      const actCode = params.activityCode || eq?.associated_act || 'PIP-L5-024';
      const delayReason = params.delayReason || `Critical Equipment Breakdown: ${equipmentName} (${params.breakdownReason})`;
      const reportedBy = params.reportedBy || eq?.operator || 'Field Equipment Operator';
      const supervisorRole = params.supervisorRole || 'Plant & Machinery Lead';
      const downtimeHours = params.estimatedDowntimeHours || 6;
      const notes = params.notes || `Equipment ${equipmentName} (${params.equipmentId}) breakdown recorded at ${timestampStr}. Reason: ${params.breakdownReason}. Estimated downtime: ${downtimeHours} hours. Immediate mechanic dispatch required.`;

      // 3. Write DPR record in SQLite dpr table
      const dprRecordId = `DPR-BRK-${Date.now().toString().slice(-6)}`;
      this.db.prepare(`
        INSERT INTO dpr (
          id, project_id, activity_code, equipment_id, report_date,
          completed_quantity, unit, delay_reason, notes, reported_by, supervisor_role, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        dprRecordId,
        projectId,
        actCode,
        params.equipmentId,
        todayDate,
        0,
        'hours',
        delayReason,
        notes,
        reportedBy,
        supervisorRole,
        nowIso
      );

      // 4. Also synchronize with general DPR engine (updates schedule activities, logs conflict under FIDIC Cl. 8.4)
      this.recordDpr(projectId, {
        activityCode: actCode,
        completedQuantity: 0,
        unit: 'hours',
        delayReason,
        notes,
        reportedBy,
        supervisorRole,
      });

      // 5. Write audit record in SQLite audit_logs
      const auditRecord = this.addAuditLog({
        projectId,
        actorName: reportedBy,
        actorRole: supervisorRole,
        action: 'EQUIPMENT_BREAKDOWN_RECORDED',
        entityType: 'DPR',
        entityId: params.equipmentId,
        previousValue: previousStatus,
        newValue: 'BREAKDOWN',
        reason: `Equipment breakdown: ${params.breakdownReason}. DPR delay logged for activity ${actCode}: ${delayReason}`,
      });

      // Fetch updated equipment record
      const updatedEq = this.getEquipment(projectId).find(e => e.id === params.equipmentId);

      const dprRecord: DPRRecord = {
        id: dprRecordId,
        projectId,
        activityCode: actCode,
        equipmentId: params.equipmentId,
        reportDate: todayDate,
        completedQuantity: 0,
        unit: 'hours',
        delayReason,
        notes,
        reportedBy,
        supervisorRole,
        createdAt: nowIso,
      };

      return {
        success: true,
        equipment: updatedEq,
        dprRecord,
        auditRecord,
        message: `Equipment breakdown logged for ${params.equipmentId}, delay reason recorded in DPR table, and audit trail saved in SQLite!`,
      };
    });
  }

  getDprRecords(projectId?: string): DPRRecord[] {
    let query = 'SELECT * FROM dpr';
    const params: any[] = [];
    if (projectId) {
      query += ' WHERE project_id = ?';
      params.push(projectId);
    }
    query += ' ORDER BY created_at DESC';
    try {
      const rows = this.db.prepare(query).all(...params) as any[];
      return rows.map(r => ({
        id: r.id,
        projectId: r.project_id,
        activityCode: r.activity_code || undefined,
        equipmentId: r.equipment_id || undefined,
        reportDate: r.report_date,
        completedQuantity: r.completed_quantity,
        unit: r.unit,
        delayReason: r.delay_reason || undefined,
        notes: r.notes || undefined,
        reportedBy: r.reported_by,
        supervisorRole: r.supervisor_role || undefined,
        createdAt: r.created_at,
      }));
    } catch (_) {
      return [];
    }
  }

  // --- WEATHER & DELAYS ---
  recordWeatherStoppage(data: {
    projectId?: string;
    activityCode?: string;
    affectedActivities?: Array<string | { activityCode?: string; id?: string; name?: string }>;
    reason?: string;
    rainfallMM?: number;
    temperature?: number;
    windSpeedKmh?: number;
    humidity?: number;
    workSuspensionActive?: boolean;
    reportedBy?: string;
    supervisorRole?: string;
    locationGeofence?: string;
    notes?: string;
    mitigationAction?: string;
    estimatedDelayDays?: number;
  }) {
    return this.transaction(() => {
      const projectId = data.projectId || this.getProjects()[0]?.id || 'PRJ-OIL-2026';
      const updId = `UPD-WTH-${Date.now().toString().slice(-6)}`;
      const timestampStr = new Date().toLocaleTimeString('en-IN', { timeZone: 'Asia/Kolkata', hour: '2-digit', minute: '2-digit' }) + ' IST';
      const reportedBy = data.reportedBy || 'AWS-09 Meteorological Sensor';
      const supervisorRole = data.supervisorRole || 'Site Safety & Weather In-Charge';
      const geofence = data.locationGeofence || '27.4825° N, 95.3225° E (Duliajan Station #09)';
      const rainfallMM = data.rainfallMM !== undefined ? Number(data.rainfallMM) : 45.0;
      const workSuspensionActive = data.workSuspensionActive !== undefined ? Boolean(data.workSuspensionActive) : rainfallMM >= 25.0;
      const reason = data.reason || (workSuspensionActive 
        ? `Heavy Monsoon Rain (${rainfallMM}mm) exceeding safety threshold (>25mm/hr). Outdoor work suspended under FIDIC Cl. 8.4(c).`
        : `Weather update: Rainfall ${rainfallMM}mm within normal operating limits.`);
      
      // Resolve primary activity code and all affected codes
      let activityCodes: string[] = [];
      if (Array.isArray(data.affectedActivities) && data.affectedActivities.length > 0) {
        activityCodes = data.affectedActivities.map(a => 
          typeof a === 'string' ? a : (a.activityCode || a.id || 'PIP-L5-024')
        );
      } else if (data.activityCode) {
        activityCodes = [data.activityCode];
      } else {
        activityCodes = ['PIP-L5-024', 'CIV-L5-019', 'NDT-L6-044'];
      }
      const primaryActivityCode = activityCodes[0] || 'PIP-L5-024';

      const entities = JSON.stringify({
        discipline: 'WEATHER_STOPPAGE',
        delayReason: reason,
        rainfallMM,
        temperature: data.temperature ?? 32.0,
        windSpeedKmh: data.windSpeedKmh ?? 18.0,
        humidity: data.humidity ?? 88,
        workSuspensionActive,
        affectedActivityCodes: activityCodes,
        mitigationAction: data.mitigationAction || 'Hydrostatic pipe caps secured; crews redeployed to indoor fabrication yard',
        estimatedDelayDays: data.estimatedDelayDays ?? 1.0,
        notes: data.notes || '',
      });

      // 1. Insert into informal_site_updates
      this.db.prepare(`
        INSERT INTO informal_site_updates (
          id, project_id, source, raw_input, timestamp, reported_by, supervisor_role,
          location_geofence, extracted_entities, matched_activity_code, linking_confidence,
          is_out_of_sequence, linking_status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        updId,
        projectId,
        'SITE_DIARY',
        `Weather Stoppage Notice: Precipitation ${rainfallMM}mm recorded at ${geofence}. Suspension Active: ${workSuspensionActive ? 'YES' : 'NO'}. Target: ${activityCodes.join(', ')}. Reason: ${reason}`,
        timestampStr,
        reportedBy,
        supervisorRole,
        geofence,
        entities,
        primaryActivityCode,
        99.5,
        0,
        'CONFIRMED'
      );

      // 2. Insert into audit_logs
      const auditRecord = this.addAuditLog({
        projectId,
        actorName: reportedBy,
        actorRole: supervisorRole,
        action: 'WEATHER_STOPPAGE_RECORDED',
        entityType: 'WEATHER' as any,
        entityId: primaryActivityCode,
        previousValue: workSuspensionActive ? 'WORK_PERMITTED' : 'WORK_SUSPENDED',
        newValue: workSuspensionActive ? 'WORK_SUSPENDED' : 'WORK_RESUMED',
        reason: `FIDIC Cl. 8.4(c) Weather Notice: ${reason}`,
      });

      if (activityCodes.length > 1) {
        for (const actCode of activityCodes.slice(1)) {
          this.addAuditLog({
            projectId,
            actorName: reportedBy,
            actorRole: supervisorRole,
            action: 'WEATHER_STOPPAGE_RECORDED',
            entityType: 'ACTIVITY',
            entityId: actCode,
            previousValue: workSuspensionActive ? 'WORK_PERMITTED' : 'WORK_SUSPENDED',
            newValue: workSuspensionActive ? 'WORK_SUSPENDED' : 'WORK_RESUMED',
            reason: `Suspended due to site weather event ${updId}: ${reason}`,
          });
        }
      }

      // 3. Update activities in SQLite if suspension active
      for (const actCode of activityCodes) {
        try {
          this.db.prepare(`
            UPDATE schedule_activities 
            SET last_evidence_update = ?
            WHERE activity_code = ? AND project_id = ?
          `).run(
            workSuspensionActive ? `Weather Stoppage: ${reason}` : 'Weather Normal: Work Resumed',
            actCode,
            projectId
          );
        } catch (_) {}
      }

      return {
        success: true,
        updateId: updId,
        auditId: auditRecord.id,
        timestamp: timestampStr,
        projectId,
        primaryActivityCode,
        affectedActivityCodes: activityCodes,
        workSuspensionActive,
        rainfallMM,
        reason,
        auditRecord,
      };
    });
  }

  getLatestWeatherUpdate(projectId?: string) {
    let query = `
      SELECT * FROM informal_site_updates 
      WHERE extracted_entities LIKE '%WEATHER_STOPPAGE%'
    `;
    const params: any[] = [];
    if (projectId) {
      query += ' AND project_id = ?';
      params.push(projectId);
    }
    query += ' ORDER BY rowid DESC LIMIT 1';

    try {
      const row = this.db.prepare(query).get(...params) as any;
      if (!row) return null;
      let entities: any = {};
      try {
        entities = JSON.parse(row.extracted_entities || '{}');
      } catch (_) {}
      return {
        id: row.id,
        projectId: row.project_id,
        source: row.source,
        rawInput: row.raw_input,
        timestamp: row.timestamp,
        reportedBy: row.reported_by,
        supervisorRole: row.supervisor_role,
        locationGeofence: row.location_geofence,
        matchedActivityCode: row.matched_activity_code,
        entities,
      };
    } catch (_) {
      return null;
    }
  }

  getWeatherStoppages(projectId?: string) {
    let query = `
      SELECT * FROM informal_site_updates 
      WHERE extracted_entities LIKE '%WEATHER_STOPPAGE%'
    `;
    const params: any[] = [];
    if (projectId) {
      query += ' AND project_id = ?';
      params.push(projectId);
    }
    query += ' ORDER BY rowid DESC LIMIT 50';

    try {
      const rows = this.db.prepare(query).all(...params) as any[];
      return rows.map(r => {
        let entities: any = {};
        try {
          entities = JSON.parse(r.extracted_entities || '{}');
        } catch (_) {}
        return {
          id: r.id,
          projectId: r.project_id,
          source: r.source,
          rawInput: r.raw_input,
          timestamp: r.timestamp,
          reportedBy: r.reported_by,
          supervisorRole: r.supervisor_role,
          locationGeofence: r.location_geofence,
          matchedActivityCode: r.matched_activity_code,
          entities,
        };
      });
    } catch (_) {
      return [];
    }
  }

  getInformalUpdates(projectId?: string) {
    let query = 'SELECT * FROM informal_site_updates';
    const params: any[] = [];
    if (projectId) {
      query += ' WHERE project_id = ?';
      params.push(projectId);
    }
    query += ' ORDER BY rowid DESC LIMIT 100';

    const rows = this.db.prepare(query).all(...params) as any[];
    return rows.map(r => {
      let entities: any = {};
      try {
        entities = JSON.parse(r.extracted_entities || '{}');
      } catch (_) {}
      return {
        id: r.id,
        projectId: r.project_id,
        source: r.source,
        rawInput: r.raw_input,
        timestamp: r.timestamp,
        reportedBy: r.reported_by,
        supervisorRole: r.supervisor_role,
        locationGeofence: r.location_geofence,
        extractedEntities: entities,
        matchedActivityCode: r.matched_activity_code,
        linkingConfidence: r.linking_confidence,
        isOutOfSequence: Boolean(r.is_out_of_sequence),
        linkingStatus: r.linking_status,
      };
    });
  }

  // --- USERS & AUTH ---
  registerUser(u: {
    id?: string;
    name: string;
    phone?: string;
    email?: string;
    role: string;
    department: string;
    projectId: string;
    badgeNumber?: string;
    trade?: string;
  }) {
    return this.transaction(() => {
      const id = u.id || `USR-${Date.now().toString().slice(-4)}`;
      const createdAt = new Date().toISOString();
      
      this.db.prepare(`
        INSERT INTO users (id, name, phone, email, role, department, project_id, badge_number, trade, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        id, u.name, u.phone || null, u.email || null, u.role, u.department,
        u.projectId, u.badgeNumber || null, u.trade || null, createdAt
      );
  
      if (u.role.toLowerCase().includes('labour') || u.role.toLowerCase().includes('weld') || u.role.toLowerCase().includes('trade')) {
        const existingWorker = this.db.prepare('SELECT id FROM workers WHERE badge_number = ? AND project_id = ?').get(u.badgeNumber || id, u.projectId);
        if (!existingWorker) {
          this.createWorker(u.projectId, {
            id: `WRK-${id}`,
            badgeNumber: u.badgeNumber || `LAB-${id}`,
            name: u.name,
            trade: (u.trade || 'LABOUR') as any,
            skills: [u.trade || 'General Tradesperson'],
            contractor: 'Assigned Contractor Gang',
          });
        }
      }
  
      this.addAuditLog({
        projectId: u.projectId,
        actorName: u.name,
        actorRole: u.role,
        action: 'USER_REGISTERED',
        entityType: 'ATTENDANCE',
        entityId: id,
        newValue: `${u.role} (${u.department}) joined ${u.projectId}`,
        reason: 'Role-based access credentials established',
      });
  
      return this.getUserById(id);
    });
  }

  getUserById(id: string) {
    return this.db.prepare('SELECT * FROM users WHERE id = ?').get(id) as any;
  }

  getUsers(projectId?: string) {
    if (projectId) {
      return this.db.prepare('SELECT * FROM users WHERE project_id = ? ORDER BY created_at DESC').all(projectId) as any[];
    }
    return this.db.prepare('SELECT * FROM users ORDER BY created_at DESC').all() as any[];
  }

  // --- HARD DATA WIPE (No dummy data!) ---
  wipeAllData() {
    return this.transaction(() => {
      this.db.exec(`
        DELETE FROM dpr;
        DELETE FROM equipment;
        DELETE FROM users;
        DELETE FROM audit_logs;
        DELETE FROM informal_site_updates;
        DELETE FROM conflicts;
        DELETE FROM materials_ledger;
        DELETE FROM workers;
        DELETE FROM activity_steps;
        DELETE FROM schedule_activities;
        DELETE FROM wbs_nodes;
        DELETE FROM projects;
      `);
    });
  }

  // --- OPTIONAL SIH26122 OFFICIAL BENCHMARK SEED ---
  // Only called when the user EXPLICITLY clicks "Load Oil India Official Benchmark"
  loadOilBenchmark() {
    return this.transaction(() => {
      this.wipeAllData();
  
      // 1. Create Project
      this.createProject({
        id: 'PRJ-OIL-2026',
        code: 'OIL-PL-024',
        name: 'Trunk Crude Oil Pipeline & Terminal Expansion Package II',
        client: 'Oil India Limited (OIL)',
        contractorJV: 'Central Viaduct & Petro-Infrastructure Consortium',
        contractType: 'FIDIC Red Book Cl. 8.4',
        lifecycle: 'EXECUTION',
        location: 'Duliajan - Digboi Pipeline Corridor, Assam',
        budget: 245000000,
        currency: 'INR (₹ Cr)',
        startDate: '2026-01-15',
        plannedFinishDate: '2026-11-30',
        status: 'ON_TRACK',
      });
  
      // 2. Insert WBS Hierarchy
      const insertWbs = this.db.prepare(`
        INSERT INTO wbs_nodes (id, project_id, code, name, level, parent_id, discipline)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `);
      const wbsNodes = [
        ['WBS-1', 'PRJ-OIL-2026', '01', 'Mobilization, RoW Clearing & Topographic Surveys', 1, null, 'CIVIL'],
        ['WBS-2', 'PRJ-OIL-2026', '02', 'Duliajan Pumping Station & Tank Farm Civils', 1, null, 'CIVIL'],
        ['WBS-3', 'PRJ-OIL-2026', '03', 'Trunk Pipeline Corridor (Duliajan to Digboi)', 1, null, 'PIPING'],
        ['WBS-4', 'PRJ-OIL-2026', '03.02', 'Corridor Section 2 — Viaduct & River Crossings', 2, 'WBS-3', 'PIPING'],
        ['WBS-5', 'PRJ-OIL-2026', '03.02.04', 'WP-104 Dihing River Viaduct Pier 24-26 & Line 24 Trunk', 3, 'WBS-4', 'PIPING'],
        ['WBS-6', 'PRJ-OIL-2026', '04', 'Cathodic Protection & Substation Infrastructure', 1, null, 'ELECTRICAL'],
        ['WBS-7', 'PRJ-OIL-2026', '05', 'SCADA, Telemetry & Metering Station', 1, null, 'INSTRUMENTATION'],
        ['WBS-8', 'PRJ-OIL-2026', '06', 'Pre-Commissioning, Caliper Pigging & Hydrostatic Testing', 1, null, 'COMMISSIONING'],
      ];
      for (const w of wbsNodes) {
        insertWbs.run(...w);
      }
  
      // 3. Insert 12 L5/L6 Schedule Activities with Realistic Triangulation Variances
      const insertAct = this.db.prepare(`
        INSERT INTO schedule_activities (
          id, project_id, activity_code, uwid, wbs_code, name, description, discipline,
          planned_start, planned_finish, duration_days, total_float_days, is_critical_path,
          predecessor_codes, successor_codes,
          planned_progress, contractor_reported_progress, quantity_survey_progress, qc_passed_progress,
          drone_lidar_progress, validated_consensus_progress, progress_confidence, tolerance_exceeded,
          delta_vs_consensus, planned_quantity, installed_quantity, unit, assigned_supervisor, workforce_count,
          last_evidence_update, freshness_state
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `);
  
      const activities = [
        [
          'ACT-PIP-024', 'PRJ-OIL-2026', 'PIP-L5-024', 'UWID-OIL-2026-PIP024', '03.02.04',
          'Pipe Stringing & Automatic Orbital Welding (12" API 5L X65 Pipeline)',
          'Fit-up, stringing, automatic orbital welding, NDT radiography, and trench lower-in for 12-inch API 5L X65 PSL2 line pipe.',
          'PIPING', '2026-09-10', '2026-09-28', 18, 2, 1,
          JSON.stringify(['CIV-L5-019']), JSON.stringify(['PIP-L5-025', 'PIP-L6-026']),
          75.0, 82.0, 74.5, 68.0, 68.2, 71.4, 94.2, 1, 10.6, 420, 304, 'meters', 'R. K. Sharma (Lead Piping Inspector)', 18,
          '4 hours ago', 'CURRENT'
        ],
        [
          'ACT-STR-3088', 'PRJ-OIL-2026', 'ACT-3088', 'UWID-EXP-2024-03088', '03.02.04',
          'Segment B-14 Post-Tensioned Pier Cap (Dihing River Pier 24-26 Foundations)',
          'Reinforced concrete post-tensioned pier cap using Fe500D rebar and C40/50 concrete.',
          'CIVIL', '2026-09-05', '2026-09-25', 20, 0, 1,
          JSON.stringify(['CIV-L5-018']), JSON.stringify(['PIP-L5-024']),
          85.0, 92.0, 86.0, 75.0, 82.5, 80.8, 91.0, 1, 11.2, 180, 148, 'cu.m', 'A. K. Baruah (Senior Civil Engineer)', 24,
          '6 hours ago', 'CURRENT'
        ],
        [
          'ACT-CIV-019', 'PRJ-OIL-2026', 'CIV-L5-019', 'UWID-OIL-2026-CIV019', '03.02.04',
          'Corridor Trench Excavation, Shoring & Dewatering (Chainage 14+200 to 14+850)',
          'Mechanized trenching to 2.4m invert depth with sheet pile shoring and continuous dewatering for pipe laying corridor.',
          'CIVIL', '2026-08-25', '2026-09-12', 18, 5, 0,
          JSON.stringify([]), JSON.stringify(['PIP-L5-024']),
          100.0, 100.0, 100.0, 100.0, 99.8, 100.0, 99.5, 0, 0.0, 650, 650, 'meters', 'M. Gogoi (Site Foreman)', 12,
          '14 days ago', 'STALE'
        ],
        [
          'ACT-PIP-025', 'PRJ-OIL-2026', 'PIP-L5-025', 'UWID-OIL-2026-PIP025', '03.02.04',
          'Field Joint Coating — 3-Layer Heat Shrink Sleeves (Joints #W24-01 to #W24-50)',
          'Surface grit blast cleaning to Sa 2.5, induction pre-heating 220°C, sleeve wrapping and 15kV holiday detection.',
          'PIPING', '2026-09-18', '2026-09-30', 12, 1, 1,
          JSON.stringify(['PIP-L5-024']), JSON.stringify(['PIP-L5-027']),
          60.0, 68.0, 58.0, 52.0, 56.0, 55.4, 92.5, 1, 12.6, 50, 28, 'joints', 'Mukul Barman (Coating Inspector)', 8,
          '3 hours ago', 'CURRENT'
        ],
        [
          'ACT-PIP-026', 'PRJ-OIL-2026', 'PIP-L6-026', 'UWID-OIL-2026-PIP026', '03.02.04',
          'NDT Inspection — 100% Radiography & Phased Array Ultrasonic Testing (PAUT)',
          'Full circumference radiographic testing and phased array ultrasonic evaluation on API 5L X65 field girth welds.',
          'PIPING', '2026-09-14', '2026-09-29', 15, 0, 1,
          JSON.stringify(['PIP-L5-024']), JSON.stringify(['PIP-L5-027']),
          70.0, 85.0, 68.0, 64.0, 66.0, 66.2, 95.0, 1, 18.8, 50, 32, 'weld joints', 'Deepankar Saikia (NDT Specialist)', 6,
          '2 hours ago', 'CURRENT'
        ],
        [
          'ACT-PIP-027', 'PRJ-OIL-2026', 'PIP-L5-027', 'UWID-OIL-2026-PIP027', '03.02.04',
          'Pipeline Trench Lower-in, Rock Shield Padding & Tie-in Spool Fit-up',
          'Side-boom synchronized lowering-in, padding with select backfill material and installation of 4.5mm HDPE rock shield.',
          'PIPING', '2026-09-22', '2026-10-06', 14, 1, 1,
          JSON.stringify(['PIP-L5-025', 'PIP-L6-026']), JSON.stringify(['PIP-L6-033']),
          40.0, 45.0, 38.0, 35.0, 36.5, 36.6, 90.0, 1, 8.4, 420, 155, 'meters', 'Vikram Joshi (Field Operations)', 14,
          '5 hours ago', 'CURRENT'
        ],
        [
          'ACT-MEC-031', 'PRJ-OIL-2026', 'MEC-L5-031', 'UWID-OIL-2026-MEC031', '03.02',
          'Sectional Block Valve (SBV-04) Skid Installation & Flange Torquing',
          'Foundation placement, 12" Class 600 trunnion ball valve alignment, RTJ gasket insertion and hydraulic bolt torquing.',
          'MECHANICAL', '2026-09-15', '2026-10-02', 17, 4, 0,
          JSON.stringify(['PIP-L5-024']), JSON.stringify(['INS-L5-055']),
          50.0, 55.0, 50.0, 48.0, 49.0, 49.1, 93.8, 1, 5.9, 1, 0.5, 'valve skids', 'Prasanta Hazarika (Mechanical Tech)', 10,
          '1 day ago', 'RECENT'
        ],
        [
          'ACT-ELC-042', 'PRJ-OIL-2026', 'ELC-L5-042', 'UWID-OIL-2026-ELC042', '04',
          'Impressed Current Cathodic Protection (ICCP) Deep Anode Bed & Test Posts',
          'Deep well drilling, MMO tubular titanium anode installation, calcined coke breeze backfill and test station calibration.',
          'ELECTRICAL', '2026-09-20', '2026-10-10', 20, 6, 0,
          JSON.stringify(['PIP-L5-024']), JSON.stringify(['PIP-L6-033']),
          30.0, 38.0, 30.0, 28.0, 29.0, 29.1, 88.5, 1, 8.9, 12, 3, 'test stations', 'Manoj Sonowal (CP Specialist)', 6,
          '8 hours ago', 'CURRENT'
        ],
        [
          'ACT-INS-055', 'PRJ-OIL-2026', 'INS-L5-055', 'UWID-OIL-2026-INS055', '05',
          'SCADA Remote Telemetry Unit (RTU) & Coriolis Custody Meter Integration',
          'Panel hookup, redundant solar power supply integration, pressure/temperature transmitter calibration and loop checks.',
          'INSTRUMENTATION', '2026-09-25', '2026-10-18', 23, 8, 0,
          JSON.stringify(['MEC-L5-031']), JSON.stringify(['PIP-L6-033']),
          15.0, 18.0, 15.0, 14.0, 14.5, 14.6, 91.0, 0, 3.4, 4, 0.6, 'panels', 'B. C. Bhattacharya (SCADA Lead)', 5,
          '1 day ago', 'RECENT'
        ],
        [
          'ACT-PIP-033', 'PRJ-OIL-2026', 'PIP-L6-033', 'UWID-OIL-2026-PIP033', '06',
          'Pre-Commissioning Hydrostatic Pressure Testing (108 bar Hold for 24h)',
          'Test header fabrication, filling with inhibited water, 4-stage pressurization to 108 bar and 24-hour pressure hold chart.',
          'PIPING', '2026-10-08', '2026-10-18', 10, 0, 1,
          JSON.stringify(['PIP-L5-027', 'MEC-L5-031']), JSON.stringify(['CIV-L6-022']),
          0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 99.0, 0, 0.0, 4.8, 0.0, 'km', 'R. K. Sharma (Lead Piping Inspector)', 8,
          'Pending startup', 'CURRENT'
        ],
        [
          'ACT-CIV-022', 'PRJ-OIL-2026', 'CIV-L6-022', 'UWID-OIL-2026-CIV022', '01',
          'Right-of-Way (RoW) Clean-up, Topsoil Reinstatement & Slope Stabilization',
          'Removal of temporary access ramps, contouring, topsoil respreading, vetiver grass planting for riverbank erosion prevention.',
          'CIVIL', '2026-10-15', '2026-11-10', 26, 12, 0,
          JSON.stringify(['PIP-L6-033']), JSON.stringify([]),
          0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 98.0, 0, 0.0, 12.5, 0.0, 'km', 'M. Gogoi (Site Foreman)', 10,
          'Scheduled post-hydrotest', 'RECENT'
        ],
        [
          'ACT-MEC-035', 'PRJ-OIL-2026', 'MEC-L6-035', 'UWID-OIL-2026-MEC035', '06',
          'Pig Launcher & Receiver Scraper Barrel Assembly & Pressure Relief Setting',
          'Installation of end closure doors, safety interlock mechanisms, thermal relief valves and caliper pig trial loading.',
          'MECHANICAL', '2026-09-28', '2026-10-14', 16, 5, 0,
          JSON.stringify(['MEC-L5-031']), JSON.stringify(['PIP-L6-033']),
          10.0, 12.0, 10.0, 8.0, 9.5, 9.2, 92.0, 0, 2.8, 2, 0.2, 'assemblies', 'Prasanta Hazarika (Mechanical Tech)', 6,
          '6 hours ago', 'CURRENT'
        ]
      ];
  
      for (const a of activities) {
        insertAct.run(...a);
      }
  
      // 4. Insert Activity Steps
      const insertStep = this.db.prepare(`
        INSERT INTO activity_steps (id, activity_id, name, weight, completed, completion_date)
        VALUES (?, ?, ?, ?, ?, ?)
      `);
      const steps = [
        ['STP-1', 'ACT-PIP-024', 'Pipe Stringing & Placement along RoW', 20, 1, '2026-09-14'],
        ['STP-2', 'ACT-PIP-024', 'Internal Clamp Fit-up & Root Pass Welding', 30, 1, '2026-09-20'],
        ['STP-3', 'ACT-PIP-024', 'Hot, Fill & Cap Welding Passes (AWS E7018-G)', 25, 0, null],
        ['STP-4', 'ACT-PIP-024', '100% Radiographic Testing (RT) & PAUT', 15, 0, null],
        ['STP-5', 'ACT-PIP-024', 'Joint Coating & Trench Lower-in', 10, 0, null],
        ['STP-11', 'ACT-STR-3088', 'Rebar Cage Prefabrication (Fe500D)', 40, 1, '2026-09-12'],
        ['STP-12', 'ACT-STR-3088', 'Post-Tensioning Ducts & Tendon Profiling', 20, 1, '2026-09-16'],
        ['STP-13', 'ACT-STR-3088', 'Engineered Shuttering & Pre-pour QA Clearance', 15, 1, '2026-09-18'],
        ['STP-14', 'ACT-STR-3088', 'C40/50 Monolithic Concrete Pour (Batch LB-2024-881)', 15, 1, '2026-09-20'],
        ['STP-15', 'ACT-STR-3088', 'Hydraulic Post-Tensioning Jacking (28-day break pending)', 10, 0, null],
        ['STP-21', 'ACT-PIP-025', 'Surface Grit Blasting to Sa 2.5 Profile', 25, 1, '2026-09-21'],
        ['STP-22', 'ACT-PIP-025', 'Induction Coil Pre-heating to 220°C', 25, 1, '2026-09-23'],
        ['STP-23', 'ACT-PIP-025', 'Canusa GTS-PP Heat Shrink Sleeve Wrapping & Shrinking', 25, 0, null],
        ['STP-24', 'ACT-PIP-025', '15kV Holiday Spark Testing & Peel Adhesion Validation', 25, 0, null],
      ];
      for (const s of steps) {
        insertStep.run(...s);
      }
  
      // 5. Insert 10 Workers with Real GPS Coordinates around Duliajan (27.4825° N, 95.3225° E)
      const insertWorker = this.db.prepare(`
        INSERT INTO workers (
          id, project_id, badge_number, name, trade, skills, contractor,
          safety_cert_valid_till, medical_clearance, attendance_status, verification_method, confidence_score,
          latitude, longitude, last_clock_in
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `);
  
      const workers = [
        [
          'WRK-101', 'PRJ-OIL-2026', 'LAB-IND-0442', 'Tapan Das', 'WELDER',
          JSON.stringify(['6G Pipe TIG/MIG', 'API 1104 Downhill', 'SMAW E7018']),
          'PetroFab Infrastructure Ltd', '2027-04-15', 1, 'VERIFIED_PRESENT', 'GEOFENCE_BIOMETRIC', 98.5,
          27.4828, 95.3221, '07:30 AM IST (Gate 1 Geofence: 27.4828° N, 95.3221° E)'
        ],
        [
          'WRK-102', 'PRJ-OIL-2026', 'LAB-IND-0443', 'Sunil Karmakar', 'FITTER',
          JSON.stringify(['Pipe Fitting 12"-24"', 'Cold Cutting Beveling', 'Flange Torque-Up']),
          'PetroFab Infrastructure Ltd', '2026-12-30', 1, 'VERIFIED_PRESENT', 'GEOFENCE_BIOMETRIC', 97.8,
          27.4822, 95.3230, '07:34 AM IST (Zone B Spool Bay: 27.4822° N, 95.3230° E)'
        ],
        [
          'WRK-103', 'PRJ-OIL-2026', 'LAB-IND-0489', 'Biren Chetia', 'OPERATOR',
          JSON.stringify(['Tadano 50T Heavy Crane', 'Hydraulic Excavator CAT 320D', 'Trench Lowering Safe Slinging']),
          'Heavy Rigging & Trans Logistics', '2027-01-10', 1, 'VERIFIED_PRESENT', 'GEOFENCE_BIOMETRIC', 96.4,
          27.4831, 95.3218, '07:42 AM IST (Heavy Lift Pad Ch. 13+200: 27.4831° N, 95.3218° E)'
        ],
        [
          'WRK-104', 'PRJ-OIL-2026', 'LAB-IND-0512', 'Deepankar Saikia', 'SURVEYOR',
          JSON.stringify(['NDT Radiography Level-II', 'Phased Array UT (PAUT)', 'Digital RT Film Interpretation']),
          'Assam NDT & Inspection Services', '2027-06-20', 1, 'VERIFIED_PRESENT', 'GEOFENCE_BIOMETRIC', 99.1,
          27.4819, 95.3241, '07:50 AM IST (Radiography QA Lab: 27.4819° N, 95.3241° E)'
        ],
        [
          'WRK-105', 'PRJ-OIL-2026', 'LAB-IND-0525', 'Hemanta Borah', 'RIGGER',
          JSON.stringify(['Heavy Pipe Side-Boom Slinging', 'Spool Tagline Control', 'Confined Space Rescue']),
          'Heavy Rigging & Trans Logistics', '2026-11-15', 1, 'VERIFIED_PRESENT', 'GEOFENCE_BIOMETRIC', 95.2,
          27.4835, 95.3212, '07:55 AM IST (Stringing Berth 4: 27.4835° N, 95.3212° E)'
        ],
        [
          'WRK-106', 'PRJ-OIL-2026', 'LAB-IND-0540', 'Manoj Sonowal', 'ELECTRICIAN',
          JSON.stringify(['Cathodic Protection Systems', 'Deep Anode Bed Cabling', 'Explosion-Proof Ex-d Wiring']),
          'Corr-Shield Tech India', '2027-03-31', 1, 'VERIFIED_PRESENT', 'GEOFENCE_BIOMETRIC', 94.0,
          27.4842, 95.3198, '08:02 AM IST (ICCP Groundbed Station 2: 27.4842° N, 95.3198° E)'
        ],
        [
          'WRK-107', 'PRJ-OIL-2026', 'LAB-IND-0566', 'Rajen Gogoi', 'LABOUR',
          JSON.stringify(['Trench Shoring Timbering', 'Rock Shield Padding Placement', 'Dewatering Pumps Op']),
          'Duliajan Allied Earthworks Gang', '2027-08-14', 1, 'VERIFIED_PRESENT', 'GEOFENCE_BIOMETRIC', 93.5,
          27.4815, 95.3255, '08:10 AM IST (Chainage 14+450 Crossing: 27.4815° N, 95.3255° E)'
        ],
        [
          'WRK-108', 'PRJ-OIL-2026', 'LAB-IND-0582', 'Diganta Morang', 'LABOUR',
          JSON.stringify(['HSE Gas Detector Watch', 'Confined Space Attendant', 'Fire Suppression Watch']),
          'PetroFab Infrastructure Ltd', '2027-05-18', 1, 'VERIFIED_PRESENT', 'GEOFENCE_BIOMETRIC', 98.0,
          27.4826, 95.3227, '08:15 AM IST (Trench Gas Watch Post 1: 27.4826° N, 95.3227° E)'
        ],
        [
          'WRK-109', 'PRJ-OIL-2026', 'LAB-IND-0599', 'Prasanta Hazarika', 'FITTER',
          JSON.stringify(['Hydrostatic Test Manifold Hookup', 'Torque-Tightening Class 600', 'Flange RTJ Jointing']),
          'PetroFab Infrastructure Ltd', '2027-02-28', 1, 'VERIFIED_PRESENT', 'GEOFENCE_BIOMETRIC', 96.8,
          27.4829, 95.3235, '08:20 AM IST (Valve Skid SV-04 Pad: 27.4829° N, 95.3235° E)'
        ],
        [
          'WRK-110', 'PRJ-OIL-2026', 'LAB-IND-0615', 'Mukul Barman', 'MASON',
          JSON.stringify(['Induction Pre-heating 220°C', 'Canusa GTS-PP Heat Shrink Sleeves', '15kV Holiday Detector']),
          'PetroFab Infrastructure Ltd', '2026-10-30', 1, 'VERIFIED_PRESENT', 'GEOFENCE_BIOMETRIC', 97.2,
          27.4821, 95.3216, '08:25 AM IST (Joint Coating Station J-18: 27.4821° N, 95.3216° E)'
        ],
      ];
  
      for (const w of workers) {
        insertWorker.run(...w);
      }
  
      // 6. Insert 15 Materials Entries (API 5L X65 pipes, bend spools, flange sets, reduction tees)
      const insertMat = this.db.prepare(`
        INSERT INTO materials_ledger (
          id, project_id, doc_type, doc_number, material_code, description,
          quantity, unit, source_supplier, destination_location, associated_activity_code,
          issued_to_supervisor, date, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `);
  
      const materials = [
        [
          'TX-GRN-501', 'PRJ-OIL-2026', 'GRN', 'GRN-2026-501', 'MAT-PIPE-12X65',
          '12" Seamless Carbon Steel Line Pipe, API 5L Gr. X65 PSL2, 12.7mm WT, 3LPE Coated',
          240, 'meters (20 spools)', 'Welspun Corp Ltd, Gujarat', 'Duliajan Central Pipe Yard (Zone B)',
          'PIP-L5-024', 'R. K. Sharma (QA/QC Lead)', '2026-09-18', 'INSPECTED_ACCEPTED'
        ],
        [
          'TX-GIN-701', 'PRJ-OIL-2026', 'GIN', 'GIN-2026-701', 'MAT-PIPE-12X65',
          '12" API 5L Gr. X65 PSL2 Line Pipe Spools issued to Field Trenching Gang Ch. 12+800',
          120, 'meters (10 spools)', 'Zone B Stores', 'Corridor Chainage 12+800',
          'PIP-L5-024', 'R. K. Sharma (Lead Piping Inspector)', '2026-09-20', 'DISPATCHED'
        ],
        [
          'TX-GRN-502', 'PRJ-OIL-2026', 'GRN', 'GRN-2026-502', 'MAT-BEND-90-5D-X65',
          '12" NB 90-Degree Induction Bend Spools, 5D Bend Radius, API 5L Gr. X65 PSL2, 14.3mm WT',
          12, 'spool units', 'Tubacex Prakash India Ltd', 'Duliajan Heavy Fittings Yard',
          'PIP-L5-024', 'R. K. Sharma (QA/QC Lead)', '2026-09-19', 'INSPECTED_ACCEPTED'
        ],
        [
          'TX-GIN-702', 'PRJ-OIL-2026', 'GIN', 'GIN-2026-702', 'MAT-BEND-90-5D-X65',
          '12" 90-Deg 5D Induction Bends issued for Dihing River Viaduct Crossing Riser Tie-ins',
          4, 'spool units', 'Heavy Fittings Yard', 'Pier 24 East Bank Tie-in',
          'PIP-L5-024', 'Vikram Joshi (Site Supervisor)', '2026-09-22', 'DISPATCHED'
        ],
        [
          'TX-GRN-503', 'PRJ-OIL-2026', 'GRN', 'GRN-2026-503', 'MAT-FLG-WN-600-12',
          '12" Class 600 Weld Neck Flange Sets (ASTM A694 Gr. F65 with RTJ Octagonal Gaskets & B7/2H Studs)',
          24, 'flange sets', 'MSL Heavy Forgings Pune', 'Zone B Precision Stores',
          'MEC-L5-031', 'Prasanta Hazarika (Senior Tech)', '2026-09-20', 'INSPECTED_ACCEPTED'
        ],
        [
          'TX-GIN-703', 'PRJ-OIL-2026', 'GIN', 'GIN-2026-703', 'MAT-FLG-WN-600-12',
          '12" Class 600 RTJ Flange Pairs with Octagonal Soft Iron Gaskets for SBV-04 Tie-in',
          6, 'flange sets', 'Zone B Precision Stores', 'Sectional Valve Station SV-04',
          'MEC-L5-031', 'Sunil Karmakar (Senior Fitter)', '2026-09-24', 'DISPATCHED'
        ],
        [
          'TX-GRN-504', 'PRJ-OIL-2026', 'GRN', 'GRN-2026-504', 'MAT-TEE-12X8-X65',
          '12" x 8" Reducing Tees (Seamless Forged, ASTM A860 WPHY-65 / ASME B16.9)',
          6, 'units', 'L&T Heavy Engineering, Hazira', 'Duliajan Warehouse Bay 2',
          'PIP-L5-024', 'Materials Controller', '2026-09-21', 'INSPECTED_ACCEPTED'
        ],
        [
          'TX-GRN-505', 'PRJ-OIL-2026', 'GRN', 'GRN-2026-505', 'MAT-SLEEVE-GTS-PP',
          'Canusa-CPS GTS-PP 12" 3-Layer Heat Shrinkable Field Joint Sleeves with Epoxy Primer Kit',
          150, 'sleeves', 'Shawcor Pipeline Products India', 'Chemicals & Coating Storage',
          'PIP-L5-025', 'Mukul Barman (Coating Inspector)', '2026-09-21', 'INSPECTED_ACCEPTED'
        ],
        [
          'TX-GIN-704', 'PRJ-OIL-2026', 'GIN', 'GIN-2026-704', 'MAT-SLEEVE-GTS-PP',
          '3-Layer Heat Shrink Sleeves issued for Welded Field Joints #W24-01 through #W24-30',
          30, 'sleeves', 'Coating Storage', 'Trench Station J-12',
          'PIP-L5-025', 'Mukul Barman (Coating Inspector)', '2026-09-25', 'DISPATCHED'
        ],
        [
          'TX-GRN-506', 'PRJ-OIL-2026', 'GRN', 'GRN-2026-506', 'MAT-ELEC-E7018G',
          'Low Hydrogen Welding Electrodes AWS A5.5 E7018-G / E8018-G (4.0mm vacuum hermetic tins)',
          800, 'kg', 'ESAB India Ltd', 'Welding Consumables Oven Room',
          'PIP-L5-024', 'Tapan Das (Lead Welder)', '2026-09-17', 'INSPECTED_ACCEPTED'
        ],
        [
          'TX-GIN-705', 'PRJ-OIL-2026', 'GIN', 'GIN-2026-705', 'MAT-ELEC-E7018G',
          'Bake-tested E7018-G Low Hydrogen Electrodes issued in heated portable quivers',
          180, 'kg', 'Consumables Room', 'Automatic Orbital Welding Station 02',
          'PIP-L5-024', 'Tapan Das (Lead Welder)', '2026-09-26', 'DISPATCHED'
        ],
        [
          'TX-GRN-507', 'PRJ-OIL-2026', 'GRN', 'GRN-2026-507', 'MAT-ANODE-MMO-TI',
          'Mixed Metal Oxide (MMO) Tubular Titanium Anodes (Canisterized with Petroleum Coke Breeze)',
          18, 'canisters', 'Corrpro Pipeline Technologies India', 'Electrical Yard Shed 3',
          'ELC-L5-042', 'Manoj Sonowal (CP Specialist)', '2026-09-22', 'INSPECTED_ACCEPTED'
        ],
        [
          'TX-GRN-508', 'PRJ-OIL-2026', 'GRN', 'GRN-2026-508', 'MAT-VALV-BALL-12-600',
          '12" Class 600 Trunnion Mounted Full Bore Ball Valve, ASME B16.34 with Rotork Gas-over-Oil Actuator',
          2, 'actuated valve units', 'Cameron Schlumberger India', 'Controlled Temperature Warehouse',
          'MEC-L5-031', 'Prasanta Hazarika (Mechanical Tech)', '2026-09-23', 'INSPECTED_ACCEPTED'
        ],
        [
          'TX-GIN-706', 'PRJ-OIL-2026', 'GIN', 'GIN-2026-706', 'MAT-VALV-BALL-12-600',
          '12" Cl 600 Trunnion Ball Valve Tag #ESDV-04 issued for Sectional Valve Station SV-04',
          1, 'actuated valve units', 'Controlled Warehouse', 'Sectional Valve Station SV-04',
          'MEC-L5-031', 'Prasanta Hazarika (Mechanical Tech)', '2026-09-27', 'DISPATCHED'
        ],
        [
          'TX-GRN-509', 'PRJ-OIL-2026', 'GRN', 'GRN-2026-509', 'MAT-ROCK-SHIELD-HDPE',
          'Heavy Duty High-Density Polyethylene (HDPE) Rock Shield Pipeline Protection Mesh (4.5mm)',
          1500, 'sq.m', 'Polycoat Geosynthetics Ltd', 'Open Storage Bay 4',
          'PIP-L5-027', 'Vikram Joshi (Field Operations)', '2026-09-24', 'INSPECTED_ACCEPTED'
        ]
      ];
  
      for (const m of materials) {
        insertMat.run(...m);
      }
  
      // 7. Insert 5 FIDIC Conflict Records with Real Contractual Clause References
      const insertConf = this.db.prepare(`
        INSERT INTO conflicts (
          id, project_id, activity_code, activity_name, type, severity, title, description,
          variance_value, claimed_value, verified_value, spec_or_clause, timestamp, action_required, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `);
  
      const conflicts = [
        [
          'CONF-01', 'PRJ-OIL-2026', 'PIP-L5-024', 'Pipe Stringing & Automatic Orbital Welding',
          'PROGRESS_VARIANCE', 'CRITICAL',
          'Contractor Claim (82.0%) vs Drone LiDAR Point Cloud (68.2%) Variance (+13.8%)',
          'Contractor interim IPC submittal #14 claimed 82.0% welding and lower-in progress. Drone LiDAR mission FL-094 and 3D point cloud surface reconstruction measured 68.2% placed linear meters. Variance of +13.8% severely exceeds the ±5.0% contractual tolerance limit.',
          '+13.8% over LiDAR', '82.0% Claimed', '68.2% LiDAR',
          'FIDIC Red Book Cl. 14.3 (Application for Interim Payment Certificates) & Cl. 8.4 (Extension of Time)',
          '2 hours ago',
          'Conduct mandatory joint field reconciliation walk with Engineer\'s Representative, QS surveyor, and Contractor Project Manager.',
          'OPEN'
        ],
        [
          'CONF-02', 'PRJ-OIL-2026', 'ACT-3088', 'Segment B-14 Post-Tensioned Pier Cap',
          'SILENT_RISK', 'HIGH',
          'Silent Structural Integrity Risk: Tendon Stressing Claimed Prior to 28-Day Concrete Cube Break Validation',
          'Contractor reported 92.0% completion on Pier Cap 24 and prepared to apply hydraulic prestressing loads. However, NABL QA/QC Materials Lab compressive strength certificate for concrete batch LB-2024-881 (28-day break) remains unreleased (only 7-day 32 MPa break on file; 45 MPa required). Post-tensioning without validated 28-day certificate risks catastrophic shear fracture.',
          '-4 Days Critical Path Deficit', 'Pour Complete & Stressing Initiated (92.0%)', 'Lab Batch LB-2024-881 28-day Break Pending in QA Lab',
          'FIDIC Red Book Cl. 7.3 (Inspection & Testing) & Cl. 7.4 (Testing by Contractor) / ASTM C39',
          '5 hours ago',
          'Lock out hydraulic tensioning pump and withhold release until signed 28-day NABL compressive break test certificate is delivered.',
          'INVESTIGATING'
        ],
        [
          'CONF-03', 'PRJ-OIL-2026', 'PIP-L6-026', 'NDT Inspection — 100% Radiography & PAUT',
          'TEST_PENDING', 'HIGH',
          'NDT Backfill Non-Conformance: 34 Welds Buried Prior to Radiographic Interpretation Sign-off',
          'Contractor advanced trench lower-in and backfilling across 180 meters prior to Engineer sign-off on 100% radiographic testing (RT) films for joints #W24-12 through #W24-46. Duliajan monsoonal storms caused subcontractor film processing delays. Burying uninspected welds violates OISD-141 pipeline safety code.',
          '34 Weld Joints Uncertified', '100% Welded & Backfilled', '64% NDT Certified',
          'FIDIC Red Book Cl. 7.5 (Rejection) & Cl. 7.6 (Remedial Work) / API 1104 Sec. 11',
          '1 day ago',
          'Contractor instructed under Cl. 7.6 to uncover 6 randomly selected weld joints for ultrasonic phased-array verification at contractor\'s cost.',
          'OPEN'
        ],
        [
          'CONF-04', 'PRJ-OIL-2026', 'PIP-L5-024', 'Pipe Stringing & Automatic Orbital Welding',
          'MATERIAL_SHORTAGE', 'MEDIUM',
          'Supply Chain Bottleneck: Shortage of Heavy-Wall 12" X65 5D Induction Bends for Ch. 13+650 Crossing',
          'Topographical crossing at Ch. 13+650 requires 12 units of 12" NB 5D heavy wall induction bends. Duliajan stores ledger (GRN-2026-502) holds only 6 verified units; remainder 6 units are held at vendor Hazira works awaiting EN 10204 3.1 chemical test certs. Critical path delay imminent in 6 calendar days.',
          '6 Bends Deficit (50% stock shortage)', '12 Units Requisitioned', '6 Units in Store Yard',
          'FIDIC Red Book Cl. 8.5 (Delays Caused by Authorities / Supply Chain) & Cl. 4.12 (Unforeseeable Physical Conditions)',
          '1 day ago',
          'Issue air freight expediting order for remaining 6 spools; adjust lower-in sequence toward Section 3.',
          'OPEN'
        ],
        [
          'CONF-05', 'PRJ-OIL-2026', 'ELC-L5-042', 'Impressed Current Cathodic Protection',
          'OUT_OF_SEQUENCE', 'MEDIUM',
          'Out-of-Sequence Construction: Deep Anode Bed Energization Preceding Trench Backfill Settlement',
          'Electrical subcontractor energized 50A transformer rectifier unit at ICCP Groundbed Station 2 while mechanical trench compaction and settlement monitoring between Ch. 14+100 and 14+400 remains incomplete. High ground potential gradient creates safety hazard for trench labourers.',
          'Sequence Conflict (Float -2 days)', 'ICCP Commissioning (38%)', 'Trench Settlement Incomplete',
          'FIDIC Red Book Cl. 4.6 (Co-operation between Subcontractors) & Cl. 6.7 (Health and Safety)',
          '2 days ago',
          'Enforce Lockout/Tagout (LOTO) on rectifier unit until civil supervisor signs trench compaction clearance.',
          'RESOLVED'
        ]
      ];
  
      for (const c of conflicts) {
        insertConf.run(...c);
      }
  
      // 8. Insert 16 Tamper-Proof Cryptographic SHA-256 Audit Trail Entries
      const insertAudit = this.db.prepare(`
        INSERT INTO audit_logs (
          id, project_id, timestamp, actor_name, actor_role, action,
          entity_type, entity_id, previous_value, new_value, reason, ip_or_device, sha256_hash
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `);
  
      const rawAuditLogs = [
        {
          id: 'AUD-1001',
          timestamp: '2026-09-15 08:00:00 IST',
          actorName: 'Marcus Vance, P.E.',
          actorRole: "Engineer's Representative (FIDIC 3.1)",
          action: 'PROJECT_BASELINE_FROZEN',
          entityType: 'ACTIVITY',
          entityId: 'PRJ-OIL-2026',
          previousValue: 'REVISION_0.9_DRAFT',
          newValue: 'BASELINE_REV_1.0_FROZEN',
          reason: 'Official baseline schedule and WBS frozen in Primavera P6 format for Trunk Pipeline Package II',
        },
        {
          id: 'AUD-1002',
          timestamp: '2026-09-16 07:15:22 IST',
          actorName: 'Gate Controller & HR',
          actorRole: 'Access Gateway Security',
          action: 'WORKFORCE_GEOFENCE_ENROLLED',
          entityType: 'ATTENDANCE',
          entityId: 'LAB-IND-0442',
          previousValue: 'UNENROLLED',
          newValue: 'Tapan Das (WELDER) - Geofence 27.4828° N, 95.3221° E',
          reason: 'Biometric credentials and 6G welding qualification card validated at Duliajan Gate 1',
        },
        {
          id: 'AUD-1003',
          timestamp: '2026-09-18 11:30:10 IST',
          actorName: 'R. K. Sharma',
          actorRole: 'Lead QA/QC Materials Inspector',
          action: 'MATERIAL_GRN_POSTED',
          entityType: 'MATERIAL',
          entityId: 'GRN-2026-501',
          previousValue: 'PENDING_INSPECTION',
          newValue: '240 meters API 5L X65 3LPE Pipe Accepted',
          reason: 'Mill test certificates verified against API 5L PSL2 criteria. Positive material identification (PMI) verified.',
        },
        {
          id: 'AUD-1004',
          timestamp: '2026-09-20 08:45:00 IST',
          actorName: 'Warehouse Controller',
          actorRole: 'Zone B Stores Supervisor',
          action: 'MATERIAL_GIN_DISPATCHED',
          entityType: 'MATERIAL',
          entityId: 'GIN-2026-701',
          previousValue: 'ALLOCATED',
          newValue: '120 meters API 5L X65 Spools Dispatched',
          reason: 'Issued to Stringing & Welding Crew for Chainage 12+800 corridor lower-in',
        },
        {
          id: 'AUD-1005',
          timestamp: '2026-09-22 07:30:00 IST',
          actorName: 'Tapan Das',
          actorRole: 'Lead 6G Welder',
          action: 'ATTENDANCE_CLOCK_IN_VERIFIED',
          entityType: 'ATTENDANCE',
          entityId: 'LAB-IND-0442',
          previousValue: 'ABSENT',
          newValue: 'VERIFIED_PRESENT (98.5%)',
          reason: 'GPS Geofence + Biometric timestamped at 07:30 AM IST (Duliajan Gate 1: 27.4828° N, 95.3221° E)',
        },
        {
          id: 'AUD-1006',
          timestamp: '2026-09-24 10:45:30 IST',
          actorName: 'Vikram Joshi',
          actorRole: 'Site Piping Supervisor',
          action: 'VOICE_UPDATE_LINKED',
          entityType: 'ACTIVITY',
          entityId: 'PIP-L5-024',
          previousValue: '68.0%',
          newValue: '72.4% (Consensus Adjusted)',
          reason: 'Voice note parsed in Hindi & linked: 45m pipe welded at Ch. 13+100; joint numbers #W24-01 to #W24-06 logged',
        },
        {
          id: 'AUD-1007',
          timestamp: '2026-09-25 14:10:15 IST',
          actorName: 'Drone Survey Pilot',
          actorRole: 'Geospatial Mapping Unit',
          action: 'LIDAR_POINT_CLOUD_INGESTED',
          entityType: 'EVIDENCE',
          entityId: 'PIP-L5-024',
          previousValue: 'LIDAR_FL-093',
          newValue: 'LIDAR_FL-094 (3D Point Cloud Volume: 286.4m)',
          reason: 'Autonomous aerial LiDAR scan processed with centimeter RTK accuracy over corridor Section 2',
        },
        {
          id: 'AUD-1008',
          timestamp: '2026-09-26 15:30:00 IST',
          actorName: 'Triangulation Engine',
          actorRole: 'Automated Truth Reconciler',
          action: 'CONSENSUS_RECALCULATED',
          entityType: 'PROGRESS',
          entityId: 'PIP-L5-024',
          previousValue: 'Consensus 69.8%',
          newValue: 'Consensus 71.4% (Confidence 94.2%)',
          reason: 'Weighted triangulation: LiDAR 68.2% (30%) + QS 74.5% (35%) + QC 68.0% (35%)',
        },
        {
          id: 'AUD-1009',
          timestamp: '2026-09-27 09:15:20 IST',
          actorName: 'Marcus Vance, P.E.',
          actorRole: "Engineer's Representative (FIDIC 3.1)",
          action: 'CONFLICT_FLAGGED_FIDIC',
          entityType: 'CONFLICT',
          entityId: 'CONF-01',
          previousValue: 'NONE',
          newValue: 'CRITICAL Progress Variance (+13.8%) under FIDIC Cl. 14.3',
          reason: 'Contractor monthly IPC claim of 82.0% exceeds LiDAR verified progress of 68.2% beyond ±5% tolerance',
        },
        {
          id: 'AUD-1010',
          timestamp: '2026-09-27 16:45:00 IST',
          actorName: 'R. K. Sharma',
          actorRole: 'Site Piping Supervisor',
          action: 'DPR_SUBMITTED',
          entityType: 'DPR',
          entityId: 'PIP-L5-024',
          previousValue: '280 meters',
          newValue: '+24 meters (304 meters total)',
          reason: 'DPR logged: 24m installed. 2 welds delayed pending RT radiography interpretation',
        },
        {
          id: 'AUD-1011',
          timestamp: '2026-09-28 08:30:10 IST',
          actorName: 'QA/QC Surveillance Engine',
          actorRole: 'Automated Quality Guard',
          action: 'SILENT_RISK_DETECTED',
          entityType: 'CONFLICT',
          entityId: 'CONF-02',
          previousValue: 'NORMAL',
          newValue: 'HIGH Silent Risk: Concrete Cube 28-day break pending',
          reason: 'Structural tendon jacking requested on Pier 24 before NABL compressive break test certificate validation',
        },
        {
          id: 'AUD-1012',
          timestamp: '2026-09-28 11:20:45 IST',
          actorName: 'Deepankar Saikia',
          actorRole: 'NDT Level-II Specialist',
          action: 'NDT_NONCONFORMANCE_RAISED',
          entityType: 'CONFLICT',
          entityId: 'CONF-03',
          previousValue: 'PENDING_REVIEW',
          newValue: 'OPEN (FIDIC Cl. 7.5 / 7.6 Notice Issued)',
          reason: '34 field weld joints lower-in and backfilled without certified RT radiography interpretation',
        },
        {
          id: 'AUD-1013',
          timestamp: '2026-09-28 14:00:00 IST',
          actorName: 'Materials Controller',
          actorRole: 'Procurement Liaison',
          action: 'MATERIAL_SHORTAGE_ESCALATED',
          entityType: 'MATERIAL',
          entityId: 'CONF-04',
          previousValue: 'IN_TRANSIT',
          newValue: 'CRITICAL BOTTLENECK (6 Heavy Wall Bends Short)',
          reason: 'Shortage of 12" X65 5D induction bend spools risks stalling Dihing River crossing tie-in in 6 days',
        },
        {
          id: 'AUD-1014',
          timestamp: '2026-09-29 09:10:00 IST',
          actorName: 'Subhash Roy',
          actorRole: 'Safety & HSE Officer',
          action: 'SAFETY_LOTO_ENFORCED',
          entityType: 'ATTENDANCE',
          entityId: 'CONF-05',
          previousValue: 'ENERGIZED',
          newValue: 'LOCKOUT_TAGOUT_ENFORCED',
          reason: 'ICCP rectifier unit locked out to protect trenching excavation crew from ground potential gradient',
        },
        {
          id: 'AUD-1015',
          timestamp: '2026-09-29 15:40:12 IST',
          actorName: 'Marcus Vance, P.E.',
          actorRole: "Engineer's Representative (FIDIC 3.1)",
          action: 'CONFLICT_RESOLVED_ENGINEER',
          entityType: 'CONFLICT',
          entityId: 'CONF-05',
          previousValue: 'OPEN',
          newValue: 'RESOLVED',
          reason: 'Civil supervisor completed and signed off trench backfill compaction; LOTO cleared for ICCP test posts',
        },
        {
          id: 'AUD-1016',
          timestamp: '2026-09-30 08:00:00 IST',
          actorName: 'Marcus Vance, P.E.',
          actorRole: "Engineer's Representative (FIDIC 3.1)",
          action: 'JOINT_RECONCILIATION_NOTICE',
          entityType: 'EVIDENCE',
          entityId: 'PIP-L5-024',
          previousValue: 'DISPUTED',
          newValue: 'JOINT_WALK_SCHEDULED',
          reason: 'Formal notice issued under FIDIC Cl. 14.3 for tripartite site walk with QS & Drone Survey lead on Ch. 12+400',
        },
      ];
  
      let prevHash = '0000000000000000000000000000000000000000000000000000000000000000';
      for (const log of rawAuditLogs) {
        const payload = `${log.id}|PRJ-OIL-2026|${log.timestamp}|${log.actorName}|${log.actorRole}|${log.action}|${log.entityType}|${log.entityId}|${log.previousValue}|${log.newValue}|${log.reason}|${prevHash}`;
        const hash = crypto.createHash('sha256').update(payload).digest('hex');
        const ipOrDevice = `ApexBuild Node-01 (SHA-256: ${hash.substring(0, 16)}...)`;
        insertAudit.run(
          log.id,
          'PRJ-OIL-2026',
          log.timestamp,
          log.actorName,
          log.actorRole,
          log.action,
          log.entityType,
          log.entityId,
          log.previousValue,
          log.newValue,
          log.reason,
          ipOrDevice,
          hash
        );
        prevHash = hash;
      }
  
      // 9. Insert Informal Site Updates (Voice Hindi & WhatsApp Notes)
      this.db.prepare(`
        INSERT INTO informal_site_updates (
          id, project_id, source, raw_input, timestamp, reported_by, supervisor_role,
          location_geofence, extracted_entities, matched_activity_code, linking_confidence,
          is_out_of_sequence, linking_status
        ) VALUES 
        (
          'UPD-101', 'PRJ-OIL-2026', 'VOICE_HINDI',
          'Line 24 ka pipe installation start ho gaya hai, 45 meter welding complete hai, lekin material delay ki wajah se do joints pending hain.',
          'Today, 10:45 AM IST', 'Vikram Joshi (Site Supervisor)', 'Site Piping Supervisor',
          'Chainage 14+450 (Within 15m radius: 27.4828° N, 95.3221° E)',
          '{"discipline":"PIPING","lineOrTag":"Line 24","action":"pipe installation & welding","quantity":45,"unit":"meters","progressPercentage":68,"delayReason":"Missing 12\\" forged elbow spools from warehouse"}',
          'PIP-L5-024', 0.98, 0, 'CONFIRMED'
        ),
        (
          'UPD-102', 'PRJ-OIL-2026', 'WHATSAPP',
          'Pier 24 cap shuttering open kar di hai. Rebar clear hai. Pre-pour QA checklist signed by client rep.',
          'Today, 08:30 AM IST', 'K. N. Saikia (Civil Supervisor)', 'Civil Site Engineer',
          'Pier 24 Dihing Viaduct (27.4831° N, 95.3218° E)',
          '{"discipline":"CIVIL","lineOrTag":"Pier 24","action":"shuttering & rebar inspection","progressPercentage":85}',
          'ACT-3088', 0.94, 0, 'CONFIRMED'
        )
      `).run();
  
      // 10. Equipment Fleet (24 Heavy Industrial Machines)
      this.seedDefaultEquipment('PRJ-OIL-2026');
      return { success: true };
    });
  }
}

export const realDb = new RealDatabase();
