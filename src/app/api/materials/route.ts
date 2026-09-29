import { NextResponse } from 'next/server';
import { realDb } from '@/lib/db';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const projectId = searchParams.get('projectId') || undefined;
  const materials = realDb.getMaterials(projectId);
  return NextResponse.json({ success: true, count: materials.length, materials });
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { projectId, docType, docNumber, materialCode, description, quantity, unit, destinationLocation, associatedActivityCode } = body;

    if (!projectId || !docType || !materialCode || !quantity) {
      return NextResponse.json({ success: false, error: 'projectId, docType, materialCode, and quantity are required' }, { status: 400 });
    }

    const tx = realDb.createMaterialTx(projectId, {
      docType,
      docNumber,
      materialCode,
      description,
      quantity,
      unit,
      destinationLocation,
      associatedActivityCode,
    });

    return NextResponse.json({ success: true, transaction: tx });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
