import { NextResponse } from 'next/server';
import { realDb } from '@/lib/db';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const projectId = searchParams.get('projectId') || undefined;
  const records = realDb.getDprRecords(projectId);
  return NextResponse.json({
    success: true,
    projectId,
    count: records.length,
    records,
    dpr: records,
  });
}

export async function POST(request: Request) {
  try {
    const body = await request.json();

    // Support batch DPR reporting
    if (Array.isArray(body.batch) || Array.isArray(body.reports)) {
      const projectId = body.projectId || realDb.getProjects()[0]?.id || 'PRJ-OIL-2026';
      const batchList = body.batch || body.reports;
      const batchResult = realDb.recordDprBatch(projectId, batchList);
      return NextResponse.json({
        ...batchResult,
        message: `Batch DPR submitted with ${batchResult.count} entries`,
      });
    }

    const { 
      projectId = realDb.getProjects()[0]?.id || 'PRJ-OIL-2026', 
      activityCode, 
      completedQuantity, 
      unit, 
      delayReason, 
      notes, 
      reportedBy = 'Field Supervisor', 
      supervisorRole = 'Section In-Charge' 
    } = body;

    if (!activityCode || completedQuantity === undefined) {
      return NextResponse.json({ 
        success: false, 
        error: 'activityCode and completedQuantity are required' 
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
