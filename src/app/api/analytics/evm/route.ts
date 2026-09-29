import { NextResponse } from 'next/server';
import { realDb } from '@/lib/db';
import { computeEvmAnalytics } from '@/lib/evmEngine';

/**
 * GET /api/analytics/evm?projectId=X
 * 
 * Computes Earned Value Management (EVM) metrics directly from the SQLite database:
 * - Core EVM Metrics:
 *   - Planned Value (PV)
 *   - Earned Value (EV)
 *   - Actual Cost (AC)
 *   - Schedule Variance (SV = EV - PV)
 *   - Cost Variance (CV = EV - AC)
 *   - Schedule Performance Index (SPI = EV / PV)
 *   - Cost Performance Index (CPI = EV / AC)
 *   - Estimate At Completion (EAC = BAC / CPI)
 *   - Estimate To Complete (ETC = EAC - AC)
 *   - Variance At Completion (VAC = BAC - EAC)
 *   - To-Complete Performance Index (TCPI = (BAC - EV) / (BAC - AC))
 * 
 * - S-Curve Monthly Cumulative Arrays:
 *   - Monthly cumulative arrays for PV, EV, AC from project start_date to planned_finish_date
 *   - Incremental monthly work (incPV, incEV, incAC)
 *   - Monthly SPI & CPI performance index tracking
 *   - Health status tagging ('AHEAD', 'ON_TRACK', 'WARNING', 'DELAYED', 'CRITICAL', 'CURRENT', 'FORECAST')
 *   - Future projection beyond status date locking at BAC and EAC
 * 
 * - Discipline Breakdown:
 *   - Grouped performance indices across Civil, Piping, Mechanical, Electrical, HSE disciplines
 */
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    let projectId = searchParams.get('projectId');
    const scaleParam = searchParams.get('scale') as 'auto' | 'crore' | 'raw' | null;
    const asOfDate = searchParams.get('asOfDate') || undefined;

    // If projectId is not specified, default to the first project in SQLite
    if (!projectId) {
      const allProjects = realDb.getProjects();
      if (allProjects.length > 0) {
        projectId = allProjects[0].id;
      } else {
        return NextResponse.json(
          {
            success: false,
            error: 'No projects found in the database. Please initialize or import a project first.',
          },
          { status: 404 }
        );
      }
    }

    // Verify project exists in SQLite
    const project = realDb.getProjectById(projectId);
    if (!project) {
      return NextResponse.json(
        {
          success: false,
          error: `Project with ID '${projectId}' was not found in the SQLite database.`,
        },
        { status: 404 }
      );
    }

    // Compute EVM & S-Curve analytics directly from database
    const analytics = computeEvmAnalytics(projectId, {
      scale: scaleParam || 'auto',
      asOfDate,
    });

    return NextResponse.json(
      {
        ...analytics,
        timestamp: new Date().toISOString(),
      },
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-store, max-age=0',
        },
      }
    );
  } catch (error: any) {
    console.error('Error computing EVM analytics:', error);
    return NextResponse.json(
      {
        success: false,
        error: error.message || 'An unexpected error occurred while computing EVM analytics.',
      },
      { status: 500 }
    );
  }
}
