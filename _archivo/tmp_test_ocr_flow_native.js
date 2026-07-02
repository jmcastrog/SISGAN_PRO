const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();

async function testOcrFlow() {
    const imgPath = 'C:\\Users\\Usuario\\.gemini\\antigravity\\brain\\8c58ff06-5243-4734-a568-d54f7cdf47fc\\cheese_scale_test_1775403100764.png';
    
    // Node.js 21+ has global FormData and fetch
    const formData = new FormData();
    const blob = new Blob([fs.readFileSync(imgPath)], { type: 'image/png' });
    formData.append('foto', blob, 'test.png');

    console.log('1. Testing /api/ocr-peso...');
    try {
        const ocrRes = await fetch('http://localhost:5000/api/ocr-peso', {
            method: 'POST',
            body: formData
        });
        const ocrData = await ocrRes.json();
        console.log('OCR Response:', JSON.stringify(ocrData, null, 2));

        if (!ocrData.filename) {
            console.error('FAILED: No filename returned from OCR');
            process.exit(1);
        }

        console.log('2. Testing /api/registrar-queso...');
        const regRes = await fetch('http://localhost:5000/api/registrar-queso', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                fecha: '2026-04-05',
                equipo: 'TEST_ROBOT_NATIVE',
                peso_kg: ocrData.peso_ocr || 42.5,
                foto_path: ocrData.filename,
                creado_por: 'test_agent'
            })
        });
        const regData = await regRes.json();
        console.log('Registration Response:', JSON.stringify(regData, null, 2));

        console.log('3. Verifying Database...');
        const dbPath = path.join(__dirname, 'data', 'sisgan_pro.db');
        const db = new sqlite3.Database(dbPath);
        db.get("SELECT * FROM queso ORDER BY id DESC LIMIT 1", (err, row) => {
            if (err) console.error(err);
            console.log('LAST_RECORD:', JSON.stringify(row, null, 2));
            db.close();
            if (row && row.foto_path === ocrData.filename) {
                console.log('VERIFICATION SUCCESSFUL: Photo path saved correctly.');
            } else {
                console.error('VERIFICATION FAILED: Photo path not found or mismatch.');
                process.exit(1);
            }
        });
    } catch (e) {
        console.error('ERROR during testing:', e);
        process.exit(1);
    }
}

testOcrFlow();
