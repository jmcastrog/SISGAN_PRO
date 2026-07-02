const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('d:/Proyectos/SISGAN_PRO/data/sisgan_pro.db');

db.all("SELECT DISTINCT tipo, lote, estatus FROM animales", (err, rows) => {
    if (err) {
        console.error(err);
        process.exit(1);
    }
    console.log(JSON.stringify(rows, null, 2));
    db.close();
});
