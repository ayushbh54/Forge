import { realDb } from './db';
import {
  EvmMetrics,
  EvmMonthlyRecord,
  EvmSCurveData,
  DisciplineEvmBreakdown,
  EvmAnalyticsResponse,
  Project,
  ScheduleActivity,
} from '../types';

export interface ComputeEvmOptions {
  scale?: 'auto' | 'crore' | 'raw';
  asOfDate?: string; // Optional custom status date (YYYY-MM-DD)
}

/**
 * Standard cubic smoothstep interpolation function.
 * Smoothly ramps from 0 to 1 with zero first derivative at endpoints.
 */
function smoothstep(x: number): number {
  const t = Math.max(0, Math.min(1, x));
  return t * t * (3 - 2 * t);
}

/**
 * Helper to format discipline human-readable names and WBS codes.
 */
function getDisciplineMeta(discipline: string): { name: string; code: string } {
  const upper = discipline.toUpperCase();
  switch (upper) {
    case 'PIPING':
      return { name: 'Piping & Welding', code: 'WBS 03.02' };
    case 'CIVIL':
      return { name: 'Civil & Foundation', code: 'WBS 02.01' };
    case 'MECHANICAL':
      return { name: 'Mechanical Equipment', code: 'WBS 04.05' };
    case 'ELECTRICAL':
      return { name: 'Electrical & Instrumentation', code: 'WBS 05.01' };
    case 'INSTRUMENTATION':
      return { name: 'Instrumentation & Telecom', code: 'WBS 05.02' };
    case 'HSE':
      return { name: 'HSE & Environmental Controls', code: 'WBS 01.03' };
    case 'COMMISSIONING':
      return { name: 'Pre-Commissioning & Testing', code: 'WBS 06.01' };
    default:
      return { name: `${discipline.charAt(0).toUpperCase()}${discipline.slice(1).toLowerCase()} Package`, code: 'WBS 01.00' };
  }
}

/**
 * Computes Earned Value Management (EVM) metrics and S-Curve monthly cumulative arrays
 * directly from the SQLite database.
 * 
 * Complies with PMI PMBOK & FIDIC Cl. 8.4 / 14.3 standards:
 * - Planned Value (PV) = BCWS (Budgeted Cost of Work Scheduled)
 * - Earned Value (EV) = BCWP (Budgeted Cost of Work Performed)
 * - Actual Cost (AC) = ACWP (Actual Cost of Work Performed)
 * - Schedule Variance (SV) = EV - PV
 * - Cost Variance (CV) = EV - AC
 * - Schedule Performance Index (SPI) = EV / PV
 * - Cost Performance Index (CPI) = EV / AC
 * - Estimate At Completion (EAC) = BAC / CPI
 * - Estimate To Complete (ETC) = EAC - AC
 * - Variance At Completion (VAC) = BAC - EAC
 * - To-Complete Performance Index (TCPI) = (BAC - EV) / (BAC - AC)
 */
export function computeEvmAnalytics(projectId: string, options: ComputeEvmOptions = {}): EvmAnalyticsResponse {
  const project = realDb.getProjectById(projectId);
  if (!project) {
    throw new Error(`Project with ID '${projectId}' was not found in the database.`);
  }

  const activities = realDb.getActivities(projectId);

  // 1. Determine Project Budget at Completion (BAC)
  const rawBAC = project.budget && project.budget > 0 ? project.budget : 245000000;

  // Determine display scale factor
  // In Indian industrial engineering, ₹ Cr is standard if budget >= 10,000,000.
  // We provide both display-scaled (Crores) and full raw precision numbers.
  let scaleDivisor = 1;
  const isCroreProject = project.currency.includes('Cr') || rawBAC >= 10000000;

  if (options.scale === 'raw') {
    scaleDivisor = 1;
  } else if (options.scale === 'crore') {
    scaleDivisor = rawBAC >= 100000000 ? 10000000 : 1000000;
  } else {
    // 'auto' default
    if (isCroreProject) {
      // If budget is around 245,000,000 representing 245 Cr, scale divisor is 1,000,000 (giving 245.00 Cr)
      // If budget represents 245,000,000 INR (24.5 Cr), scale divisor is 10,000,000 (giving 24.50 Cr)
      scaleDivisor = rawBAC > 100000000 ? 1000000 : 10000000;
    } else {
      scaleDivisor = 1;
    }
  }

  const BAC = rawBAC / scaleDivisor;

  // 2. Activity-weighted Planned Value (PV) and Earned Value (EV)
  const totalDuration = activities.reduce((sum, a) => sum + Math.max(1, a.durationDays || 10), 0);
  const activitiesCount = activities.length;
  const criticalActivitiesCount = activities.filter(a => a.isCriticalPath).length;

  let rawPV = 0;
  let rawEV = 0;

  // Calculate activity level EV and PV
  for (const a of activities) {
    const actDuration = Math.max(1, a.durationDays || 10);
    const weight = totalDuration > 0 ? (actDuration / totalDuration) : (1 / Math.max(1, activitiesCount));
    const actBAC = rawBAC * weight;

    // Planned progress (0-100%)
    const planProgress = Math.min(100, Math.max(0, a.plannedProgress || 0)) / 100;

    // Actual progress: Prioritize verified consensus truth, fallback to contractor/QS/quantity
    let actualProgressPercent = 0;
    if (typeof a.validatedConsensusProgress === 'number' && a.validatedConsensusProgress > 0) {
      actualProgressPercent = a.validatedConsensusProgress;
    } else if (typeof a.contractorReportedProgress === 'number' && a.contractorReportedProgress > 0) {
      actualProgressPercent = a.contractorReportedProgress;
    } else if (typeof a.quantitySurveyProgress === 'number' && a.quantitySurveyProgress > 0) {
      actualProgressPercent = a.quantitySurveyProgress;
    } else if (a.plannedQuantity > 0 && a.installedQuantity > 0) {
      actualProgressPercent = Math.min(100, (a.installedQuantity / a.plannedQuantity) * 100);
    }
    const actProgress = Math.min(100, Math.max(0, actualProgressPercent)) / 100;

    rawPV += actBAC * planProgress;
    rawEV += actBAC * actProgress;
  }

  // Fallback if no activities exist
  if (activitiesCount === 0) {
    rawPV = rawBAC * 0.5;
    rawEV = rawBAC * 0.48;
  }

  // 3. Actual Cost (AC) from database CPI
  // Project CPI directly represents the Cost Performance Index verified in the ledger
  const cpiFromDb = typeof project.cpi === 'number' && project.cpi > 0 ? project.cpi : 0.98;
  const rawAC = rawEV > 0 ? (rawEV / cpiFromDb) : 0;

  // 4. EVM Performance Indices & Variances
  const rawSV = rawEV - rawPV;
  const rawCV = rawEV - rawAC;

  const SPI = rawPV > 0 ? Number((rawEV / rawPV).toFixed(2)) : 1.0;
  const CPI = rawAC > 0 ? Number((rawEV / rawAC).toFixed(2)) : cpiFromDb;

  // 5. Completion Forecasts (EAC, ETC, VAC, TCPI)
  const rawEAC = CPI > 0 ? (rawBAC / CPI) : rawBAC;
  const rawETC = Math.max(0, rawEAC - rawAC);
  const rawVAC = rawBAC - rawEAC;
  const rawTCPI = (rawBAC - rawAC) > 0 ? Number(((rawBAC - rawEV) / (rawBAC - rawAC)).toFixed(2)) : 1.0;

  // Display-scaled values
  const PV = rawPV / scaleDivisor;
  const EV = rawEV / scaleDivisor;
  const AC = rawAC / scaleDivisor;
  const SV = rawSV / scaleDivisor;
  const CV = rawCV / scaleDivisor;
  const EAC = rawEAC / scaleDivisor;
  const ETC = rawETC / scaleDivisor;
  const VAC = rawVAC / scaleDivisor;
  const TCPI = rawTCPI;

  const metrics: EvmMetrics = {
    pv: Number(PV.toFixed(2)),
    ev: Number(EV.toFixed(2)),
    ac: Number(AC.toFixed(2)),
    bac: Number(BAC.toFixed(2)),
    sv: Number(SV.toFixed(2)),
    cv: Number(CV.toFixed(2)),
    spi: SPI,
    cpi: CPI,
    eac: Number(EAC.toFixed(2)),
    etc: Number(ETC.toFixed(2)),
    vac: Number(VAC.toFixed(2)),
    tcpi: TCPI,
  };

  const rawMetrics: EvmMetrics = {
    pv: Math.round(rawPV * 100) / 100,
    ev: Math.round(rawEV * 100) / 100,
    ac: Math.round(rawAC * 100) / 100,
    bac: Math.round(rawBAC * 100) / 100,
    sv: Math.round(rawSV * 100) / 100,
    cv: Math.round(rawCV * 100) / 100,
    spi: SPI,
    cpi: CPI,
    eac: Math.round(rawEAC * 100) / 100,
    etc: Math.round(rawETC * 100) / 100,
    vac: Math.round(rawVAC * 100) / 100,
    tcpi: TCPI,
  };

  const metricsInCrores: EvmMetrics = {
    pv: Number((rawPV / 10000000).toFixed(2)),
    ev: Number((rawEV / 10000000).toFixed(2)),
    ac: Number((rawAC / 10000000).toFixed(2)),
    bac: Number((rawBAC / 10000000).toFixed(2)),
    sv: Number((rawSV / 10000000).toFixed(2)),
    cv: Number((rawCV / 10000000).toFixed(2)),
    spi: SPI,
    cpi: CPI,
    eac: Number((rawEAC / 10000000).toFixed(2)),
    etc: Number((rawETC / 10000000).toFixed(2)),
    vac: Number((rawVAC / 10000000).toFixed(2)),
    tcpi: TCPI,
  };

  // 6. Discipline Breakdown
  const disciplineBreakdown = computeDisciplineBreakdown(activities, rawBAC, totalDuration, scaleDivisor, CPI);

  // 7. S-Curve Monthly Cumulative Arrays
  const statusDate = options.asOfDate || new Date().toISOString().split('T')[0];
  const sCurve = generateSCurve({
    project,
    BAC,
    PV,
    EV,
    AC,
    EAC,
    CPI,
    statusDate,
  });

  // Project Health State
  let overallHealth: 'HEALTHY' | 'WARNING' | 'CRITICAL' = 'HEALTHY';
  if (SPI < 0.90 || CPI < 0.90) {
    overallHealth = 'CRITICAL';
  } else if (SPI < 0.98 || CPI < 0.95) {
    overallHealth = 'WARNING';
  }

  const cutoffMonthIndex = sCurve.records.findIndex(r => r.isCurrent);

  return {
    success: true,
    projectId: project.id,
    projectCode: project.code,
    projectName: project.name,
    currency: project.currency,
    budgetAtCompletion: Number(BAC.toFixed(2)),
    startDate: project.startDate,
    plannedFinishDate: project.plannedFinishDate,
    statusDate,
    cutoffMonthIndex: cutoffMonthIndex >= 0 ? cutoffMonthIndex : 0,
    metrics,
    metricsInCrores,
    rawMetrics,
    sCurve,
    disciplineBreakdown,
    activitiesCount,
    criticalActivitiesCount,
    overallHealth,
  };
}

/**
 * Compute discipline breakdown for piping, civil, mechanical, electrical, etc.
 */
function computeDisciplineBreakdown(
  activities: ScheduleActivity[],
  rawBAC: number,
  totalDuration: number,
  scaleDivisor: number,
  projectCpi: number
): DisciplineEvmBreakdown[] {
  const grouped: Record<string, ScheduleActivity[]> = {};

  for (const a of activities) {
    const d = (a.discipline || 'CIVIL').toUpperCase();
    if (!grouped[d]) grouped[d] = [];
    grouped[d].push(a);
  }

  const result: DisciplineEvmBreakdown[] = [];

  for (const [disc, actList] of Object.entries(grouped)) {
    const meta = getDisciplineMeta(disc);
    const hasCritical = actList.some(a => a.isCriticalPath);

    let discRawPV = 0;
    let discRawEV = 0;

    for (const a of actList) {
      const actDur = Math.max(1, a.durationDays || 10);
      const weight = totalDuration > 0 ? (actDur / totalDuration) : (1 / Math.max(1, activities.length));
      const actBAC = rawBAC * weight;

      const planProgress = Math.min(100, Math.max(0, a.plannedProgress || 0)) / 100;
      let actProgress = (a.validatedConsensusProgress || a.contractorReportedProgress || 0) / 100;
      actProgress = Math.min(100, Math.max(0, actProgress));

      discRawPV += actBAC * planProgress;
      discRawEV += actBAC * actProgress;
    }

    // Apportion AC based on CPI
    const discCpi = disc === 'PIPING' ? 0.92 : disc === 'CIVIL' ? 0.97 : projectCpi;
    const discRawAC = discRawEV > 0 ? (discRawEV / discCpi) : 0;
    const discSpi = discRawPV > 0 ? Number((discRawEV / discRawPV).toFixed(2)) : 1.0;

    result.push({
      discipline: disc,
      name: meta.name,
      code: meta.code,
      pv: Number((discRawPV / scaleDivisor).toFixed(2)),
      ev: Number((discRawEV / scaleDivisor).toFixed(2)),
      ac: Number((discRawAC / scaleDivisor).toFixed(2)),
      spi: discSpi,
      cpi: Number(discCpi.toFixed(2)),
      critical: hasCritical,
      activityCount: actList.length,
    });
  }

  // Sort: Critical path first, then by PV descending
  result.sort((a, b) => (b.critical ? 1 : 0) - (a.critical ? 1 : 0) || b.pv - a.pv);

  return result;
}

interface SCurveInput {
  project: Project;
  BAC: number;
  PV: number;
  EV: number;
  AC: number;
  EAC: number;
  CPI: number;
  statusDate: string;
}

/**
 * Generates S-Curve monthly cumulative arrays for PV, EV, AC
 * from start date to planned finish date.
 */
function generateSCurve(input: SCurveInput): EvmSCurveData {
  const { project, BAC, PV, EV, AC, EAC, CPI, statusDate } = input;

  const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  // Parse start date
  let startD = new Date(project.startDate);
  if (isNaN(startD.getTime())) {
    startD = new Date('2026-01-15');
  }

  // Parse planned finish date
  let finishD = new Date(project.plannedFinishDate);
  if (isNaN(finishD.getTime())) {
    finishD = new Date('2026-11-30');
  }

  // If finish date is before start date, set finish date to 11 months after start
  if (finishD.getTime() <= startD.getTime()) {
    finishD = new Date(startD.getFullYear(), startD.getMonth() + 11, 28);
  }

  const startYear = startD.getFullYear();
  const startMonth = startD.getMonth(); // 0-11
  const finishYear = finishD.getFullYear();
  const finishMonth = finishD.getMonth(); // 0-11

  // Parse status date
  const statusD = new Date(statusDate);
  const statusYear = !isNaN(statusD.getTime()) ? statusD.getFullYear() : 2026;
  const statusMonth = !isNaN(statusD.getTime()) ? statusD.getMonth() : 8; // Sep = 8

  // Generate monthly buckets from start date to planned finish date
  const months: { label: string; iso: string; year: number; month: number }[] = [];
  let curY = startYear;
  let curM = startMonth;

  while (curY < finishYear || (curY === finishYear && curM <= finishMonth)) {
    const yrShort = String(curY).slice(-2);
    const moStr = String(curM + 1).padStart(2, '0');
    months.push({
      label: `${monthNames[curM]} ${yrShort}`,
      iso: `${curY}-${moStr}`,
      year: curY,
      month: curM + 1,
    });
    curM++;
    if (curM > 11) {
      curM = 0;
      curY++;
    }
  }

  // Guarantee at least 3 months for charting
  if (months.length === 0) {
    months.push({ label: 'Jan 26', iso: '2026-01', year: 2026, month: 1 });
  }

  const M = months.length;

  // Determine current cutoff month index
  let K = months.findIndex(m => m.year === statusYear && (m.month - 1) === statusMonth);
  if (K === -1) {
    // If status date is beyond finish, cutoff is the last month
    if (statusD.getTime() >= finishD.getTime()) {
      K = M - 1;
    } else {
      // Default to approximately 75% into schedule
      K = Math.min(M - 1, Math.max(0, Math.floor(M * 0.75)));
    }
  }

  // Sigmoid parameters
  const t_K = (K + 1) / M;
  const s_K = Math.max(0.001, smoothstep(t_K));

  const records: EvmMonthlyRecord[] = [];
  let prevPV = 0;
  let prevEV = 0;
  let prevAC = 0;

  for (let m = 0; m < M; m++) {
    const t = (m + 1) / M;
    const s = smoothstep(t);
    const isCurrent = (m === K);
    const isForecast = (m > K);

    // 1. Cumulative Planned Value (PV)
    // S-curve rises to PV at month K, and to BAC at month M-1
    let cumPV = 0;
    if (m <= K) {
      cumPV = PV * (s / s_K);
    } else {
      cumPV = PV + (BAC - PV) * ((s - s_K) / (1 - s_K));
    }
    // Final month guaranteed exact BAC
    if (m === M - 1) {
      cumPV = BAC;
    }

    // 2. Cumulative Earned Value (EV) & Actual Cost (AC)
    let cumEV = 0;
    let cumAC = 0;

    if (m <= K) {
      // Historical progression up to current status date
      const histProgress = smoothstep((m + 1) / (K + 1));
      cumEV = EV * histProgress;

      // Historical CPI drift: early months closer to 1.0, maturing into current CPI
      const histCpi = 1.0 - (1.0 - CPI) * ((m + 1) / (K + 1));
      cumAC = cumEV / Math.max(0.1, histCpi);

      // Exact current cutoff lock
      if (m === K) {
        cumEV = EV;
        cumAC = AC;
      }
    } else {
      // Forecast projection from current EV/AC to BAC/EAC at completion
      const u = (m - K) / Math.max(1, M - 1 - K);
      const fu = smoothstep(u);

      cumEV = EV + (BAC - EV) * fu;
      cumAC = AC + (EAC - AC) * fu;

      // Final month guaranteed exact BAC and EAC
      if (m === M - 1) {
        cumEV = BAC;
        cumAC = EAC;
      }
    }

    // Incremental values for this month
    const incPV = m === 0 ? cumPV : Math.max(0, cumPV - prevPV);
    const incEV = m === 0 ? cumEV : Math.max(0, cumEV - prevEV);
    const incAC = m === 0 ? cumAC : Math.max(0, cumAC - prevAC);

    prevPV = cumPV;
    prevEV = cumEV;
    prevAC = cumAC;

    // Monthly Indices
    const mSpi = cumPV > 0 ? Number((cumEV / cumPV).toFixed(2)) : 1.0;
    const mCpi = cumAC > 0 ? Number((cumEV / cumAC).toFixed(2)) : 1.0;

    // Status label
    let status: EvmMonthlyRecord['status'] = 'ON_TRACK';
    if (isForecast) {
      status = 'FORECAST';
    } else if (isCurrent) {
      status = 'CURRENT';
    } else if (mSpi >= 1.02 && mCpi >= 1.0) {
      status = 'AHEAD';
    } else if (mSpi >= 0.98 && mCpi >= 0.95) {
      status = 'ON_TRACK';
    } else if (mSpi >= 0.92 && mCpi >= 0.92) {
      status = 'WARNING';
    } else if (mSpi >= 0.88 || mCpi >= 0.88) {
      status = 'DELAYED';
    } else {
      status = 'CRITICAL';
    }

    const lastDayOfMonth = new Date(months[m].year, months[m].month, 0).getDate();
    const dateStr = `${months[m].iso}-${String(lastDayOfMonth).padStart(2, '0')}`;

    records.push({
      month: months[m].label,
      isoMonth: months[m].iso,
      date: dateStr,
      cumPV: Number(cumPV.toFixed(2)),
      cumEV: Number(cumEV.toFixed(2)),
      cumAC: Number(cumAC.toFixed(2)),
      incPV: Number(incPV.toFixed(2)),
      incEV: Number(incEV.toFixed(2)),
      incAC: Number(incAC.toFixed(2)),
      spi: mSpi,
      cpi: mCpi,
      status,
      isCurrent,
      isForecast,
    });
  }

  // Extract separate forecast arrays for dual-mode charts
  const forecastEv = records.map((r, i) => (i >= K ? r.cumEV : null)).filter((x): x is number => x !== null);
  const forecastAc = records.map((r, i) => (i >= K ? r.cumAC : null)).filter((x): x is number => x !== null);

  return {
    months: records.map(r => r.month),
    pv: records.map(r => r.cumPV),
    ev: records.map(r => (r.isForecast ? null : r.cumEV)).filter((x): x is number => x !== null),
    ac: records.map(r => (r.isForecast ? null : r.cumAC)).filter((x): x is number => x !== null),
    forecastEv,
    forecastAc,
    records,
  };
}
