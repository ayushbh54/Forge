import { NextResponse } from 'next/server';
import { realDb } from '@/lib/db';

export async function GET() {
  const projects = realDb.getProjects();
  return NextResponse.json({ success: true, count: projects.length, projects });
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { id, code, name, client, contractorJV, contractType, location, budget, currency, startDate, plannedFinishDate } = body;

    if (!id || !name) {
      return NextResponse.json({ success: false, error: 'Project Unique ID and Name are required' }, { status: 400 });
    }

    const created = realDb.createProject({
      id: id.trim().toUpperCase(),
      code: code ? code.trim().toUpperCase() : id.trim().toUpperCase(),
      name: name.trim(),
      client: client || 'Client Pending',
      contractorJV: contractorJV || 'Not Assigned',
      contractType: contractType || 'FIDIC Red Book',
      lifecycle: 'EXECUTION',
      location: location || 'Site Location Pending',
      budget: budget || 0,
      currency: currency || 'INR (₹)',
      startDate: startDate || new Date().toISOString().split('T')[0],
      plannedFinishDate: plannedFinishDate || '',
      status: 'PLANNING',
    });

    return NextResponse.json({ success: true, project: created });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
