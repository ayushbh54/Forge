import { NextResponse } from 'next/server';
import { realDb } from '@/lib/db';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const projectId = searchParams.get('projectId') || undefined;
    const id = searchParams.get('id') || undefined;
    const badgeNumber = searchParams.get('badgeNumber') || undefined;
    const email = searchParams.get('email') || undefined;

    if (id) {
      const user = realDb.getUserById(id);
      if (!user) {
        return NextResponse.json({ success: false, error: 'User not found' }, { status: 404 });
      }
      return NextResponse.json({ success: true, user });
    }

    if (projectId && (badgeNumber || email)) {
      const user = realDb.findUser(projectId.trim().toUpperCase(), { badgeNumber, email });
      if (!user) {
        return NextResponse.json({ success: false, error: 'User not found in project' }, { status: 404 });
      }
      return NextResponse.json({ success: true, user });
    }

    const users = realDb.getUsers(projectId);
    return NextResponse.json({ success: true, count: users.length, users });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { action, name, role, department, projectId, phone, email, badgeNumber, trade, identifier } = body;

    const normProjectId = (projectId || 'PRJ-OIL-2026').trim().toUpperCase();

    // Ensure the project exists in SQLite; if not, auto-create the project workspace for this unique ID
    let project = realDb.getProjectById(normProjectId);
    if (!project) {
      project = realDb.createProject({
        id: normProjectId,
        code: normProjectId,
        name: `Project ${normProjectId}`,
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

    // Direct Login / Lookup
    if (action === 'LOGIN') {
      const searchBadge = badgeNumber || identifier;
      const searchEmail = email || identifier;
      const existingUser = realDb.findUser(normProjectId, {
        badgeNumber: searchBadge,
        email: searchEmail,
        name: name || identifier,
      });

      if (!existingUser) {
        return NextResponse.json({
          success: false,
          error: `No registered credentials found matching '${identifier || badgeNumber || email || name}' in project ${normProjectId}.`,
        }, { status: 404 });
      }

      return NextResponse.json({
        success: true,
        message: `User ${existingUser.name} successfully authenticated`,
        user: existingUser,
        project,
      });
    }

    // Registration Flow
    if (!name || !role || !projectId) {
      return NextResponse.json({ 
        success: false, 
        error: 'Name, Role, and Project Unique ID are mandatory to connect to the project workspace' 
      }, { status: 400 });
    }

    // Register user in SQLite (idempotent: updates existing if matched by badgeNumber or email)
    const user = realDb.registerUser({
      name: name.trim(),
      role: role.trim(),
      department: department ? department.trim() : 'Field Operations',
      projectId: normProjectId,
      phone,
      email,
      badgeNumber,
      trade,
    });

    return NextResponse.json({
      success: true,
      message: `User ${name} successfully connected to Project ${normProjectId} workspace as ${role}`,
      user,
      project,
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
