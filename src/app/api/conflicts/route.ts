import { NextResponse } from 'next/server';
import { realDb } from '@/lib/db';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const projectId = searchParams.get('projectId') || undefined;
  const conflicts = realDb.getConflicts(projectId);
  return NextResponse.json({ success: true, count: conflicts.length, conflicts });
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { conflictId, resolutionNote = 'Resolved by Project Management Authority' } = body;

    // Support conflict raising
    if (body.action === 'RAISE' || (!conflictId && body.title)) {
      const id = body.id || body.conflictId || body.idempotency_key || `CNF-${Date.now().toString().slice(-4)}`;
      const projectId = body.projectId || 'PRJ-OIL-2026';
      realDb.createConflict({
        id,
        projectId,
        activityCode: body.activityCode || 'PIP-L5-024',
        activityName: body.activityName || 'Pipeline Welding',
        type: body.type || 'SPEC_VARIATION',
        severity: body.severity || 'MEDIUM',
        title: body.title || 'Technical Spec Conflict',
        description: body.description || '',
        varianceValue: body.varianceValue || 'N/A',
        claimedValue: body.claimedValue || 'N/A',
        verifiedValue: body.verifiedValue || 'N/A',
        specOrClause: body.specOrClause || body.reference || 'FIDIC Cl. 4.21',
        actionRequired: body.actionRequired || 'Inspection required',
        status: body.status || 'OPEN',
      });
      return NextResponse.json({
        success: true,
        message: `Conflict ${id} created in SQLite ledger`,
        conflictId: id,
      });
    }

    if (!conflictId) {
      return NextResponse.json({ success: false, error: 'conflictId is required to resolve conflict' }, { status: 400 });
    }

    realDb.resolveConflict(conflictId, resolutionNote);
    return NextResponse.json({ 
      success: true, 
      message: `Conflict ${conflictId} marked as RESOLVED in SQLite ledger` 
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

