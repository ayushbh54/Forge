import { NextResponse } from 'next/server';
import { realDb } from '@/lib/db';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const projectId = searchParams.get('projectId') || undefined;
  const users = realDb.getUsers(projectId);
  return NextResponse.json({ success: true, count: users.length, users });
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { name, role, department, projectId, phone, email, badgeNumber, trade } = body;

    if (!name || !role || !projectId) {
      return NextResponse.json({ 
        success: false, 
        error: 'Name, Role, and Project Unique ID are mandatory to connect to the project workspace' 
      }, { status: 400 });
    }

    // Ensure the project exists in SQLite; if not, auto-create the project workspace for this unique ID
    let project = realDb.getProjectById(projectId.trim().toUpperCase());
    if (!project) {
      project = realDb.createProject({
        id: projectId.trim().toUpperCase(),
        code: projectId.trim().toUpperCase(),
        name: `Project ${projectId.trim().toUpperCase()}`,
        client: 'Universal Client Enterprise',
        contractorJV: 'Joint Venture Consortium',
        contractType: 'FIDIC Red Book Cl. 8.4',
        lifecycle: 'EXECUTION',
        location: 'Site Location',
        budget: 100000000,
        currency: 'INR (₹)',
        startDate: new Date().toISOString().split('T')[0],
        plannedFinishDate: '',
        status: 'ON_TRACK',
      });
    }

    // Register user in SQLite
    const user = realDb.registerUser({
      name: name.trim(),
      role: role.trim(),
      department: department ? department.trim() : 'Field Operations',
      projectId: projectId.trim().toUpperCase(),
      phone,
      email,
      badgeNumber,
      trade,
    });

    return NextResponse.json({
      success: true,
      message: `User ${name} successfully connected to Project ${projectId} workspace as ${role}`,
      user,
      project,
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
