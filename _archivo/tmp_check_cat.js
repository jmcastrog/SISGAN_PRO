const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('data/sisgan_pro.db');

db.serialize(() => {
    db.all("SELECT * FROM CAT_TIPO", (err, rows) => {
        console.log("CAT_TIPO:", rows);
    });
});
