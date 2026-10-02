// Direct In-Process Audit Verification of All 16 Next.js API Routes & SQLite DB
const assert = require('assert');
const path = require('path');

function makeRequest(url, method = 'GET', body = null) {
  const init = { method, headers: { 'content-type': 'application/json' } };
  if (body) {
    init.body = JSON.stringify(body);
  }
  return new Request(url, init);
}

async function run() {
  console.log('\n========================================================');
  console.log('🔬 NIRMAAN OS — COMPLETE 16-ENDPOINT IN-PROCESS AUDIT');
  console.log('========================================================\n');

  let passed = 0;
  let total = 0;

  async function test(name, fn) {
    total++;
    try {
      await fn();
      passed++;
      console.log(`  ✅ [PASS] ${name}`);
    } catch (e) {
      console.error(`  ❌ [FAIL] ${name}`);
      console.error(`     ${e.stack || e.message}`);
    }
  }

  // Helper to get userland
  function getRoute(routePath) {
    const fullPath = path.join(process.cwd(), '.next/server/app/api', routePath, 'route.js');
    delete require.cache[require.resolve(fullPath)];
    const mod = require(fullPath);
    return mod.routeModule.userland;
  }

  // 1. Reset & Benchmark
  await test('1. POST /api/reset (LOAD_BENCHMARK)', async () => {
    const { POST } = getRoute('reset');
    const req = makeRequest('http://localhost/api/reset', 'POST', { action: 'LOAD_BENCHMARK' });
    const res = await POST(req);
    if (res.status !== 200) console.error('Err:', await res.text());
    assert.strictEqual(res.status, 200);
    const data = await res.json();
    assert.strictEqual(data.success, true);
  });

  // 2. Projects
  await test('2. GET & POST /api/projects', async () => {
    const { GET, POST } = getRoute('projects');
    
    // Check initial benchmark
    const getRes = await GET(makeRequest('http://localhost/api/projects'));
    if (getRes.status !== 200) console.error('Err:', await getRes.text());
    assert.strictEqual(getRes.status, 200);
    const getData = await getRes.json();
    assert.strictEqual(getData.success, true);
    assert(getData.projects.length >= 1);

    // Create new project
    const postRes = await POST(makeRequest('http://localhost/api/projects', 'POST', {
      id: 'PRJ-AUD-99',
      code: 'AUD-99',
      name: 'Audit Corridor Expansion',
      client: 'Oil India Limited',
    }));
    if (postRes.status !== 200) console.error('Err:', await postRes.text());
    assert.strictEqual(postRes.status, 200);
    const postData = await postRes.json();
    assert.strictEqual(postData.success, true);
    assert.strictEqual(postData.project.id, 'PRJ-AUD-99');

    // Query single project by id
    const singleRes = await GET(makeRequest('http://localhost/api/projects?id=PRJ-AUD-99'));
    if (singleRes.status !== 200) console.error('Err:', await singleRes.text());
    assert.strictEqual(singleRes.status, 200);
    const singleData = await singleRes.json();
    assert.strictEqual(singleData.project.code, 'AUD-99');
  });

  // 3. Activities
  await test('3. GET & POST /api/activities (single & batch)', async () => {
    const { GET, POST } = getRoute('activities');

    // Single activity
    const singleRes = await POST(makeRequest('http://localhost/api/activities', 'POST', {
      projectId: 'PRJ-AUD-99',
      activityData: {
        id: 'ACT-AUD-101',
        activityCode: 'PIP-AUD-101',
        name: 'Corridor Section Welds',
        discipline: 'PIPING',
        plannedQuantity: 500,
      },
    }));
    if (singleRes.status !== 200) console.error('Err:', await singleRes.text());
    assert.strictEqual(singleRes.status, 200);
    const singleData = await singleRes.json();
    assert.strictEqual(singleData.success, true);

    // Batch activities
    const batchRes = await POST(makeRequest('http://localhost/api/activities', 'POST', {
      projectId: 'PRJ-AUD-99',
      activities: [
        { id: 'ACT-AUD-102', activityCode: 'CIV-AUD-102', name: 'Anchor Block Civils', discipline: 'CIVIL' },
        { id: 'ACT-AUD-103', activityCode: 'ELE-AUD-103', name: 'ICCP Cable Trench', discipline: 'ELECTRICAL' },
      ],
    }));
    if (batchRes.status !== 200) console.error('Err:', await batchRes.text());
    assert.strictEqual(batchRes.status, 200);
    const batchData = await batchRes.json();
    assert.strictEqual(batchData.count, 2);

    // Query activities
    const listRes = await GET(makeRequest('http://localhost/api/activities?projectId=PRJ-AUD-99'));
    if (listRes.status !== 200) console.error('Err:', await listRes.text());
    assert.strictEqual(listRes.status, 200);
    const listData = await listRes.json();
    assert.strictEqual(listData.activities.length, 3);
  });

  // 4. Workforce
  await test('4. GET, POST, PATCH /api/workforce (GPS clock-in & batch)', async () => {
    const { GET, POST, PATCH } = getRoute('workforce');

    // Single worker
    const postRes = await POST(makeRequest('http://localhost/api/workforce', 'POST', {
      projectId: 'PRJ-AUD-99',
      name: 'Subhash Kalita',
      trade: 'WELDER',
      badgeNumber: 'LAB-AUD-101',
    }));
    if (postRes.status !== 200) console.error('Err:', await postRes.text());
    assert.strictEqual(postRes.status, 200);

    // Batch workers
    const batchRes = await POST(makeRequest('http://localhost/api/workforce', 'POST', {
      projectId: 'PRJ-AUD-99',
      workers: [
        { name: 'Worker Two', trade: 'FITTER', badgeNumber: 'LAB-AUD-102' },
        { name: 'Worker Three', trade: 'RIGGER', badgeNumber: 'LAB-AUD-103' },
      ],
    }));
    if (batchRes.status !== 200) console.error('Err:', await batchRes.text());
    assert.strictEqual(batchRes.status, 200);
    const batchData = await batchRes.json();
    assert.strictEqual(batchData.count, 2);

    // GPS Clock-in
    const patchRes = await PATCH(makeRequest('http://localhost/api/workforce', 'PATCH', {
      workerId: 'LAB-AUD-101',
      status: 'VERIFIED_PRESENT',
      method: 'GEOFENCE_BIOMETRIC',
      confidence: 99.4,
      latitude: 27.4855,
      longitude: 95.3211,
    }));
    if (patchRes.status !== 200) console.error('Err:', await patchRes.text());
    assert.strictEqual(patchRes.status, 200);
    const patchData = await patchRes.json();
    assert.strictEqual(patchData.worker.latitude, 27.4855);
    assert.strictEqual(patchData.worker.longitude, 95.3211);

    // Query list
    const listRes = await GET(makeRequest('http://localhost/api/workforce?projectId=PRJ-AUD-99'));
    if (listRes.status !== 200) console.error('Err:', await listRes.text());
    const listData = await listRes.json();
    assert.strictEqual(listData.workers.length, 3);
  });

  // 5. DPR
  await test('5. GET & POST /api/dpr (single & batch)', async () => {
    const { GET, POST } = getRoute('dpr');

    // Single DPR
    const singleRes = await POST(makeRequest('http://localhost/api/dpr', 'POST', {
      projectId: 'PRJ-AUD-99',
      activityCode: 'PIP-AUD-101',
      completedQuantity: 45,
      unit: 'meters',
      reportedBy: 'Site In-Charge',
    }));
    if (singleRes.status !== 200) console.error('Err:', await singleRes.text());
    assert.strictEqual(singleRes.status, 200);

    // Batch DPR
    const batchRes = await POST(makeRequest('http://localhost/api/dpr', 'POST', {
      projectId: 'PRJ-AUD-99',
      batch: [
        { activityCode: 'CIV-AUD-102', completedQuantity: 25, unit: 'meters' },
        { activityCode: 'ELE-AUD-103', completedQuantity: 60, unit: 'meters' },
      ],
    }));
    if (batchRes.status !== 200) console.error('Err:', await batchRes.text());
    assert.strictEqual(batchRes.status, 200);
    const batchData = await batchRes.json();
    assert.strictEqual(batchData.count, 2);

    // GET historical records
    const listRes = await GET(makeRequest('http://localhost/api/dpr?projectId=PRJ-AUD-99'));
    if (listRes.status !== 200) console.error('Err:', await listRes.text());
    assert.strictEqual(listRes.status, 200);
    const listData = await listRes.json();
    assert(listData.records.length >= 3);
  });

  // 6. Materials
  await test('6. GET & POST /api/materials (single & batch)', async () => {
    const { GET, POST } = getRoute('materials');

    // Single
    const singleRes = await POST(makeRequest('http://localhost/api/materials', 'POST', {
      projectId: 'PRJ-AUD-99',
      docType: 'GRN',
      materialCode: 'STEEL-PIPE-X65',
      quantity: 150,
      unit: 'meters',
    }));
    if (singleRes.status !== 200) console.error('Err:', await singleRes.text());
    assert.strictEqual(singleRes.status, 200);

    // Batch
    const batchRes = await POST(makeRequest('http://localhost/api/materials', 'POST', {
      projectId: 'PRJ-AUD-99',
      batch: [
        { docType: 'GIN', materialCode: 'E7018-ELECTRODE', quantity: 80, unit: 'kg' },
        { docType: 'GIN', materialCode: 'HEAT-SHRINK-SLEEVE', quantity: 24, unit: 'units' },
      ],
    }));
    if (batchRes.status !== 200) console.error('Err:', await batchRes.text());
    assert.strictEqual(batchRes.status, 200);
    const batchData = await batchRes.json();
    assert.strictEqual(batchData.count, 2);

    // Query list
    const listRes = await GET(makeRequest('http://localhost/api/materials?projectId=PRJ-AUD-99'));
    if (listRes.status !== 200) console.error('Err:', await listRes.text());
    const listData = await listRes.json();
    assert.strictEqual(listData.materials.length, 3);
  });

  // 7. Conflicts
  await test('7. GET & POST /api/conflicts (raise & resolve)', async () => {
    const { GET, POST } = getRoute('conflicts');

    // Raise
    const raiseRes = await POST(makeRequest('http://localhost/api/conflicts', 'POST', {
      action: 'RAISE',
      id: 'CNF-AUD-991',
      projectId: 'PRJ-AUD-99',
      activityCode: 'PIP-AUD-101',
      title: 'NDT Level II Radiography Hold',
      description: 'Girth welds #W-01 to #W-04 require certified interpreter sign-off',
      severity: 'HIGH',
    }));
    if (raiseRes.status !== 200) console.error('Err:', await raiseRes.text());
    assert.strictEqual(raiseRes.status, 200);

    // Resolve
    const resolveRes = await POST(makeRequest('http://localhost/api/conflicts', 'POST', {
      conflictId: 'CNF-AUD-991',
      resolutionNote: 'Certified NDT RT Level II sign-off received. Acceptance verified.',
    }));
    if (resolveRes.status !== 200) console.error('Err:', await resolveRes.text());
    assert.strictEqual(resolveRes.status, 200);

    // Query list
    const listRes = await GET(makeRequest('http://localhost/api/conflicts?projectId=PRJ-AUD-99'));
    if (listRes.status !== 200) console.error('Err:', await listRes.text());
    const listData = await listRes.json();
    assert(listData.conflicts.length >= 1);
    const resolved = listData.conflicts.find(c => c.id === 'CNF-AUD-991');
    assert.strictEqual(resolved.status, 'RESOLVED');
  });

  // 8. Audit Logs & SHA-256
  await test('8. GET & POST /api/audit (SHA-256 verification)', async () => {
    const { GET, POST } = getRoute('audit');

    // Add audit log
    const postRes = await POST(makeRequest('http://localhost/api/audit', 'POST', {
      projectId: 'PRJ-AUD-99',
      actorName: 'Audit Inspector',
      actorRole: 'Quality Assurance',
      action: 'NDT_INSPECTION_SIGNED',
      entityType: 'EVIDENCE',
      entityId: 'RT-PASS-991',
      reason: 'Radiography films verified 100% compliant with API 1104',
    }));
    if (postRes.status !== 200) console.error('Err:', await postRes.text());
    assert.strictEqual(postRes.status, 200);

    // Query logs
    const listRes = await GET(makeRequest('http://localhost/api/audit?projectId=PRJ-AUD-99'));
    if (listRes.status !== 200) console.error('Err:', await listRes.text());
    const listData = await listRes.json();
    assert(listData.auditLogs.length > 0);
    for (const l of listData.auditLogs) {
      assert(l.sha256Hash && l.sha256Hash.length === 64, `Invalid SHA256: ${l.sha256Hash}`);
    }
  });

  // 9. Equipment & Fleet
  await test('9. GET & POST /api/equipment (Fleet telemetry & breakdown)', async () => {
    const { GET, POST } = getRoute('equipment');

    // Query fleet
    const listRes = await GET(makeRequest('http://localhost/api/equipment?projectId=PRJ-OIL-2026'));
    if (listRes.status !== 200) console.error('Err:', await listRes.text());
    assert.strictEqual(listRes.status, 200);
    const listData = await listRes.json();
    assert(listData.equipment.length >= 24);
    assert(listData.fleetBreakdown.cranesCount > 0);

    // Record breakdown
    const breakRes = await POST(makeRequest('http://localhost/api/equipment', 'POST', {
      projectId: 'PRJ-OIL-2026',
      equipmentId: 'EQ-CRANE-01',
      breakdownReason: 'Fuel injector blockage',
      activityCode: 'PIP-L5-024',
      estimatedDowntimeHours: 5,
    }));
    if (breakRes.status !== 200) console.error('Err:', await breakRes.text());
    assert.strictEqual(breakRes.status, 200);
    const breakData = await breakRes.json();
    assert.strictEqual(breakData.equipment.status, 'BREAKDOWN');
  });

  // 10. Linking Bridge
  await test('10. GET & POST /api/linking (AI NLP parsing)', async () => {
    const { GET, POST } = getRoute('linking');

    // Submit Hindi update
    const postRes = await POST(makeRequest('http://localhost/api/linking', 'POST', {
      projectId: 'PRJ-OIL-2026',
      source: 'VOICE_HINDI',
      rawInput: 'Line 24 ka pipe welding 30 meter complete hua hai',
      reportedBy: 'Field Supervisor',
    }));
    if (postRes.status !== 200) console.error('Err:', await postRes.text());
    assert.strictEqual(postRes.status, 200);
    const postData = await postRes.json();
    assert.strictEqual(postData.update.matchedActivityCode, 'PIP-L5-024');

    // Query updates
    const listRes = await GET(makeRequest('http://localhost/api/linking?projectId=PRJ-OIL-2026'));
    if (listRes.status !== 200) console.error('Err:', await listRes.text());
    const listData = await listRes.json();
    assert(listData.updates.length > 0);
  });

  // 11. Truth Triangulation
  await test('11. GET & POST /api/truth (Multi-factor consensus)', async () => {
    const { GET, POST } = getRoute('truth');

    // Update progress
    const postRes = await POST(makeRequest('http://localhost/api/truth', 'POST', {
      projectId: 'PRJ-OIL-2026',
      activityCode: 'PIP-L5-024',
      progress: 78.0,
      delayReason: 'Slow progress due to morning rain',
    }));
    if (postRes.status !== 200) console.error('Err:', await postRes.text());
    assert.strictEqual(postRes.status, 200);
    const postData = await postRes.json();
    assert.strictEqual(postData.activity.contractorReportedProgress, 78.0);
    assert(postData.activity.validatedConsensusProgress > 0);

    // Query truth
    const getRes = await GET(makeRequest('http://localhost/api/truth?projectId=PRJ-OIL-2026'));
    if (getRes.status !== 200) console.error('Err:', await getRes.text());
    assert.strictEqual(getRes.status, 200);
    const getData = await getRes.json();
    assert(getData.activities.length > 0);
  });

  // 12. Weather Telemetry
  await test('12. GET & POST /api/weather (FIDIC 8.4(c) Stoppage)', async () => {
    const { GET, POST } = getRoute('weather');

    // Record stoppage
    const postRes = await POST(makeRequest('http://localhost/api/weather', 'POST', {
      projectId: 'PRJ-OIL-2026',
      rainfallMM: 60.0,
      workSuspensionActive: true,
      reason: 'Monsoon deluge 60mm > 25mm safety threshold',
    }));
    if (postRes.status !== 200 && postRes.status !== 201) console.error('Err:', await postRes.text());
    assert(postRes.status === 200 || postRes.status === 201, `Expected 200 or 201, got ${postRes.status}`);
    const postData = await postRes.json();
    assert.strictEqual(postData.workSuspensionActive, true);

    // Query weather
    const getRes = await GET(makeRequest('http://localhost/api/weather?projectId=PRJ-OIL-2026'));
    if (getRes.status !== 200) console.error('Err:', await getRes.text());
    assert.strictEqual(getRes.status, 200);
    const getData = await getRes.json();
    assert.strictEqual(getData.rainfallMM, 60.0);
    assert.strictEqual(getData.workSuspensionActive, true);
  });

  // 13. EVM & S-Curve
  await test('13. GET /api/analytics/evm', async () => {
    const { GET } = getRoute('analytics/evm');
    const res = await GET(makeRequest('http://localhost/api/analytics/evm?projectId=PRJ-OIL-2026'));
    if (res.status !== 200) console.error('Err:', await res.text());
    assert.strictEqual(res.status, 200);
    const data = await res.json();
    assert(data.metrics && data.metrics.spi !== undefined, 'Expected metrics.spi');
    assert(data.metrics && data.metrics.cpi !== undefined, 'Expected metrics.cpi');
    assert(data.sCurve && data.sCurve.months.length > 0, 'Expected sCurve.months');
  });

  // 14. Risk Radar
  await test('14. GET /api/risk', async () => {
    const { GET } = getRoute('risk');
    const res = await GET(makeRequest('http://localhost/api/risk?projectId=PRJ-OIL-2026'));
    if (res.status !== 200) console.error('Err:', await res.text());
    assert.strictEqual(res.status, 200);
    const data = await res.json();
    assert(data.summary && data.summary.overallRiskLevel !== undefined, 'Expected summary.overallRiskLevel');
    assert(data.disciplines && data.disciplines.length > 0, 'Expected disciplines');
  });

  // 15. Auth & Users (Registration, Lookup, and Login)
  await test('15. GET & POST /api/auth', async () => {
    const { GET, POST } = getRoute('auth');
    const postRes = await POST(makeRequest('http://localhost/api/auth', 'POST', {
      name: 'Dr. Marcus Vance, P.E.',
      role: "Engineer's Representative (FIDIC 3.1)",
      department: 'Assurance & Governance',
      projectId: 'PRJ-AUD-99',
      badgeNumber: 'FIDIC-001',
      email: 'm.vance@oil.in',
    }));
    if (postRes.status !== 200) console.error('Err:', await postRes.text());
    assert.strictEqual(postRes.status, 200);

    // Single lookup via badge
    const badgeRes = await GET(makeRequest('http://localhost/api/auth?projectId=PRJ-AUD-99&badgeNumber=FIDIC-001'));
    assert.strictEqual(badgeRes.status, 200);
    const badgeData = await badgeRes.json();
    assert.strictEqual(badgeData.user.name, 'Dr. Marcus Vance, P.E.');

    // Direct Login test
    const loginRes = await POST(makeRequest('http://localhost/api/auth', 'POST', {
      action: 'LOGIN',
      projectId: 'PRJ-AUD-99',
      identifier: 'FIDIC-001',
    }));
    assert.strictEqual(loginRes.status, 200);
    const loginData = await loginRes.json();
    assert.strictEqual(loginData.user.badge_number, 'FIDIC-001');

    const getRes = await GET(makeRequest('http://localhost/api/auth?projectId=PRJ-AUD-99'));
    if (getRes.status !== 200) console.error('Err:', await getRes.text());
    assert.strictEqual(getRes.status, 200);
    const getData = await getRes.json();
    assert(getData.users.length >= 1);
  });

  // 16. Gemini Intelligence
  await test('16. POST /api/gemini (Key status & heuristic parsing)', async () => {
    const { POST } = getRoute('gemini');
    
    // Status
    const statusRes = await POST(makeRequest('http://localhost/api/gemini', 'POST', {
      action: 'GET_KEYS_STATUS',
    }));
    if (statusRes.status !== 200) console.error('Err:', await statusRes.text());
    assert.strictEqual(statusRes.status, 200);
    const statusData = await statusRes.json();
    assert.strictEqual(statusData.success, true);

    // Test missing payload safe handling
    const safeRes = await POST(makeRequest('http://localhost/api/gemini', 'POST', {
      action: 'PARSE_FIELD_UPDATE',
    }));
    assert.strictEqual(safeRes.status, 400);

    // Field update parsing with heuristic fallback
    const parseRes = await POST(makeRequest('http://localhost/api/gemini', 'POST', {
      action: 'PARSE_FIELD_UPDATE',
      payload: {
        projectId: 'PRJ-OIL-2026',
        rawText: 'Welding completed on Line 24 for 40 meters',
      },
    }));
    if (parseRes.status !== 200) console.error('Err:', await parseRes.text());
    assert.strictEqual(parseRes.status, 200);
    const parseData = await parseRes.json();
    assert.strictEqual(parseData.success, true);
    assert(parseData.result.matchedActivityCode.includes('PIP'));
  });

  // 17. Error Boundary Checks
  await test('17. Validation & Error Boundaries', async () => {
    const { POST: postProjects } = getRoute('projects');
    const errProjects = await postProjects(makeRequest('http://localhost/api/projects', 'POST', { foo: 'bar' }));
    assert.strictEqual(errProjects.status, 400);

    const { POST: postTruth } = getRoute('truth');
    const errTruth = await postTruth(makeRequest('http://localhost/api/truth', 'POST', { activityCode: 'PIP-01' }));
    assert.strictEqual(errTruth.status, 400);

    const { GET: getProjects } = getRoute('projects');
    const errNotFound = await getProjects(makeRequest('http://localhost/api/projects?id=INVALID_999999'));
    assert.strictEqual(errNotFound.status, 404);
  });

  console.log('\n========================================================');
  console.log(`🎉 SUMMARY: ${passed}/${total} API ROUTES & CAPABILITIES VERIFIED!`);
  console.log('========================================================\n');

  if (passed !== total) {
    process.exit(1);
  }
}

run().catch(err => {
  console.error('Test suite failed:', err);
  process.exit(1);
});
