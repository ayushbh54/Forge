import { NextResponse } from 'next/server';
import { realDb } from '@/lib/db';

export const dynamic = 'force-dynamic';

/**
 * GET /api/equipment?projectId=X
 * Returns fleet list of 24 heavy machines (Cranes, Excavators, Welding Rigs, DG sets).
 */
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const projectId = searchParams.get('projectId') || 'PRJ-OIL-2026';

    const equipment = realDb.getEquipment(projectId);

    const cranes = equipment.filter((e) => e.category === 'CRANE');
    const excavators = equipment.filter((e) => e.category === 'EXCAVATOR');
    const weldingRigs = equipment.filter((e) => e.category === 'WELDING_RIG');
    const dgSets = equipment.filter((e) => e.category === 'DG_SET');

    return NextResponse.json({
      success: true,
      projectId,
      count: equipment.length,
      totalCount: equipment.length,
      fleetBreakdown: {
        cranesCount: cranes.length,
        excavatorsCount: excavators.length,
        weldingRigsCount: weldingRigs.length,
        dgSetsCount: dgSets.length,
      },
      summary: {
        totalFleet: equipment.length,
        active: equipment.filter((e) => e.status === 'ACTIVE' || e.status === 'ACTIVE_DEPLOYED').length,
        standby: equipment.filter((e) => e.status === 'STANDBY').length,
        breakdown: equipment.filter((e) => e.status === 'BREAKDOWN').length,
        maintenance: equipment.filter((e) => e.status === 'MAINTENANCE').length,
      },
      equipment,
      data: equipment,
    });
  } catch (error: any) {
    console.error('Error fetching equipment fleet:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Internal Server Error' },
      { status: 500 }
    );
  }
}

/**
 * POST /api/equipment
 * Records equipment breakdown, logs delay reason in DPR table, and writes audit record in SQLite.
 */
export async function POST(request: Request) {
  try {
    const body = await request.json();
    const {
      projectId = 'PRJ-OIL-2026',
      equipmentId,
      id,
      breakdownReason,
      reason,
      delayReason,
      activityCode,
      associatedAct,
      reportedBy = 'Field Equipment Operator',
      supervisorRole = 'Plant & Machinery Lead',
      estimatedDowntimeHours = 6,
      downtimeHours,
      notes,
    } = body;

    const targetEquipmentId = equipmentId || id;
    const targetReason = breakdownReason || reason;

    if (!targetEquipmentId) {
      return NextResponse.json(
        {
          success: false,
          error: 'equipmentId is required to record an equipment breakdown',
        },
        { status: 400 }
      );
    }

    if (!targetReason) {
      return NextResponse.json(
        {
          success: false,
          error: 'breakdownReason is required to record an equipment breakdown',
        },
        { status: 400 }
      );
    }

    const hours = downtimeHours !== undefined ? Number(downtimeHours) : Number(estimatedDowntimeHours);

    const result = realDb.recordEquipmentBreakdown({
      projectId,
      equipmentId: targetEquipmentId,
      breakdownReason: targetReason,
      delayReason: delayReason || `Critical Equipment Breakdown: ${targetReason}`,
      activityCode: activityCode || associatedAct,
      reportedBy,
      supervisorRole,
      estimatedDowntimeHours: isNaN(hours) ? 6 : hours,
      notes,
    });

    return NextResponse.json(
      {
        success: true,
        message: `Equipment breakdown recorded for ${targetEquipmentId}, delay reason logged in DPR table, and audit record written to SQLite!`,
        equipment: result.equipment,
        dprRecord: result.dprRecord,
        auditRecord: result.auditRecord,
      },
      { status: 200 }
    );
  } catch (error: any) {
    console.error('Error recording equipment breakdown:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Failed to record equipment breakdown' },
      { status: 500 }
    );
  }
}
