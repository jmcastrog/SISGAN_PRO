const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('data/sisgan_pro.db');

db.serialize(() => {
    db.all("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'", (err, tables) => {
        if (err) {
            console.error(err);
            return;
        }

        tables.forEach(table => {
            console.log(`--- Table: ${table.name} ---`);
            db.all(`PRAGMA table_info(${table.name})`, (err, schema) => {
                if (err) console.error(err);
                else console.log(JSON.stringify(schema, null, 2));
            });
            db.get(`SELECT count(*) as total FROM ${table.name}`, (err, row) => {
                if (err) console.error(err);
                else console.log(`Total records: ${row.total}`);
            });
        });
    });
});
