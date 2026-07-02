const http = require('http');

const payload = JSON.stringify({
    fecha: "2026-04-05",
    equipo: "TARDE",
    peso_kg: 10.5,
    leche_usada_litros: 50,
    foto_path: null,
    creado_por: "admin"
});

const options = {
    hostname: 'localhost',
    port: 5000,
    path: '/api/registrar-queso',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
    }
};

const req1 = http.request(options, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
        console.log('Result 1 (Expected Success):', data);
        
        // now duplicate
        const req2 = http.request(options, (res2) => {
            let data2 = '';
            res2.on('data', chunk => data2 += chunk);
            res2.on('end', () => {
                console.log('Result 2 (Expected Fail 400):', data2);
            });
        });
        req2.on('error', e => console.error(e));
        req2.write(payload);
        req2.end();
    });
});
req1.on('error', e => console.error(e));
req1.write(payload);
req1.end();
