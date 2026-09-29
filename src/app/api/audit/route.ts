import { NextResponse } from 'next/server';
import { realDb } from '@/lib/db';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const projectId = searchParams.get('projectId') || undefined;
  const auditLogs = realDb.getAuditLogs(projectId);
  return NextResponse.json({ success: true, count: auditLogs.length, auditLogs });
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { projectId, actorName, actorRole, action, entityType, entityId, previousValue, newValue, reason } = body;

    const log = realDb.addAuditLog({
      projectId,
      actorName: actorName || 'System Engineer',
      actorRole: actorRole || 'LEAD_PLANNING_ENGINEER',
      action: action || 'FIDIC_DELAY_NOTICE_ISSUED',
      entityType: entityType || 'ACTIVITY',
      entityId: entityId || 'FIDIC-8.4',
      previousValue: previousValue || null,
      newValue: newValue || null,
      reason: reason || 'FIDIC Clause 8.4 Delay Notice Exported/Shared',
    });

    return NextResponse.json({ success: true, auditLog: log });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

