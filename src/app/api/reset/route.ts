import { NextResponse } from 'next/server';
import { realDb } from '@/lib/db';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { action } = body;

    if (action === 'WIPE_ALL') {
      realDb.wipeAllData();
      return NextResponse.json({
        success: true,
        message: 'All dummy and existing data wiped successfully. The database is now completely clean and empty.',
      });
    }

    if (action === 'LOAD_BENCHMARK') {
      realDb.loadOilBenchmark();
      return NextResponse.json({
        success: true,
        message: 'Loaded Oil India Limited (OIL) Official Benchmark Dataset for SIH26122.',
      });
    }

    return NextResponse.json({ success: false, error: 'Unknown action' }, { status: 400 });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
