import { NextResponse } from 'next/server';
import { realDb } from '@/lib/db';
import { enterpriseStore } from '@/lib/stateStore';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const projectId = searchParams.get('projectId') || undefined;
  
  let updates = realDb.getInformalUpdates(projectId);
  if (updates.length === 0) {
    updates = enterpriseStore.getInformalUpdates();
  }
  return NextResponse.json({ success: true, count: updates.length, updates });
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const rawInput = body.rawInput || body.rawText;
    const projectId = body.projectId || realDb.getProjects()[0]?.id || 'PRJ-OIL-2026';
    const source = body.source || 'VOICE_HINDI';
    const reportedBy = body.reportedBy || 'Site Supervisor';
    const supervisorRole = body.supervisorRole || 'Site In-Charge';
    const locationGeofence = body.locationGeofence || 'Site GPS (Verified within Geofence)';

    if (!rawInput) {
      return NextResponse.json({ success: false, error: 'rawInput is required' }, { status: 400 });
    }

    const result = realDb.submitInformalUpdate({
      projectId,
      rawInput,
      source,
      reportedBy,
      supervisorRole,
      locationGeofence,
    });

    // Also mirror into enterpriseStore in-memory for backwards compatibility
    try {
      enterpriseStore.submitInformalUpdate({
        rawInput,
        source: source as any,
        reportedBy,
        supervisorRole,
        locationGeofence,
      });
    } catch (_) {}

    return NextResponse.json({
      success: true,
      message: 'Site update parsed and evaluated against P6 schedule activities in SQLite database',
      update: result.update,
      candidateMatches: result.candidateMatches,
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
