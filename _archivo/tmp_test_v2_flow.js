const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();

async function testTwoStepFlow() {
    const imgPath = 'C:\\Users\\Usuario\\.gemini\\antigravity\\brain\\8c58ff06-5243-4734-a568-d54f7cdf47fc\\cheese_scale_test_1775403100764.png';
    
    // Step 1: UPLOAD ONLY
    console.log('1. Testing /api/upload-foto...');
    const formData = new FormData();
    const blob = new Blob([fs.readFileSync(imgPath)], { type: 'image/png' });
    formData.append('foto', blob, 'test_v2.png');

    const upRes = await fetch('http://localhost:5000/api/upload-foto', {
        method: 'POST',
        body: formData
    });
    const upData = await upRes.json();
    console.log('Upload Response:', JSON.stringify(upData, null, 2));

    if (!upData.filename) {
        console.error('FAILED: No filename returned from Upload');
        process.exit(1);
    }

    // Step 2: REGISTER IMMEDIATELY (Simulating user clicking "A mano")
    console.log('2. Testing /api/registrar-queso (Manual Bypassing OCR)...');
    const regRes = await fetch('http://localhost:5000/api/registrar-queso', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            fecha: '2026-04-05',
            equipo: 'MANUAL_BYPASS_TEST',
            peso_kg: 99.9,
            foto_path: upData.filename,
            creado_por: 'test_agent'
        })
    });
    const regData = await regRes.json();
    console.log('Registration Response:', JSON.stringify(regData, null, 2));

    // Step 3: VERIFY DB
    console.log('3. Verifying Database...');
    const dbPath = path.join(__dirname, 'data', 'sisgan_pro.db');
    const db = new sqlite3.Database(dbPath);
    db.get("SELECT * FROM queso WHERE equipo='MANUAL_BYPASS_TEST' ORDER BY id DESC LIMIT 1", (err, row) => {
        if (err) console.error(err);
        console.log('RECORD:', JSON.stringify(row, null, 2));
        db.close();
        if (row && row.foto_path === upData.filename) {
            console.log('VERIFICATION SUCCESSFUL: Evidence saved even without OCR completion.');
        } else {
            console.error('VERIFICATION FAILED: Evidence missing.');
            process.exit(1);
        }
    });
}

testTwoStepFlow();
