import { NextResponse } from 'next/server';
import { realDb } from '@/lib/db';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const projectId = searchParams.get('projectId') || undefined;
  const workers = realDb.getWorkers(projectId);
  return NextResponse.json({ success: true, count: workers.length, workers });
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const projectId = body.projectId || realDb.getProjects()[0]?.id || 'PRJ-OIL-2026';

    // Support batch worker creation
    if (Array.isArray(body.workers)) {
      const createdBatch = realDb.createWorkersBatch(projectId, body.workers);
      return NextResponse.json({
        success: true,
        count: createdBatch.length,
        workers: createdBatch,
        message: `Registered ${createdBatch.length} workers in SQLite database`,
      });
    }

    const { name, badgeNumber, trade, skills, contractor, safetyCertValidTill, latitude, longitude } = body;

    if (!name || !trade) {
      return NextResponse.json({ success: false, error: 'name and trade are required' }, { status: 400 });
    }

    const worker = realDb.createWorker(projectId, {
      name,
      badgeNumber: badgeNumber || `LAB-${Date.now().toString().slice(-4)}`,
      trade,
      skills: skills || [],
      contractor: contractor || 'Site Contractor',
      safetyCertValidTill: safetyCertValidTill || '2027-12-31',
      latitude: latitude !== undefined ? Number(latitude) : undefined,
      longitude: longitude !== undefined ? Number(longitude) : undefined,
    });

    return NextResponse.json({ success: true, worker });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

export async function PATCH(request: Request) {
  try {
    const body = await request.json();

    // Support batch attendance recording
    if (Array.isArray(body.batch) || Array.isArray(body.attendance)) {
      const batchList = body.batch || body.attendance;
      const batchResults = realDb.recordAttendanceBatch(batchList);
      return NextResponse.json({
        success: true,
        count: batchResults.length,
        workers: batchResults,
        message: `Batch attendance verified for ${batchResults.length} workers`,
      });
    }

    const { 
      workerId, 
      status = 'VERIFIED_PRESENT', 
      method = 'GEOFENCE_BIOMETRIC', 
      confidence = 98.0,
      latitude,
      longitude,
    } = body;

    if (!workerId) {
      return NextResponse.json({ success: false, error: 'workerId is required' }, { status: 400 });
    }

    const lat = latitude !== undefined ? Number(latitude) : undefined;
    const lng = longitude !== undefined ? Number(longitude) : undefined;

    const updated = realDb.recordAttendance(workerId, status, method, Number(confidence), lat, lng);
    return NextResponse.json({ 
      success: true, 
      message: `Clock-in verified for ${workerId}`, 
      worker: updated 
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

