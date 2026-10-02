import { NextResponse } from 'next/server';
import { realDb } from '@/lib/db';
import { enterpriseStore } from '@/lib/stateStore';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const projectId = searchParams.get('projectId') || undefined;

  let project = projectId ? realDb.getProjectById(projectId) : realDb.getProjects()[0];
  if (!project) {
    project = enterpriseStore.getProject();
  }

  let activities = realDb.getActivities(projectId);
  if (activities.length === 0) {
    activities = enterpriseStore.getActivities();
  }

  return NextResponse.json({
    success: true,
    project,
    activities,
  });
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { activityCode, progress, delayReason } = body;
    const projectId = body.projectId || realDb.getProjects()[0]?.id || 'PRJ-OIL-2026';
    const reportedBy = body.reportedBy || 'Triangulation Engineer';

    if (!activityCode || progress === undefined) {
      return NextResponse.json({ success: false, error: 'activityCode and progress are required' }, { status: 400 });
    }

    let updated = realDb.updateActivityProgress(projectId, activityCode, Number(progress), delayReason, reportedBy);

    // Also mirror into enterpriseStore for backwards compatibility
    try {
      const storeUpdated = enterpriseStore.confirmAndApplyUpdate('UPD-API', activityCode, Number(progress));
      if (!updated && storeUpdated) {
        updated = storeUpdated;
      }
    } catch (_) {}

    if (!updated) {
      return NextResponse.json({ success: false, error: 'Activity not found in project' }, { status: 404 });
    }

    return NextResponse.json({
      success: true,
      message: 'Consensus truth recalculated and recorded in SQLite database',
      activity: updated,
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
