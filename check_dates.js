const sqlite3 = require('sqlite3');
const fs = require('fs');
const dbPath = fs.existsSync('data/sisgan_pro.db') ? 'data/sisgan_pro.db' : 'sisgan_pro.db';
console.log('Using:', dbPath);
const db = new sqlite3.Database(dbPath);
db.all("SELECT DISTINCT fecha FROM control_leche WHERE turno = 'M' ORDER BY fecha", (err, rows) => {
    if (err) console.log(err.message);
    else {
        console.log('Dates found:', rows.length);
        rows.forEach(r => console.log(r.fecha));
    }
    db.close();
});
