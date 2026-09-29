import { NextResponse } from 'next/server';
import { realDb } from '@/lib/db';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { 
      projectId, 
      activityCode, 
      completedQuantity, 
      unit, 
      delayReason, 
      notes, 
      reportedBy = 'Field Supervisor', 
      supervisorRole = 'Section In-Charge' 
    } = body;

    if (!projectId || !activityCode || completedQuantity === undefined) {
      return NextResponse.json({ 
        success: false, 
        error: 'projectId, activityCode, and completedQuantity are required' 
      }, { status: 400 });
    }

    const result = realDb.recordDpr(projectId, {
      activityCode,
      completedQuantity: Number(completedQuantity),
      unit,
      delayReason,
      notes,
      reportedBy,
      supervisorRole,
    });

    return NextResponse.json({ 
      ...result,
      message: `Daily Progress Report for ${activityCode} recorded in SQLite database!`,
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
