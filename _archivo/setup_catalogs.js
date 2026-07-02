const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('data/sisgan_pro.db');

function toCleanSet(arr) {
    const s = new Set();
    arr.forEach(val => {
        if (!val) return;
        let c = val.trim();
        if (c.length > 0) {
            c = c.charAt(0).toUpperCase() + c.slice(1).toLowerCase();
            s.add(c);
        }
    });
    return Array.from(s).sort();
}

db.serialize(() => {
    // Create tables
    db.run(`CREATE TABLE IF NOT EXISTS CAT_TIPO ( id INTEGER PRIMARY KEY AUTOINCREMENT, valor TEXT UNIQUE )`);
    db.run(`CREATE TABLE IF NOT EXISTS CAT_LOTE ( id INTEGER PRIMARY KEY AUTOINCREMENT, valor TEXT UNIQUE )`);
    db.run(`CREATE TABLE IF NOT EXISTS CAT_ESTATUS ( id INTEGER PRIMARY KEY AUTOINCREMENT, valor TEXT UNIQUE )`);

    db.all("SELECT DISTINCT tipo FROM ANIMALES", (err, rows) => {
        if (err) return;
        const cleaned = toCleanSet(rows.map(r => r.tipo));
        const stmt = db.prepare("INSERT OR IGNORE INTO CAT_TIPO (valor) VALUES (?)");
        cleaned.forEach(val => stmt.run(val));
        stmt.finalize(() => {
            console.log("CAT_TIPO inserted");
            db.all("SELECT DISTINCT lote FROM ANIMALES", (err, rows2) => {
                const cleaned2 = toCleanSet(rows2.map(r => r.lote));
                const stmt2 = db.prepare("INSERT OR IGNORE INTO CAT_LOTE (valor) VALUES (?)");
                cleaned2.forEach(val => stmt2.run(val));
                stmt2.finalize(() => {
                    console.log("CAT_LOTE inserted");
                    db.all("SELECT DISTINCT estatus FROM ANIMALES", (err, rows3) => {
                        const cleaned3 = toCleanSet(rows3.map(r => r.estatus));
                        const stmt3 = db.prepare("INSERT OR IGNORE INTO CAT_ESTATUS (valor) VALUES (?)");
                        cleaned3.forEach(val => stmt3.run(val));
                        stmt3.finalize(() => {
                            console.log("CAT_ESTATUS inserted");
                            db.close();
                        });
                    });
                });
            });
        });
    });
});
