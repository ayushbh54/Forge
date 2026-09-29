import { NextResponse } from 'next/server';
import { enterpriseStore } from '@/lib/stateStore';

export async function GET() {
  const updates = enterpriseStore.getInformalUpdates();
  return NextResponse.json({ success: true, count: updates.length, updates });
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { rawInput, source = 'VOICE_HINDI', reportedBy = 'Site Supervisor', supervisorRole = 'Site In-Charge' } = body;

    if (!rawInput) {
      return NextResponse.json({ success: false, error: 'rawInput is required' }, { status: 400 });
    }

    const result = enterpriseStore.submitInformalUpdate({
      rawInput,
      source,
      reportedBy,
      supervisorRole,
    });

    return NextResponse.json({
      success: true,
      message: 'Site update parsed and evaluated against P6 schedule activities',
      update: result.update,
      candidateMatches: result.candidateMatches,
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
