const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const dbPath = path.join(__dirname, 'data', 'sisgan_pro.db');

const db = new sqlite3.Database(dbPath, (err) => {
    if (err) return console.error(err.message);
    db.serialize(() => {
        db.run("ALTER TABLE queso ADD COLUMN leche_usada_litros REAL", (err) => {
            if (err) {
                if (err.message.includes('duplicate column name')) {
                    console.log('Column leche_usada_litros already exists.');
                } else {
                    console.error('Error adding column:', err.message);
                }
            } else {
                console.log('Column leche_usada_litros added successfully.');
            }
            db.close();
        });
    });
});
