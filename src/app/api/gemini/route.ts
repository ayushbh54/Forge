import { NextResponse } from 'next/server';
import { geminiBrain } from '@/lib/geminiBrain';
import { realDb } from '@/lib/db';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { action, payload, apiKey } = body;

    if (!action) {
      return NextResponse.json({ success: false, error: 'action is required' }, { status: 400 });
    }

    if (action === 'SET_KEY') {
      if (apiKey) {
        geminiBrain.setApiKey(apiKey);
        return NextResponse.json({ success: true, message: 'Global Gemini API key configured' });
      }
      return NextResponse.json({ success: false, error: 'apiKey missing' }, { status: 400 });
    }

    if (action === 'SET_MODULE_KEY') {
      const { module, key } = payload || {};
      if (module && key) {
        geminiBrain.setModuleApiKey(module, key);
        return NextResponse.json({ success: true, message: `Gemini API key for module [${module}] configured successfully` });
      }
      return NextResponse.json({ success: false, error: 'module and key are required' }, { status: 400 });
    }

    if (action === 'GET_KEYS_STATUS') {
      const status = geminiBrain.getKeyStatus();
      return NextResponse.json({ success: true, status });
    }

    if (action === 'PARSE_FIELD_UPDATE') {
      const { rawText, projectId } = payload;
      if (!rawText) {
        return NextResponse.json({ success: false, error: 'rawText is required' }, { status: 400 });
      }
      const activities = realDb.getActivities(projectId);
      const result = await geminiBrain.parseFieldUpdate(rawText, activities, apiKey);
      return NextResponse.json({ success: true, result });
    }

    if (action === 'TRIANGULATION_ANALYSIS') {
      const { activityCode, projectId } = payload;
      const activities = realDb.getActivities(projectId);
      const act = activities.find(a => a.activityCode === activityCode) || activities[0];
      if (!act) {
        return NextResponse.json({ success: false, error: 'Activity not found' }, { status: 404 });
      }
      const insight = await geminiBrain.analyzeTriangulation(act, apiKey);
      return NextResponse.json({ success: true, insight });
    }

    if (action === 'COPILOT_QUERY') {
      const { query, projectId } = payload;
      const project = projectId ? realDb.getProjectById(projectId) || null : null;
      const activities = realDb.getActivities(projectId);
      const workers = realDb.getWorkers(projectId);
      const materials = realDb.getMaterials(projectId);
      const conflicts = realDb.getConflicts(projectId);

      const reply = await geminiBrain.askCopilot(
        query,
        {
          project: project || (realDb.getProjects()[0] || null),
          activities,
          workers,
          materials,
          conflicts,
        },
        apiKey
      );

      return NextResponse.json({ success: true, reply });
    }

    return NextResponse.json({ success: false, error: `Unknown action: ${action}` }, { status: 400 });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
