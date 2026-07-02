// Script para migrar el esquema de la BD existente de SISGAN PRO
// Agrega las columnas que le faltan a la tabla animales y otras tablas
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('D:/Proyectos/SISGAN_PRO/data/sisgan_pro.db');

const columnasFaltantes = [
    { tabla: 'animales', col: 'comentarios', tipo: 'TEXT' },
    { tabla: 'animales', col: 'foto_animal', tipo: 'TEXT' },
    { tabla: 'animales', col: 'foto_hierro', tipo: 'TEXT' },
    { tabla: 'animales', col: 'fecha_parto_est', tipo: 'TEXT' },
    { tabla: 'partos', col: 'num_asignado', tipo: 'TEXT' },
    { tabla: 'partos', col: 'estado', tipo: 'TEXT DEFAULT "Vivo"' },
    { tabla: 'partos', col: 'observacion', tipo: 'TEXT' },
    { tabla: 'partos', col: 'estatus_cria', tipo: 'TEXT' },
    { tabla: 'partos', col: 'creado_por', tipo: 'TEXT' },
    { tabla: 'partos', col: 'creado_en', tipo: 'TEXT' },
    { tabla: 'control_leche', col: 'turno', tipo: 'TEXT' },
    { tabla: 'control_leche', col: 'creado_por', tipo: 'TEXT' },
    { tabla: 'control_leche', col: 'creado_en', tipo: 'TEXT' },
    { tabla: 'servicios', col: 'creado_por', tipo: 'TEXT' },
    { tabla: 'servicios', col: 'creado_en', tipo: 'TEXT' },
    { tabla: 'queso', col: 'equipo', tipo: 'TEXT' },
    { tabla: 'queso', col: 'creado_por', tipo: 'TEXT' },
    { tabla: 'queso', col: 'creado_en', tipo: 'TEXT' },
];

db.serialize(() => {
    columnasFaltantes.forEach(({ tabla, col, tipo }) => {
        const sql = `ALTER TABLE ${tabla} ADD COLUMN ${col} ${tipo}`;
        db.run(sql, [], (err) => {
            if (err && err.message.includes('duplicate column')) {
                console.log(`  [ya existe] ${tabla}.${col}`);
            } else if (err) {
                console.log(`  [ERROR] ${tabla}.${col}: ${err.message}`);
            } else {
                console.log(`  [OK] ${tabla}.${col} agregada`);
            }
        });
    });

    // Crear tabla usuarios si no existe
    db.run(`CREATE TABLE IF NOT EXISTS usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario TEXT UNIQUE,
        password TEXT,
        nombre TEXT,
        rol TEXT DEFAULT 'trabajador',
        activo INTEGER DEFAULT 1,
        creado_en TEXT
    )`, (err) => {
        if (err) console.log('Error tabla usuarios:', err.message);
        else console.log('  [OK] Tabla usuarios verificada');
    });

    // Crear tabla queso si no existe
    db.run(`CREATE TABLE IF NOT EXISTS queso (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT,
        equipo TEXT,
        peso_kg REAL,
        producto TEXT DEFAULT 'QUESO',
        creado_por TEXT,
        creado_en TEXT
    )`, (err) => {
        if (err && !err.message.includes('already exists')) console.log('Error tabla queso:', err.message);
        else console.log('  [OK] Tabla queso verificada');
    });

    db.close(() => {
        console.log('\nMIGRACION COMPLETADA');
    });
});
