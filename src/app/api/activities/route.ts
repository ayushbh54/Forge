import { NextResponse } from 'next/server';
import { realDb } from '@/lib/db';
import { importScheduleFromText } from '@/lib/scheduleImporter';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const projectId = searchParams.get('projectId') || undefined;
  const activities = realDb.getActivities(projectId);
  return NextResponse.json({ success: true, count: activities.length, activities });
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { projectId, importMode, rawScheduleContent, format = 'CSV_TABLE', activityData } = body;

    if (!projectId) {
      return NextResponse.json({ success: false, error: 'projectId is required' }, { status: 400 });
    }

    if (importMode && rawScheduleContent) {
      const result = importScheduleFromText(projectId, rawScheduleContent, format);
      return NextResponse.json({
        success: true,
        message: `Imported ${result.activitiesCount} real activities (${result.criticalCount} critical path) into project ${projectId}`,
        ...result,
      });
    }

    if (Array.isArray(body.activities)) {
      const acts = realDb.createActivitiesBatch(projectId, body.activities);
      return NextResponse.json({ success: true, count: acts.length, activities: acts });
    }

    if (activityData) {
      const act = realDb.createActivity(projectId, activityData);
      return NextResponse.json({ success: true, activity: act });
    }

    return NextResponse.json({ success: false, error: 'Invalid payload: provide importMode, activities array, or activityData' }, { status: 400 });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
