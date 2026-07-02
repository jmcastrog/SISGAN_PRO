const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const dbPath = path.join(__dirname, 'data', 'sisgan_pro.db');

const db = new sqlite3.Database(dbPath, (err) => {
    if (err) return console.error(err.message);
    db.all("SELECT sql FROM sqlite_master WHERE type='table' AND name='queso'", [], (err, rows) => {
        if (err) return console.error(err.message);
        console.log('SCHEMA_QUESO:');
        rows.forEach(row => console.log(row.sql));
        db.close();
    });
});
