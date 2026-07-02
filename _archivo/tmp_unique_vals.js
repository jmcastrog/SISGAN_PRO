const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('data/sisgan_pro.db');

db.serialize(() => {
    db.all("SELECT DISTINCT tipo FROM ANIMALES", (err, rows) => {
        if (err) console.error(err);
        else console.log("TIPOS:", rows.map(r => r.tipo).filter(Boolean));
    });
    db.all("SELECT DISTINCT lote FROM ANIMALES", (err, rows) => {
        if (err) console.error(err);
        else console.log("LOTES:", rows.map(r => r.lote).filter(Boolean));
    });
    db.all("SELECT DISTINCT estatus FROM ANIMALES", (err, rows) => {
        if (err) console.error(err);
        else console.log("ESTATUS:", rows.map(r => r.estatus).filter(Boolean));
    });
});
db.close();
