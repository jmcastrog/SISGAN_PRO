const sqlite3 = require('sqlite3').verbose();
const { Client } = require('pg');

// Configuración
const SQLITE_DB_PATH = 'data/sisgan_pro.db';
const POSTGRES_URI = 'postgresql://postgres:X_qdpxtZDTs-NG9@db.kvcdqrqitbiiinrrvwfe.supabase.co:5432/postgres';

async function migrate() {
    const db = new sqlite3.Database(SQLITE_DB_PATH);
    const pgClient = new Client({ connectionString: POSTGRES_URI });

    try {
        await pgClient.connect();
        console.log('Conectado a Supabase.');

        const tables = await new Promise((resolve, reject) => {
            db.all("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'", (err, rows) => {
                if (err) reject(err);
                else resolve(rows);
            });
        });

        for (const table of tables) {
            const tableName = table.name;
            console.log(`Migrando tabla: ${tableName}...`);

            // Obtener info de la tabla
            const columns = await new Promise((resolve, reject) => {
                db.all(`PRAGMA table_info(${tableName})`, (err, rows) => {
                    if (err) reject(err);
                    else resolve(rows);
                });
            });

            // Mapeo de tipos y creación de tabla en Postgres
            const colDefs = columns.map(col => {
                let pgType = '';
                const sqliteType = col.type.toUpperCase();
                
                if (sqliteType.includes('INT')) pgType = 'INTEGER';
                else if (sqliteType.includes('TEXT') || sqliteType === '') pgType = 'TEXT';
                else if (sqliteType.includes('REAL') || sqliteType.includes('FLOAT') || sqliteType.includes('NUMERIC')) pgType = 'DOUBLE PRECISION';
                else pgType = 'TEXT'; // Fallback

                // Manejo de PK
                if (col.pk) {
                    return `"${col.name}" ${pgType} PRIMARY KEY`;
                }
                return `"${col.name}" ${pgType}`;
            });

            const createTableSql = `CREATE TABLE IF NOT EXISTS "${tableName}" (${colDefs.join(', ')})`;
            await pgClient.query(createTableSql);
            
            // Limpiar datos previos en la tabla destino (opcional, pero para migración limpia es mejor)
            await pgClient.query(`TRUNCATE TABLE "${tableName}" RESTART IDENTITY CASCADE`).catch(e => {
                // Silenciar error si TRUNCATE falla (ej: si no hay PK o es tabla pequeña)
                return pgClient.query(`DELETE FROM "${tableName}"`);
            });

            // Leer datos de SQLite
            const rows = await new Promise((resolve, reject) => {
                db.all(`SELECT * FROM ${tableName}`, (err, rows) => {
                    if (err) reject(err);
                    else resolve(rows);
                });
            });

            if (rows.length > 0) {
                const columnNames = Object.keys(rows[0]).map(name => `"${name}"`).join(', ');
                for (const row of rows) {
                    const values = Object.values(row);
                    const placeholders = values.map((_, i) => `$${i + 1}`).join(', ');
                    const insertSql = `INSERT INTO "${tableName}" (${columnNames}) VALUES (${placeholders})`;
                    await pgClient.query(insertSql, values);
                }
            }
            console.log(`Tabla ${tableName} migrada con éxito (${rows.length} registros).`);
        }

        console.log('--- Migración Finalizada con Exito ---');

    } catch (err) {
        console.error('Error durante la migración:', err);
    } finally {
        db.close();
        await pgClient.end();
    }
}

migrate();
