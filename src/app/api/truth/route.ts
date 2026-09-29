import { NextResponse } from 'next/server';
import { enterpriseStore } from '@/lib/stateStore';

export async function GET() {
  const activities = enterpriseStore.getActivities();
  const project = enterpriseStore.getProject();
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

    const updated = enterpriseStore.confirmAndApplyUpdate('UPD-API', activityCode, progress);
    if (!updated) {
      return NextResponse.json({ success: false, error: 'Activity not found' }, { status: 404 });
    }

    return NextResponse.json({
      success: true,
      message: 'Consensus truth recalculated',
      activity: updated,
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
