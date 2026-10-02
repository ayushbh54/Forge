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
    const projectId = body.projectId || realDb.getProjects()[0]?.id || 'PRJ-OIL-2026';

    // Support batch material transaction posting
    if (Array.isArray(body.transactions) || Array.isArray(body.batch)) {
      const batchList = body.transactions || body.batch;
      const createdTxs = realDb.createMaterialTxBatch(projectId, batchList);
      return NextResponse.json({
        success: true,
        count: createdTxs.length,
        transactions: createdTxs,
        message: `Posted ${createdTxs.length} material ledger transactions to SQLite database`,
      });
    }

    const { 
      docType = 'GRN', 
      docNumber, 
      materialCode, 
      description, 
      quantity, 
      unit = 'units', 
      sourceSupplier,
      destinationLocation = 'Site Warehouse', 
      associatedActivityCode,
      issuedToSupervisor,
      date,
      status = 'DISPATCHED'
    } = body;

    if (!materialCode || quantity === undefined) {
      return NextResponse.json({ success: false, error: 'materialCode and quantity are required' }, { status: 400 });
    }

    const tx = realDb.createMaterialTx(projectId, {
      docType,
      docNumber,
      materialCode,
      description: description || `Transaction for ${materialCode}`,
      quantity: Number(quantity),
      unit,
      sourceSupplier,
      destinationLocation,
      associatedActivityCode,
      issuedToSupervisor,
      date,
      status,
    });

    return NextResponse.json({ success: true, transaction: tx });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
