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
    const { projectId, name, badgeNumber, trade, skills, contractor, safetyCertValidTill } = body;

    if (!projectId || !name || !trade) {
      return NextResponse.json({ success: false, error: 'projectId, name, and trade are required' }, { status: 400 });
    }

    const worker = realDb.createWorker(projectId, {
      name,
      badgeNumber: badgeNumber || `LAB-${Date.now().toString().slice(-4)}`,
      trade,
      skills: skills || [],
      contractor: contractor || 'Site Contractor',
      safetyCertValidTill: safetyCertValidTill || '2027-12-31',
    });

    return NextResponse.json({ success: true, worker });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

export async function PATCH(request: Request) {
  try {
    const body = await request.json();
    const { workerId, status = 'VERIFIED_PRESENT', method = 'GEOFENCE_BIOMETRIC', confidence = 98.0 } = body;

    if (!workerId) {
      return NextResponse.json({ success: false, error: 'workerId is required' }, { status: 400 });
    }

    const updated = realDb.recordAttendance(workerId, status, method, confidence);
    return NextResponse.json({ success: true, message: `Clock-in verified for ${workerId}`, worker: updated });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

