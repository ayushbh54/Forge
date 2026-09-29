import { NextResponse } from 'next/server';
import { realDb } from '@/lib/db';
import { SuspendedActivity } from '@/types/index';

// Canonical telemetry for Oil India Duliajan site (27.4825° N, 95.3225° E)
const DULIAJAN_SITE = {
  siteName: 'Oil India Duliajan Site',
  siteCoordinates: '27.4825° N, 95.3225° E',
  latitude: 27.4825,
  longitude: 95.3225,
  defaultTemperature: 32.0,
  defaultRainfallMM: 45.0,
  defaultWindSpeedKmh: 18.0,
  defaultHumidity: 88,
  rainfallThresholdMM: 25.0,
  baselineHistoricalDaysLost: 14,
  baselineAllowedDays: 6,
  contractualClause: 'FIDIC Cl. 8.4(c) (Exceptionally Adverse Climatic Conditions)',
};

// Default canonical suspended activities for Duliajan Monsoon protocol
const CANONICAL_SUSPENDED_ACTIVITIES: SuspendedActivity[] = [
  {
    id: 'ACT-PL-024',
    activityCode: 'PIP-L5-024',
    name: 'Piping Line 24 (Welding & Laying)',
    location: 'Section C-4 / Station 14+200',
    reason: 'Excessive precipitation (>15mm/hr safety cutoff) prevents open-groove SMAW/GTAW welding and joint wrapping integrity.',
    crewSize: 38,
    isCriticalPath: true,
    estimatedSlippage: '1.0 Day',
    mitigationAction: 'Pipe ends sealed with hydrostatic caps; crew redeployed to fabrication bay.',
  },
  {
    id: 'ACT-FD-108',
    activityCode: 'CIV-L5-019',
    name: 'Foundation Pours & Micro-Piles (Compressor Bay Unit 3)',
    location: 'Civil Substation Yard 2 / Station 14+200',
    reason: 'Rainfall exceeds 45mm; severe water-cement ratio compromise, trench flooding, and aggregate saturation risk.',
    crewSize: 24,
    isCriticalPath: true,
    estimatedSlippage: '1.5 Days',
    mitigationAction: 'Batching transit mixers rerouted; pour stop-ends prepared; curing tarps deployed; dewatering pumps activated.',
  },
  {
    id: 'ACT-CR-019',
    activityCode: 'NDT-L6-044',
    name: 'Crane Erection & RT Girth Weld Inspection',
    location: 'Process Plant Area 1 / Open Trench',
    reason: 'Sub-grade soil bearing capacity degraded by torrential rain; lightning hazard protocol active within 15 km.',
    crewSize: 12,
    isCriticalPath: false,
    estimatedSlippage: '0.5 Day',
    mitigationAction: 'Boom lowered to 15° storm cradle; outrigger mats secured; crawler parked in dry bay.',
  },
];

/**
 * GET /api/weather
 * Returns current site weather telemetry for Oil India Duliajan site (27.4825° N, 95.3225° E).
 * Returns: temperature, rainfallMM, windSpeedKmh, humidity, workSuspensionActive (boolean), affectedActivities, historicalSeasonDaysLost.
 */
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const projectId = searchParams.get('projectId') || 'PRJ-OIL-2026';

    // Retrieve any recent weather stoppage event recorded in SQLite
    const latestUpdate = realDb.getLatestWeatherUpdate(projectId);
    const stoppageRecords = realDb.getWeatherStoppages(projectId);

    // Extract dynamic telemetry if an update was posted, else use real site telemetry
    const rainfallMM = latestUpdate?.entities?.rainfallMM !== undefined
      ? Number(latestUpdate.entities.rainfallMM)
      : DULIAJAN_SITE.defaultRainfallMM;

    const temperature = latestUpdate?.entities?.temperature !== undefined
      ? Number(latestUpdate.entities.temperature)
      : DULIAJAN_SITE.defaultTemperature;

    const windSpeedKmh = latestUpdate?.entities?.windSpeedKmh !== undefined
      ? Number(latestUpdate.entities.windSpeedKmh)
      : DULIAJAN_SITE.defaultWindSpeedKmh;

    const humidity = latestUpdate?.entities?.humidity !== undefined
      ? Number(latestUpdate.entities.humidity)
      : DULIAJAN_SITE.defaultHumidity;

    // Work suspension is active if rainfall exceeds safety cutoff (25mm) or explicitly set in update
    const workSuspensionActive = latestUpdate?.entities?.workSuspensionActive !== undefined
      ? Boolean(latestUpdate.entities.workSuspensionActive)
      : rainfallMM >= DULIAJAN_SITE.rainfallThresholdMM;

    // Calculate historical season days lost: base 14 days + any distinct recorded stoppage events
    const historicalSeasonDaysLost = DULIAJAN_SITE.baselineHistoricalDaysLost + stoppageRecords.length;
    const netClaimableEotDays = Math.max(0, historicalSeasonDaysLost - DULIAJAN_SITE.baselineAllowedDays);

    // Correlate affected activities with SQLite schedule activities
    let affectedActivities: SuspendedActivity[] = [];

    if (workSuspensionActive) {
      const dbActivities = realDb.getActivities(projectId);
      const affectedCodes = latestUpdate?.entities?.affectedActivityCodes as string[] | undefined;

      if (dbActivities.length > 0) {
        affectedActivities = CANONICAL_SUSPENDED_ACTIVITIES.map(canonical => {
          const match = dbActivities.find(
            a => a.activityCode.toLowerCase() === canonical.activityCode.toLowerCase() ||
                 a.name.toLowerCase().includes('welding') && canonical.activityCode.includes('PIP')
          );
          if (match) {
            return {
              ...canonical,
              activityCode: match.activityCode,
              name: match.name,
              crewSize: match.workforceCount || canonical.crewSize,
              isCriticalPath: Boolean(match.isCriticalPath),
            };
          }
          return canonical;
        });

        // If specific activity codes were recorded in latest update, prioritize them
        if (affectedCodes && affectedCodes.length > 0) {
          const filtered = affectedActivities.filter(a => affectedCodes.includes(a.activityCode));
          if (filtered.length > 0) {
            affectedActivities = filtered;
          }
        }
      } else {
        affectedActivities = [...CANONICAL_SUSPENDED_ACTIVITIES];
      }
    }

    return NextResponse.json({
      success: true,
      siteName: DULIAJAN_SITE.siteName,
      coordinates: DULIAJAN_SITE.siteCoordinates,
      latitude: DULIAJAN_SITE.latitude,
      longitude: DULIAJAN_SITE.longitude,
      temperature,
      rainfallMM,
      windSpeedKmh,
      humidity,
      workSuspensionActive,
      affectedActivities,
      historicalSeasonDaysLost,
      baselineAllowedDays: DULIAJAN_SITE.baselineAllowedDays,
      netClaimableEotDays,
      contractualClause: DULIAJAN_SITE.contractualClause,
      rainfallThresholdMM: DULIAJAN_SITE.rainfallThresholdMM,
      stoppagesLoggedCount: stoppageRecords.length,
      lastUpdated: latestUpdate ? latestUpdate.timestamp : new Date().toISOString(),
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

/**
 * POST /api/weather
 * Records weather stoppage event into `informal_site_updates` and `audit_logs` in SQLite database.
 */
export async function POST(request: Request) {
  try {
    const body = await request.json();
    const {
      projectId = 'PRJ-OIL-2026',
      activityCode,
      affectedActivities,
      reason,
      rainfallMM,
      temperature,
      windSpeedKmh,
      humidity,
      workSuspensionActive = true,
      reportedBy = 'AWS-09 Meteorological Sensor',
      supervisorRole = 'Site Safety & Weather In-Charge',
      locationGeofence = '27.4825° N, 95.3225° E (Duliajan Station #09)',
      notes,
      mitigationAction,
      estimatedDelayDays,
    } = body;

    // Record stoppage event into informal_site_updates and audit_logs in SQLite
    const recordResult = realDb.recordWeatherStoppage({
      projectId,
      activityCode,
      affectedActivities,
      reason,
      rainfallMM: rainfallMM !== undefined ? Number(rainfallMM) : DULIAJAN_SITE.defaultRainfallMM,
      temperature: temperature !== undefined ? Number(temperature) : DULIAJAN_SITE.defaultTemperature,
      windSpeedKmh: windSpeedKmh !== undefined ? Number(windSpeedKmh) : DULIAJAN_SITE.defaultWindSpeedKmh,
      humidity: humidity !== undefined ? Number(humidity) : DULIAJAN_SITE.defaultHumidity,
      workSuspensionActive: Boolean(workSuspensionActive),
      reportedBy,
      supervisorRole,
      locationGeofence,
      notes,
      mitigationAction,
      estimatedDelayDays: estimatedDelayDays !== undefined ? Number(estimatedDelayDays) : 1.0,
    });

    return NextResponse.json({
      success: true,
      message: 'Weather stoppage event successfully recorded in informal_site_updates and audit_logs',
      updateId: recordResult.updateId,
      auditId: recordResult.auditId,
      projectId: recordResult.projectId,
      timestamp: recordResult.timestamp,
      workSuspensionActive: recordResult.workSuspensionActive,
      rainfallMM: recordResult.rainfallMM,
      primaryActivityCode: recordResult.primaryActivityCode,
      affectedActivityCodes: recordResult.affectedActivityCodes,
      reason: recordResult.reason,
      auditRecord: recordResult.auditRecord,
    }, { status: 201 });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
