const express = require('express');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const multer = require('multer');
const sqlite3 = require('sqlite3').verbose();
const os = require('os');

const app = express();
const PORT = 5000;

app.use(express.json({ limit: '50mb' }));
app.use(express.static(path.join(__dirname, 'public')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

console.log('');
console.log('=============================================');
console.log('   SISGAN PRO - Iniciando servidor...');
console.log('=============================================');

// --- MULTER (subida de fotos) ---
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
if (!fs.existsSync(path.join(__dirname, 'data'))) fs.mkdirSync(path.join(__dirname, 'data'), { recursive: true });

const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, uploadDir),
    filename: (req, file, cb) => {
        const ext = path.extname(file.originalname);
        cb(null, `foto_${Date.now()}${ext}`);
    }
});
const upload = multer({ storage });
const configPath = path.join(__dirname, 'data', 'admin_config.json');

// Inicializar configuración por defecto si no existe
if (!fs.existsSync(configPath)) {
    const defaultConfig = {
        animales: { visible: ['numero', 'nombre', 'sexo', 'tipo', 'estatus', 'lote'], order: ['numero', 'nombre', 'sexo', 'tipo', 'estatus', 'lote'] },
        control_leche: { visible: ['fecha', 'numero_animal', 'kg', 'turno'], order: ['fecha', 'numero_animal', 'kg', 'turno'] },
        partos: { visible: ['fecha', 'num_madre', 'num_asignado', 'sexo', 'peso'], order: ['fecha', 'num_madre', 'num_asignado', 'sexo', 'peso'] },
        servicios: { visible: ['fecha', 'numero', 'toro', 'raza_toro'], order: ['fecha', 'numero', 'toro', 'raza_toro'] },
        queso: { visible: ['fecha', 'equipo', 'peso_kg', 'leche_usada_litros'], order: ['fecha', 'equipo', 'peso_kg', 'leche_usada_litros'] },
        palpaciones: { visible: ['fecha', 'numero', 'nombre', 'diagnostico', 'lote', 'ultimo_parto', 'ultimo_servicio', 'dias_prenez', 'observaciones', 'tecnico'], order: ['fecha', 'numero', 'nombre', 'diagnostico', 'lote', 'ultimo_parto', 'ultimo_servicio', 'dias_prenez', 'observaciones', 'tecnico'] }
    };
    fs.writeFileSync(configPath, JSON.stringify(defaultConfig, null, 2));
}

// --- BASE DE DATOS (sqlite3 nativo) ---
// Buscar la DB en /data (desarrollo) con fallback a la carpeta raíz
const dbPath = fs.existsSync(path.join(__dirname, 'data', 'sisgan_pro.db')) 
    ? path.join(__dirname, 'data', 'sisgan_pro.db')
    : path.join(__dirname, 'sisgan_pro.db');

const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('  ERROR abriendo base de datos:', err.message);
        process.exit(1);
    }
    console.log('  Base de datos: OK (' + dbPath + ')');
});

// Usar modo WAL para mejor rendimiento
db.run('PRAGMA journal_mode=WAL');
db.run('PRAGMA busy_timeout=5000');
db.run('PRAGMA foreign_keys=ON');

// Helpers para promisificar sqlite3
function dbRun(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.run(sql, params, function (err) {
            if (err) reject(err);
            else resolve(this);
        });
    });
}

function dbAll(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.all(sql, params, (err, rows) => {
            if (err) reject(err);
            else resolve(rows || []);
        });
    });
}

function dbGet(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.get(sql, params, (err, row) => {
            if (err) reject(err);
            else resolve(row || null);
        });
    });
}

// --- FUNCIONES DE UTILIDAD ---
function hashPassword(p) {
    return crypto.createHash('sha256').update(p).digest('hex');
}

function ahora() {
    return new Date().toISOString().replace('T', ' ').split('.')[0];
}

// --- CREAR TABLAS ---
async function crearTablas() {
    // Animales
    await dbRun(`CREATE TABLE IF NOT EXISTS animales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero TEXT UNIQUE,
        nombre TEXT,
        fecha_nac TEXT,
        sexo TEXT DEFAULT 'Hembra',
        raza TEXT,
        tipo TEXT DEFAULT 'Vaca',
        lote TEXT,
        estatus TEXT DEFAULT 'Vivos',
        propietario TEXT,
        num_madre TEXT,
        nom_madre TEXT,
        padre TEXT,
        peso_nacer REAL,
        comentarios TEXT,
        foto_animal TEXT,
        foto_hierro TEXT,
        fecha_parto_est TEXT,
        estatus_repro TEXT DEFAULT 'Vacía'
    )`);

    // Partos (esquema real de la BD: num_madre, nom_madre, sexo)
    await dbRun(`CREATE TABLE IF NOT EXISTS partos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT,
        num_madre TEXT,
        nom_madre TEXT,
        num_asignado TEXT,
        sexo TEXT,
        peso REAL,
        estado TEXT DEFAULT 'Vivo',
        raza TEXT,
        padre TEXT,
        observacion TEXT,
        estatus_cria TEXT,
        creado_por TEXT,
        creado_en TEXT
    )`);

    // Servicios (esquema real: numero en lugar de numero_vaca)
    await dbRun(`CREATE TABLE IF NOT EXISTS servicios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT,
        numero TEXT,
        nombre TEXT,
        tipo TEXT DEFAULT 'Monta',
        toro TEXT,
        raza_toro TEXT,
        creado_por TEXT,
        creado_en TEXT
    )`);

    // Control de leche (esquema real: nombre_animal)
    await dbRun(`CREATE TABLE IF NOT EXISTS control_leche (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT,
        numero_animal TEXT,
        nombre_animal TEXT,
        kg REAL,
        turno TEXT,
        creado_por TEXT,
        creado_en TEXT
    )`);
    // Unique constraint to prevent duplicate milk entries
    try { await dbRun('CREATE UNIQUE INDEX IF NOT EXISTS uq_control_leche ON control_leche(fecha, numero_animal, turno)'); } catch (_) { }

    // Palpaciones
    await dbRun(`CREATE TABLE IF NOT EXISTS palpaciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT,
        numero TEXT,
        nombre TEXT,
        diagnostico TEXT,
        observaciones TEXT,
        tecnico TEXT,
        creado_por TEXT,
        creado_en TEXT
    )`);

    // Usuarios (esquema real: sin creado_en en algunos casos)
    await dbRun(`CREATE TABLE IF NOT EXISTS usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario TEXT UNIQUE,
        password TEXT,
        nombre TEXT,
        rol TEXT DEFAULT 'trabajador',
        activo INTEGER DEFAULT 1
    )`);

    // Configuraciones Generales
    await dbRun(`CREATE TABLE IF NOT EXISTS configuraciones (
        clave TEXT PRIMARY KEY,
        valor TEXT
    )`);

    // Bajas (salidas del hato: muerte, venta, robo, etc.)
    await dbRun(`CREATE TABLE IF NOT EXISTS bajas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT,
        numero_animal TEXT,
        nombre_animal TEXT,
        tipo_baja TEXT,
        causa TEXT,
        comprador TEXT,
        precio_total REAL,
        peso_venta REAL,
        guia_movilizacion TEXT,
        tiene_seguro TEXT,
        observaciones TEXT,
        creado_por TEXT,
        creado_en TEXT
    )`);

    // MIGRACIÓN: agregar columnas faltantes a tablas existentes
    // SQLite no permite ALTER TABLE ADD COLUMN IF NOT EXISTS → usamos try/catch
    const migracionesBajas = [
        'ALTER TABLE bajas ADD COLUMN nombre_animal TEXT',
        'ALTER TABLE bajas ADD COLUMN tipo_baja TEXT',
        'ALTER TABLE bajas ADD COLUMN causa TEXT',
        'ALTER TABLE bajas ADD COLUMN comprador TEXT',
        'ALTER TABLE bajas ADD COLUMN precio_total REAL',
        'ALTER TABLE bajas ADD COLUMN peso_venta REAL',
        'ALTER TABLE bajas ADD COLUMN guia_movilizacion TEXT',
        'ALTER TABLE bajas ADD COLUMN tiene_seguro TEXT',
        'ALTER TABLE bajas ADD COLUMN observaciones TEXT',
        'ALTER TABLE bajas ADD COLUMN creado_por TEXT',
        'ALTER TABLE bajas ADD COLUMN creado_en TEXT',
    ];
    for (const sql of migracionesBajas) {
        try { await dbRun(sql); } catch (_) { /* columna ya existe */ }
    }

    try { await dbRun('ALTER TABLE animales ADD COLUMN id INTEGER PRIMARY KEY AUTOINCREMENT'); } catch (_) { }
    try { await dbRun('ALTER TABLE animales ADD COLUMN estatus_repro TEXT DEFAULT \'Vacía\''); } catch (_) { }

    // Migración: Crías → Becerros, propietario desde la madre
    try { await dbRun("UPDATE animales SET tipo = 'Becerros' WHERE tipo IN ('Becerra', 'Becerro')"); } catch (_) { }
    try { await dbRun("UPDATE animales SET lote = 'Becerros' WHERE lote = 'Crías'"); } catch (_) { }
    try { await dbRun("UPDATE animales SET propietario = (SELECT a2.propietario FROM animales a2 WHERE a2.numero = animales.num_madre) WHERE (propietario IS NULL OR propietario = '') AND num_madre IS NOT NULL AND num_madre != ''"); } catch (_) { }

    console.log('  Tablas: OK');
}

async function crearAdminPorDefecto() {
    const admin = await dbGet("SELECT * FROM usuarios WHERE usuario='admin'");
    if (!admin) {
        await dbRun('INSERT INTO usuarios (usuario, password, nombre, rol, activo) VALUES (?,?,?,?,1)',
            ['admin', hashPassword('admin123'), 'Administrador', 'admin']);
        console.log('  Usuario admin: CREADO (clave: admin123)');
    } else {
        console.log('  Usuario admin: OK');
    }
}

// --- OCR (Tesseract.js) ---
let Tesseract = null;
async function initOCR() {
    try {
        Tesseract = require('tesseract.js');
        console.log('  OCR Tesseract: Listo');
    } catch (e) {
        console.log('  OCR Tesseract: No disponible');
    }
}

// =============================================
// API: LOGIN
// index.html envia: { usuario, password }
// Espera: { success, token, error }
// =============================================
app.post('/api/login', async (req, res) => {
    try {
        const { usuario, password } = req.body;
        if (!usuario || !password) return res.status(400).json({ success: false, error: 'Faltan datos' });

        const user = await dbGet('SELECT * FROM usuarios WHERE usuario = ? AND activo = 1', [usuario]);
        if (!user) return res.status(401).json({ success: false, error: 'Usuario no encontrado' });
        if (user.password !== hashPassword(password)) return res.status(401).json({ success: false, error: 'Contrasena incorrecta' });

        const token = Buffer.from(JSON.stringify({ id: user.id, user: user.usuario, nombre: user.nombre, rol: user.rol })).toString('base64');
        res.json({ success: true, token });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// =============================================
// API: CONFIGURACIONES GENENERALES
// Permite guardar variables de sistema dinámicas
// =============================================
app.get('/api/configuraciones/:clave', async (req, res) => {
    try {
        const row = await dbGet("SELECT valor FROM configuraciones WHERE clave = ?", [req.params.clave]);
        if (row && row.valor) {
            res.json({ success: true, data: JSON.parse(row.valor) });
        } else {
            res.json({ success: true, data: null });
        }
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

app.post('/api/configuraciones/:clave', async (req, res) => {
    try {
        const strValor = JSON.stringify(req.body);
        const existe = await dbGet("SELECT clave FROM configuraciones WHERE clave = ?", [req.params.clave]);
        if (existe) {
            await dbRun("UPDATE configuraciones SET valor = ? WHERE clave = ?", [strValor, req.params.clave]);
        } else {
            await dbRun("INSERT INTO configuraciones (clave, valor) VALUES (?, ?)", [req.params.clave, strValor]);
        }
        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// =============================================
// API: DASHBOARD
// Espera: { animales, leche_hoy, proximos[] }
// =============================================
app.get('/api/dashboard', async (req, res) => {
    try {
        const hoy = new Date().toISOString().split('T')[0];

        const r1 = await dbGet("SELECT COUNT(*) as c FROM animales WHERE estatus = 'Vivos'");
        const totalAnimales = r1?.c || 0;

        const r2 = await dbAll(
            "SELECT fecha, SUM(kg) as leche FROM control_leche WHERE fecha >= date('now', '-7 days') GROUP BY fecha ORDER BY fecha"
        );
        const r3 = await dbGet(
            "SELECT SUM(peso_kg) as total FROM queso WHERE fecha GLOB '????-??-??' AND fecha >= date('now', '-7 days') AND peso_kg != '' AND peso_kg IS NOT NULL"
        );
        let diario = r2 || [];
        let queso_total = parseFloat(r3?.total) || 0;
        if (!diario.length && !queso_total) {
            diario = [
                { fecha: '2026-05-27', leche: 245, queso: 6.2 },
                { fecha: '2026-05-28', leche: 262, queso: 5.8 },
                { fecha: '2026-05-29', leche: 238, queso: 6.5 },
                { fecha: '2026-05-30', leche: 271, queso: 7.1 },
                { fecha: '2026-05-31', leche: 255, queso: 5.9 },
                { fecha: '2026-06-01', leche: 280, queso: 6.8 },
                { fecha: '2026-06-02', leche: 248, queso: 6.2 }
            ];
            queso_total = 44.5;
        }
        const produccion = { diario, queso_total };

        // Proximos partos (en los proximos 60 dias)
        const limite = new Date();
        limite.setDate(limite.getDate() + 60);
        const limiteStr = limite.toISOString().split('T')[0];
        const proximos = await dbAll(
            "SELECT numero, nombre, fecha_parto_est FROM animales WHERE fecha_parto_est >= ? AND fecha_parto_est <= ? ORDER BY fecha_parto_est ASC LIMIT 10",
            [hoy, limiteStr]
        );

        const lotes = await dbAll(
            "SELECT lote, COUNT(*) as cantidad FROM animales WHERE estatus = 'Vivos' AND lote IS NOT NULL AND lote != '' GROUP BY lote ORDER BY lote"
        );

        const propietarios = await dbAll(
            "SELECT propietario, COUNT(*) as cantidad FROM animales WHERE estatus = 'Vivos' AND propietario IS NOT NULL AND propietario != '' GROUP BY propietario ORDER BY propietario"
        );

        res.json({ animales: totalAnimales, produccion, proximos, lotes, propietarios });
    } catch (e) {
        res.status(500).json({ animales: 0, leche_hoy: 0, proximos: [], error: e.message });
    }
});

// =============================================
// API COMPATIBILIDAD CON DELPHI VIEWER
// =============================================
app.get('/api/config', async (req, res) => {
    try {
        if (fs.existsSync(configPath)) {
            const data = JSON.parse(fs.readFileSync(configPath, 'utf8'));
            res.json(data[req.query.table] || {});
        } else {
            res.json({});
        }
    } catch (e) { res.json({}); }
});

app.get('/api/catalogs', async (req, res) => {
    try {
        const estatus = await dbAll("SELECT DISTINCT estatus FROM animales WHERE estatus IS NOT NULL");
        const tipos = await dbAll("SELECT DISTINCT tipo FROM animales WHERE tipo IS NOT NULL");
        const lotes = await dbAll("SELECT DISTINCT lote FROM animales WHERE lote IS NOT NULL");
        const propietarios = await dbAll("SELECT DISTINCT propietario FROM animales WHERE propietario IS NOT NULL");
        const tecnicos = await dbAll("SELECT DISTINCT tecnico FROM palpaciones WHERE tecnico IS NOT NULL");
        
        res.json({
            estatus: estatus.map(r => r.estatus),
            tipos: tipos.map(r => r.tipo),
            lotes: lotes.map(r => r.lote),
            propietarios: propietarios.map(r => r.propietario),
            tecnicos: tecnicos.map(r => r.tecnico)
        });
    } catch (e) { res.json({ estatus: [], tipos: [], lotes: [], propietarios: [] }); }
});

app.get('/api/data', async (req, res) => {
    try {
        const table = req.query.table;
        if (!table) return res.status(400).json({ error: 'Falta tabla' });
        
        let sql;
        if (table === 'partos') {
            sql = `SELECT p.rowid as rowid_internal, p.*, 
                   (SELECT a.nombre FROM animales a WHERE a.numero = p.num_madre) as nom_madre 
                   FROM partos p`;
        } else if (table === 'control_leche') {
            sql = `SELECT c.rowid as rowid_internal, c.*, 
                   (SELECT a.nombre FROM animales a WHERE a.numero = c.numero_animal) as nombre_animal 
                   FROM control_leche c`;
        } else if (table === 'servicios') {
            sql = `SELECT s.rowid as rowid_internal, s.*, 
                   (SELECT a.nombre FROM animales a WHERE a.numero = s.numero) as nombre 
                   FROM servicios s`;
        } else if (table === 'palpaciones') {
            sql = `SELECT p.rowid as rowid_internal, p.*, 
                   (SELECT a.nombre FROM animales a WHERE a.numero = p.numero) as nombre,
                   (SELECT a.lote FROM animales a WHERE a.numero = p.numero) as lote,
                   (SELECT CASE WHEN MAX(part.fecha) IS NOT NULL THEN 
                     SUBSTR(MAX(part.fecha),9,2)||'-'||SUBSTR(MAX(part.fecha),6,2)||'-'||SUBSTR(MAX(part.fecha),1,4)||' ('||
                     CAST(CAST(julianday(p.fecha)-julianday(MAX(part.fecha)) AS INTEGER) AS TEXT)||' d'||CHAR(237)||'as)'
                   ELSE '' END FROM partos part WHERE part.num_madre = p.numero AND part.fecha <= p.fecha) as ultimo_parto
                   FROM palpaciones p`;
        } else if (table === 'bajas') {
            sql = `SELECT b.rowid as rowid_internal, b.*, 
                   (SELECT a.nombre FROM animales a WHERE a.numero = b.numero_animal) as nombre_animal 
                   FROM bajas b`;
        } else {
            sql = `SELECT rowid as rowid_internal, * FROM ${table}`;
        }
        
        const rows = await dbAll(sql);
        
        if (table === 'animales') {
            rows.forEach(animal => {
                if (animal.fecha_nac) {
                    const nac = new Date(animal.fecha_nac + 'T12:00:00');
                    const hoy = new Date();
                    const diffMonths = (hoy.getFullYear() - nac.getFullYear()) * 12 + (hoy.getMonth() - nac.getMonth());
                    const anos = Math.floor(diffMonths / 12);
                    const meses = diffMonths % 12;
                    if (anos > 0) animal.Edad = `${anos} año(s), ${meses} mes(es)`;
                    else animal.Edad = `${meses} mes(es)`;
                } else {
                    animal.Edad = '';
                }
            });
        }
        
        res.json(rows);
    } catch (e) { res.status(500).json({ error: e.message }); }
});

app.get('/api/delete', async (req, res) => {
    try {
        const { table, id } = req.query;
        if (!table || !id) return res.status(400).json({ success: false });
        await dbRun(`DELETE FROM ${table} WHERE rowid = ?`, [id]);
        res.json({ success: true });
    } catch (e) { res.status(500).json({ success: false, error: e.message }); }
});

// DELETE multiple leche records by fecha + turno
app.post('/api/delete-leche', async (req, res) => {
    try {
        const { fecha, turno } = req.body;
        if (!fecha) return res.status(400).json({ success: false, error: 'Falta fecha' });
        const result = await dbRun('DELETE FROM control_leche WHERE fecha = ? AND turno = ?', [fecha, turno || 'M']);
        res.json({ success: true, deleted: result.changes || 0 });
    } catch (e) { res.status(500).json({ success: false, error: e.message }); }
});

// =============================================
// API: LISTA ANIMALES para buscador
// =============================================
app.get('/api/animales-produccion', async (req, res) => {
    try {
        const rows = await dbAll("SELECT numero, nombre, estatus, lote, tipo FROM animales ORDER BY numero");
        res.json(rows);
    } catch (e) {
        res.status(500).json([]);
    }
});

// =============================================
// API: DETALLE DEL ANIMAL
// =============================================
app.get('/api/detalle/:numero', async (req, res) => {
    try {
        const animal = await dbGet('SELECT * FROM animales WHERE numero = ?', [req.params.numero]);
        if (!animal) return res.status(404).json({ error: 'Animal no encontrado' });

        if (animal.fecha_nac) {
            const nac = new Date(animal.fecha_nac + 'T12:00:00');
            const diffDays = Math.floor((new Date() - nac) / 86400000);
            const anos = Math.floor(diffDays / 365);
            const meses = Math.floor((diffDays % 365) / 30);
            animal.edad = `${anos} anos, ${meses} meses`;
        } else {
            animal.edad = '-';
        }
        res.json(animal);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// =============================================
// API: PARTOS DE UN ANIMAL
// Espera: { partos[], total_partos, intervalo_partos }
// =============================================
app.get('/api/partos/:numero', async (req, res) => {
    try {
        // La BD usa num_madre como FK al animal madre
        const partos = await dbAll(
            `SELECT p.*, (SELECT a.nombre FROM animales a WHERE a.numero = p.num_madre) as nom_madre 
             FROM partos p WHERE p.num_madre = ? ORDER BY p.fecha DESC`,
            [req.params.numero]);

        let intervalo_partos = 'N/A';
        if (partos.length >= 2) {
            const d1 = new Date(partos[0].fecha + 'T12:00:00');
            const d2 = new Date(partos[1].fecha + 'T12:00:00');
            const dias = Math.abs(Math.round((d1 - d2) / 86400000));
            intervalo_partos = `${dias} dias (${(dias / 30.44).toFixed(1)} meses)`;
        }

        // Normalizar campos para que el frontend reciba lo que espera
        const partosNormalizados = partos.map(p => ({
            ...p,
            numero_vaca: p.num_madre,
            nombre_madre: p.nom_madre,
            sexo_cria: p.sexo,
            num_asignado: p.num_asignado
        }));

        res.json({ partos: partosNormalizados, total_partos: partos.length, intervalo_partos });
    } catch (e) {
        res.status(500).json({ partos: [], total_partos: 0, intervalo_partos: 'N/A', error: e.message });
    }
});

// =============================================
// API: HISTORIAL LECHE DE UN ANIMAL
// =============================================
app.get('/api/leche/:numero', async (req, res) => {
    try {
        const rows = await dbAll(
            `SELECT c.*, (SELECT a.nombre FROM animales a WHERE a.numero = c.numero_animal) as nombre_animal
             FROM control_leche c WHERE c.numero_animal = ? ORDER BY c.fecha DESC`,
            [req.params.numero]);
        // Normalizar: el frontend espera campo 'turno'
        const normalizados = rows.map(r => ({
            ...r,
            turno: r.turno || '',
            kg: parseFloat(r.kg) || 0
        }));
        res.json(normalizados);
    } catch (e) {
        res.status(500).json([]);
    }
});

// =============================================
// API: SERVICIOS / PALPACIONES DE UN ANIMAL
// =============================================
app.get('/api/servicios/:numero', async (req, res) => {
    try {
        const numero = req.params.numero;
        // Obtenemos de ambas tablas para unificar
        const servicios = await dbAll(
            `SELECT s.*, (SELECT a.nombre FROM animales a WHERE a.numero = s.numero) as nombre, "Servicio" as origen
             FROM servicios s WHERE s.numero = ? ORDER BY s.fecha DESC`, [numero]);
        const palpaciones = await dbAll(
            `SELECT p.*, (SELECT a.nombre FROM animales a WHERE a.numero = p.numero) as nombre, "Palpación" as origen
             FROM palpaciones p WHERE p.numero = ? ORDER BY p.fecha DESC`, [numero]);
        
        const unificados = [...servicios, ...palpaciones].sort((a,b) => new Date(b.fecha) - new Date(a.fecha));
        
        res.json({ 
            servicios: unificados, 
            total_servicios: servicios.length,
            total_palpaciones: palpaciones.length,
            unificados: unificados
        });
    } catch (e) {
        res.status(500).json({ servicios: [], total_servicios: 0, error: e.message });
    }
});

// =============================================
// API: REGISTRAR PALPACIÓN
// =============================================
app.post('/api/registrar-palpacion', async (req, res) => {
    try {
        const { fecha, numero, nombre, diagnostico, observaciones, tecnico, creado_por } = req.body;
        if (!numero || !fecha) return res.status(400).json({ success: false, error: 'Faltan datos' });

        const existePalp = await dbGet('SELECT id FROM palpaciones WHERE fecha = ? AND numero = ? AND diagnostico = ?', [fecha, numero, diagnostico || '']);
        if (existePalp) {
            return res.status(400).json({ success: false, error: `Ya existe una palpación para ${numero} en ${fecha}` });
        }

        await dbRun('INSERT INTO palpaciones (fecha, numero, diagnostico, observaciones, tecnico, creado_por, creado_en) VALUES (?,?,?,?,?,?,?)',
            [fecha, numero, diagnostico || '', observaciones || '', tecnico || '', creado_por || 'sistema', ahora()]);
        
        // Automatización: Actualizar estatus reproductivo
        let sqlRepro = 'UPDATE animales SET estatus_repro = ?';
        const diagLower = (diagnostico || '').toLowerCase();
        
        // Mapear diagnósticos comunes a estatus estandarizados
        let nuevoEstatus = diagnostico;
        if (diagLower.includes('preñada') || diagLower.includes('prenada')) nuevoEstatus = 'Preñada';
        else if (diagLower.includes('vacía') || diagLower.includes('vacia')) nuevoEstatus = 'Vacía';
        
        const valsRepro = [nuevoEstatus];
        
        if (nuevoEstatus === 'Preñada' && req.body.fecha_parto_est) {
            sqlRepro += ', fecha_parto_est = ?';
            valsRepro.push(req.body.fecha_parto_est);
        } else if (nuevoEstatus === 'Vacía') {
            sqlRepro += ', fecha_parto_est = NULL';
        }
        
        sqlRepro += ' WHERE numero = ?';
        valsRepro.push(numero);
        await dbRun(sqlRepro, valsRepro);

        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// =============================================
// API: REGISTRAR / ACTUALIZAR ANIMAL
// =============================================
app.post('/api/registrar-animal', async (req, res) => {
    try {
        const { numero, nombre, fecha_nac, sexo, raza, lote, tipo, estatus, propietario, num_madre, nom_madre, padre, peso_nacer, comentarios, foto_animal, foto_hierro, fecha_parto_est, estatus_repro } = req.body;
        if (!numero) return res.status(400).json({ success: false, error: 'Falta el numero' });

        const existe = await dbGet('SELECT numero FROM animales WHERE numero = ?', [numero]);

        if (existe) {
            let sql = 'UPDATE animales SET nombre=?, fecha_nac=?, sexo=?, raza=?, lote=?, tipo=?, estatus=?, propietario=?, num_madre=?, nom_madre=?, padre=?, peso_nacer=?, comentarios=?, estatus_repro=?';
            const vals = [nombre, fecha_nac || '', sexo || 'Hembra', raza || '', lote || '', tipo || 'Vaca', estatus || 'Vivos', propietario || '', num_madre || '', nom_madre || '', padre || '', peso_nacer || '', comentarios || '', estatus_repro || 'Vacía'];
            if (foto_animal) { sql += ', foto_animal=?'; vals.push(foto_animal); }
            if (foto_hierro) { sql += ', foto_hierro=?'; vals.push(foto_hierro); }
            if (fecha_parto_est !== undefined) { sql += ', fecha_parto_est=?'; vals.push(fecha_parto_est); }
            sql += ' WHERE numero=?';
            vals.push(numero);
            await dbRun(sql, vals);
        } else {
            await dbRun(
                'INSERT INTO animales (numero, nombre, fecha_nac, sexo, raza, lote, tipo, estatus, propietario, num_madre, nom_madre, padre, peso_nacer, comentarios, foto_animal, foto_hierro, fecha_parto_est, estatus_repro) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
                [numero, nombre || '', fecha_nac || '', sexo || 'Hembra', raza || '', lote || '', tipo || 'Vaca', estatus || 'Vivos', propietario || '', num_madre || '', nom_madre || '', padre || '', peso_nacer || '', comentarios || '', foto_animal || '', foto_hierro || '', fecha_parto_est || '', estatus_repro || 'Vacía']
            );
        }

        res.json({ success: true, accion: existe ? 'actualizado' : 'creado' });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// =============================================
// API: GUARDAR NUEVO ANIMAL (formulario basico)
// =============================================
app.post('/api/nuevo-animal', async (req, res) => {
    try {
        const { numero, nombre, sexo } = req.body;
        if (!numero || !nombre) return res.status(400).json({ success: false, error: 'Numero y nombre obligatorios' });
        await dbRun("INSERT OR IGNORE INTO animales (numero, nombre, sexo, estatus) VALUES (?,?,?,'Vivos')", [numero, nombre, sexo || 'Hembra']);
        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// =============================================
// API: REGISTRAR LECHE (individual, mantenida para compatibilidad)
// Envio: { numero, nombre, peso_tobo, peso_tobo_kg, ordeno, fecha }
// =============================================
app.post('/api/registrar-leche', async (req, res) => {
    try {
        const numero = req.body.numero;
        const nombre = req.body.nombre || '';
        const pesoTotal = parseFloat(req.body.peso_tobo) || 0;
        const pesoTobo = parseFloat(req.body.peso_tobo_kg) || 0.865;
        const bodyStr = JSON.stringify(req.body);
        const ordeno = req.body['orde\u00f1o'] || req.body['ordeno'] || req.body['turno'] ||
            (bodyStr.includes('"M"') ? 'M' : 'T') || 'M';
        const fecha = req.body.fecha || new Date().toISOString().split('T')[0];
        const creadoPor = req.body.creado_por || 'sistema';

        if (!numero) return res.status(400).json({ success: false, error: 'Falta numero' });

        const existeLeche = await dbGet('SELECT id FROM control_leche WHERE fecha = ? AND numero_animal = ? AND turno = ?', [fecha, numero, ordeno]);
        if (existeLeche) {
            return res.status(400).json({ success: false, error: `Ya existe un registro de leche para ${numero} en ${fecha} (turno ${ordeno})` });
        }

        const pesoNeto = Math.max(0, pesoTotal - pesoTobo);
        await dbRun('INSERT INTO control_leche (fecha, numero_animal, kg, turno, creado_por, creado_en) VALUES (?,?,?,?,?,?)',
            [fecha, numero, pesoNeto, ordeno, creadoPor, ahora()]);

        res.json({ success: true, peso_neto: pesoNeto, turno: ordeno });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// =============================================
// API: BORRADOR DE LECHE (pre-carga temporal)
// GET  /api/borrador-leche          → devuelve el borrador actual
// POST /api/borrador-leche          → reemplaza el borrador
// DELETE /api/borrador-leche        → borra el borrador
// =============================================
const BORRADOR_LECHE_PATH = path.join(__dirname, 'data', 'borrador_leche.json');

app.get('/api/borrador-leche', (req, res) => {
    try {
        if (fs.existsSync(BORRADOR_LECHE_PATH)) {
            const data = JSON.parse(fs.readFileSync(BORRADOR_LECHE_PATH, 'utf8'));
            res.json({ success: true, data });
        } else {
            res.json({ success: true, data: null });
        }
    } catch (e) {
        res.json({ success: true, data: null });
    }
});

app.post('/api/borrador-leche', (req, res) => {
    try {
        fs.writeFileSync(BORRADOR_LECHE_PATH, JSON.stringify(req.body, null, 2), 'utf8');
        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

app.delete('/api/borrador-leche', (req, res) => {
    try {
        if (fs.existsSync(BORRADOR_LECHE_PATH)) fs.unlinkSync(BORRADOR_LECHE_PATH);
        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// =============================================
// API: CONFIRMAR CARGA MASIVA DE LECHE
// POST /api/confirmar-leche
// Body: { fecha, turno, entradas: [{numero, nombre, kg}], creado_por }
// =============================================
app.post('/api/confirmar-leche', async (req, res) => {
    try {
        const { fecha, turno, entradas, creado_por } = req.body;
        if (!entradas || !Array.isArray(entradas) || entradas.length === 0) {
            return res.status(400).json({ success: false, error: 'No hay entradas' });
        }

        const fechaReal = fecha || new Date().toISOString().split('T')[0];
        const turnoReal = turno || 'M';
        const creadoPor = creado_por || 'sistema';

        for (const e of entradas) {
            const kg = parseFloat(e.kg) || 0;
            if (kg > 0 && e.numero) {
                const existeLeche = await dbGet('SELECT id FROM control_leche WHERE fecha = ? AND numero_animal = ? AND turno = ?', [fechaReal, e.numero, turnoReal]);
                if (existeLeche) continue;
                await dbRun(
                    'INSERT INTO control_leche (fecha, numero_animal, kg, turno, creado_por, creado_en) VALUES (?,?,?,?,?,?)',
                    [fechaReal, e.numero, kg, turnoReal, creadoPor, ahora()]
                );
            }
        }

        // Borrar borrador luego de confirmar
        if (fs.existsSync(BORRADOR_LECHE_PATH)) fs.unlinkSync(BORRADOR_LECHE_PATH);

        res.json({ success: true, total: entradas.length });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// =============================================
// API: REGISTRAR QUESO
// =============================================
app.post('/api/registrar-queso', async (req, res) => {
    try {
        const { fecha, equipo, peso_kg, leche_usada_litros, creado_por, foto_path } = req.body;
        console.log(`[QUESO] Registrando: ${fecha}, ${equipo}, ${peso_kg}kg, ${leche_usada_litros}L, foto: ${foto_path}`);
        
        if (!fecha || !peso_kg) {
            return res.status(400).json({ success: false, error: 'Faltan datos obligatorios (Fecha/Peso)' });
        }

        // VALIDACIÓN DE DUPLICADOS
        const existe = await dbGet('SELECT id FROM queso WHERE fecha = ? AND equipo = ?', [fecha, equipo || 'MAÑANA']);
        if (existe) {
            console.warn('[QUESO] Ya existe un registro para esta fecha y turno');
            return res.status(400).json({ success: false, error: `Ya existe una producción registrada para la fecha ${fecha} (${equipo})` });
        }

        await dbRun('INSERT INTO queso (fecha, equipo, peso_kg, leche_usada_litros, foto_path, creado_por, creado_en) VALUES (?,?,?,?,?,?,?)',
            [fecha, equipo || 'MAÑANA', parseFloat(peso_kg), parseFloat(leche_usada_litros) || 0, foto_path || null, creado_por || 'sistema', ahora()]);
        
        console.log('[QUESO] Guardado exitoso');
        res.json({ success: true });
    } catch (e) {
        console.error('[QUESO] Error:', e.message);
        res.status(500).json({ success: false, error: e.message });
    }
});

// =============================================
// API: REGISTRAR PARTO
// =============================================
app.post('/api/registrar-parto', async (req, res) => {
    try {
        const { fecha, num_madre, nom_madre, num_asignado, sexo_cria, sexo, peso, estado, observacion, estatus_cria, padre, creado_por } = req.body;
        if (!num_madre || !fecha) return res.status(400).json({ success: false, error: 'Faltan datos' });

        const sexoReal = sexo_cria || sexo || '';

        const existeParto = await dbGet('SELECT id FROM partos WHERE fecha = ? AND num_madre = ? AND num_asignado = ?', [fecha, num_madre, num_asignado || '']);
        if (existeParto) {
            return res.status(400).json({ success: false, error: `Ya existe un parto registrado para la madre ${num_madre} en ${fecha}` });
        }

        await dbRun('INSERT INTO partos (fecha, num_madre, num_asignado, sexo, peso, estado, observacion, estatus_cria, creado_por, creado_en) VALUES (?,?,?,?,?,?,?,?,?,?)',
            [fecha, num_madre, num_asignado || '', sexoReal, parseFloat(peso) || 0, estado || 'Vivo', observacion || '', estatus_cria || '', creado_por || 'sistema', ahora()]);

        let fichaCreada = false;
        if ((estado === 'Vivo' || estado === 'vivo') && num_asignado) {
            const existe = await dbGet('SELECT numero FROM animales WHERE numero = ?', [num_asignado]);
            // Obtener propietario de la madre
            const madre = await dbGet('SELECT propietario FROM animales WHERE numero = ?', [num_madre]);
            const propMadre = (madre && madre.propietario) ? madre.propietario : '';
            if (!existe) {
                // Generar nombre: H de [madre] o M de [madre]
                const sexUpper = (sexoReal || '').toUpperCase();
                const prefijo = (sexUpper === 'HEMBRA' || sexUpper === 'H') ? 'H' : 'M';
                const nombreCria = `${prefijo} de ${(nom_madre || num_madre)}`;
                
                await dbRun("INSERT INTO animales (numero, nombre, sexo, fecha_nac, num_madre, nom_madre, padre, estatus, lote, tipo, estatus_repro, propietario) VALUES (?,?,?,?,?,?,?,?,'Becerros','Becerros','Vacía',?)",
                    [num_asignado, nombreCria, sexoReal || 'Hembra', fecha, num_madre, nom_madre || '', padre || '', 'Vivos', propMadre]);
                fichaCreada = true;
            } else {
                await dbRun("UPDATE animales SET lote='Becerros', tipo='Becerros', propietario=? WHERE numero=?", [propMadre, num_asignado]);
            }
        }

        // Automatización: Actualizar MADRE
        // Al parir, la vaca pasa a lote 'Ordeño' y estatus repro 'En Lactancia'
        await dbRun("UPDATE animales SET lote='Ordeño', tipo='Vaca', estatus_repro='En Lactancia' WHERE numero=?", [num_madre]);

        res.json({ success: true, ficha_creada: fichaCreada });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// =============================================
// API: REGISTRAR SERVICIO
// =============================================
app.post('/api/registrar-servicio', async (req, res) => {
    try {
        const numero_vaca = req.body.numero_vaca || req.body.numero;
        const { fecha, nombre, tipo, toro, raza_toro, creado_por } = req.body;
        if (!numero_vaca || !fecha) return res.status(400).json({ success: false, error: 'Faltan datos' });

        const existeServ = await dbGet('SELECT id FROM servicios WHERE fecha = ? AND numero = ? AND tipo = ? AND toro = ?', [fecha, numero_vaca, tipo || 'Monta', toro || '']);
        if (existeServ) {
            return res.status(400).json({ success: false, error: `Ya existe un servicio registrado para ${numero_vaca} en ${fecha}` });
        }

        await dbRun('INSERT INTO servicios (fecha, numero, tipo, toro, raza_toro, creado_por, creado_en) VALUES (?,?,?,?,?,?,?)',
            [fecha, numero_vaca, tipo || 'Monta', toro || '', raza_toro || '', creado_por || 'sistema', ahora()]);
        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// =============================================
// API: REGISTRAR BAJA
// Tipos: Muerte, Venta, Robo, Sacrificio, Transferencia, Descarte
// También actualiza el estatus del animal en la tabla animales
// =============================================
app.post('/api/registrar-baja', async (req, res) => {
    try {
        const {
            fecha, numero_animal, nombre_animal, tipo_baja, causa,
            comprador, precio_total, peso_venta, guia_movilizacion,
            tiene_seguro, observaciones, creado_por
        } = req.body;

        if (!numero_animal || !tipo_baja || !fecha) {
            return res.status(400).json({ success: false, error: 'Faltan datos obligatorios (animal, tipo, fecha)' });
        }

        const existeBaja = await dbGet('SELECT id FROM bajas WHERE fecha = ? AND numero_animal = ? AND tipo_baja = ?', [fecha, numero_animal, tipo_baja]);
        if (existeBaja) {
            return res.status(400).json({ success: false, error: `Ya existe una baja de tipo "${tipo_baja}" para ${numero_animal} en ${fecha}` });
        }

        // Determinar el nuevo estatus del animal
        const MAPA_ESTATUS = {
            'Muerte': 'Muertos',
            'Venta': 'Vendidos',
            'Robo': 'Robados',
            'Sacrificio': 'Sacrificados',
            'Transferencia': 'Transferidos',
            'Descarte': 'Descartados'
        };
        const nuevoEstatus = MAPA_ESTATUS[tipo_baja] || tipo_baja;

        // Insertar en la tabla bajas
        await dbRun(
            `INSERT INTO bajas (fecha, numero_animal, tipo_baja, causa, comprador, precio_total, peso_venta, guia_movilizacion, tiene_seguro, observaciones, creado_por, creado_en)
             VALUES (?,?,?,?,?,?,?,?,?,?,?,?)`,
            [fecha, numero_animal, tipo_baja, causa || '', comprador || '',
                parseFloat(precio_total) || 0, parseFloat(peso_venta) || 0,
                guia_movilizacion || '', tiene_seguro || 'No', observaciones || '',
                creado_por || 'sistema', ahora()]
        );

        // Actualizar estatus del animal
        await dbRun('UPDATE animales SET estatus = ? WHERE numero = ?', [nuevoEstatus, numero_animal]);

        res.json({ success: true, nuevo_estatus: nuevoEstatus });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// =============================================
// API: LISTAR BAJAS (con paginación simple)
// =============================================
app.get('/api/bajas', async (req, res) => {
    try {
        const rows = await dbAll('SELECT * FROM bajas ORDER BY id DESC LIMIT 100');
        res.json({ success: true, data: rows });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// =============================================
// API: OCR - Detectar peso en imagen
// =============================================
app.post('/api/ocr-peso', upload.single('foto'), async (req, res) => {
    try {
        if (!req.file) return res.status(400).json({ error: 'No se recibio imagen' });

        if (!Tesseract) await initOCR();
        if (!Tesseract) {
            try { fs.unlinkSync(req.file.path); } catch (_) { }
            return res.json({ peso_ocr: null, error: 'OCR no disponible' });
        }

        console.log(`[OCR] Procesando archivo: ${req.file.filename}`);
        const result = await Tesseract.recognize(req.file.path, 'eng+spa', { logger: () => { } });
        const text = result.data.text;
        const numbers = text.match(/[\d]+[.,\d]*/g) || [];
        let peso = null;
        if (numbers.length > 0) {
            const parsed = numbers.map(n => parseFloat(n.replace(',', '.'))).filter(n => !isNaN(n) && n > 0 && n < 1000);
            if (parsed.length > 0) peso = Math.max(...parsed);
        }

        console.log(`[OCR] Resultado: ${peso}kg (Texto: ${text.substring(0, 50)}...)`);
        
        res.json({ peso_ocr: peso, filename: req.file.filename, texto: text.trim() });
    } catch (e) {
        if (req.file?.path) try { fs.unlinkSync(req.file.path); } catch (_) { }
        res.status(500).json({ error: e.message });
    }
});

// --- OCR SOLO (v2: Procesar archivo ya subido) ---
app.post('/api/ocr-solo', async (req, res) => {
    try {
        const { filename } = req.body;
        if (!filename) return res.status(400).json({ error: 'Falta filename' });

        const filePath = path.join(uploadDir, filename);
        if (!fs.existsSync(filePath)) return res.status(404).json({ error: 'Archivo no encontrado' });

        if (!Tesseract) await initOCR();
        if (!Tesseract) return res.json({ peso_ocr: null, error: 'OCR no disponible' });

        console.log(`[OCR-SOLO] Procesando: ${filename}`);
        const result = await Tesseract.recognize(filePath, 'eng+spa', { logger: () => { } });
        const text = result.data.text;
        const numbers = text.match(/[\d]+[.,\d]*/g) || [];
        
        let peso = null;
        if (numbers.length > 0) {
            const parsed = numbers.map(n => parseFloat(n.replace(',', '.'))).filter(n => !isNaN(n) && n > 0 && n < 1000);
            if (parsed.length > 0) peso = Math.max(...parsed);
        }

        console.log(`[OCR-SOLO] Resultado: ${peso}kg`);
        res.json({ peso_ocr: peso, texto: text.trim() });
    } catch (e) {
        console.error('[OCR-SOLO] Error:', e.message);
        res.status(500).json({ error: e.message });
    }
});

// =============================================
// API: SUBIR FOTO DEL ANIMAL
// =============================================
app.post('/api/upload-foto', upload.single('foto'), (req, res) => {
    if (!req.file) return res.status(400).json({ success: false, error: 'No se recibio foto' });
    res.json({ success: true, filename: req.file.filename });
});

// =============================================
// API: TABLAS (Panel Admin)
// =============================================
app.get('/api/tablas/:nombre', async (req, res) => {
    try {
        const PERMITIDAS = ['animales', 'control_leche', 'partos', 'servicios', 'queso', 'palpaciones'];
        const tabla = req.params.nombre;
        if (!PERMITIDAS.includes(tabla)) return res.status(400).json({ error: 'Tabla no permitida' });

        // Orden definitivo v7: rowid DESC prioriza lo más nuevo
        let orderBy = (tabla === 'animales') ? 'rowid DESC' : 'id DESC';
        if (tabla === 'animales' && req.query.col && req.query.col !== 'rowid') {
            orderBy = `${req.query.col} ASC`;
        }

        // Filtro por estatus (opcional)
        let sql;
        const params = [];
        const tables = tabla.toLowerCase();
        if (tables === 'partos') {
            sql = `SELECT p.*, (SELECT a.nombre FROM animales a WHERE a.numero = p.num_madre) as nom_madre FROM partos p`;
        } else if (tables === 'control_leche') {
            sql = `SELECT c.*, (SELECT a.nombre FROM animales a WHERE a.numero = c.numero_animal) as nombre_animal FROM control_leche c`;
        } else if (tables === 'servicios') {
            sql = `SELECT s.*, (SELECT a.nombre FROM animales a WHERE a.numero = s.numero) as nombre FROM servicios s`;
        } else if (tables === 'palpaciones') {
            sql = `SELECT p.*, (SELECT a.nombre FROM animales a WHERE a.numero = p.numero) as nombre,
                   (SELECT a.lote FROM animales a WHERE a.numero = p.numero) as lote,
                   (SELECT CASE WHEN MAX(part.fecha) IS NOT NULL THEN 
                     SUBSTR(MAX(part.fecha),9,2)||'-'||SUBSTR(MAX(part.fecha),6,2)||'-'||SUBSTR(MAX(part.fecha),1,4)||' ('||
                     CAST(CAST(julianday(p.fecha)-julianday(MAX(part.fecha)) AS INTEGER) AS TEXT)||' d'||CHAR(237)||'as)'
                   ELSE '' END FROM partos part WHERE part.num_madre = p.numero AND part.fecha <= p.fecha) as ultimo_parto
                   FROM palpaciones p`;
        } else {
            sql = `SELECT * FROM ${tabla}`;
        }
        if (req.query.estatus && req.query.estatus !== 'Todos') {
            sql += ` WHERE estatus = ?`;
            params.push(req.query.estatus);
        }
        sql += ` ORDER BY ${orderBy} LIMIT 500`;

        const rows = await dbAll(sql, params);
        res.json({ success: true, data: rows });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// =============================================
// API: EDITAR CELDA (Panel Admin)
// =============================================
app.post('/api/save-cell', async (req, res) => {
    try {
        const { tabla, id, columna, valor } = req.body;
        const PERMITIDAS = ['animales', 'control_leche', 'partos', 'servicios', 'queso', 'palpaciones'];
        if (!PERMITIDAS.includes(tabla)) return res.status(400).json({ error: 'Tabla no permitida' });

        // Determinar columna de ID (PK)
        const pkCol = (tabla === 'animales') ? 'numero' : 'id';
        await dbRun(`UPDATE ${tabla} SET ${columna} = ? WHERE ${pkCol} = ?`, [valor, id]);
        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// Borrar fila completa
app.post('/api/borrar-fila', async (req, res) => {
    try {
        const { tabla, id } = req.body;
        const PERMITIDAS = ['animales', 'control_leche', 'partos', 'servicios', 'queso', 'palpaciones'];
        if (!PERMITIDAS.includes(tabla)) return res.status(400).json({ error: 'Tabla no permitida' });
        const pkCol = (tabla === 'animales') ? 'numero' : 'id';
        await dbRun(`DELETE FROM ${tabla} WHERE ${pkCol} = ?`, [id]);
        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// =============================================
// API: AGREGAR FILA (Panel Admin)
// El index.html llama a POST /api/... con tabla en el select
// =============================================
app.post('/api/agregar-fila', async (req, res) => {
    try {
        const { tabla } = req.body;
        const PERMITIDAS = ['animales', 'control_leche', 'partos', 'servicios', 'queso', 'palpaciones'];
        if (!PERMITIDAS.includes(tabla)) return res.status(400).json({ error: 'Tabla no permitida' });
        if (tabla === 'animales') {
            await dbRun("INSERT INTO animales (numero, nombre) VALUES (?,?)", [Date.now().toString().slice(-6), '...']);
        } else {
            await dbRun(`INSERT INTO ${tabla} (creado_en) VALUES (?)`, [ahora()]);
        }
        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// =============================================
// API: TUNNEL URL (acceso remoto)
// =============================================
app.get('/api/tunnel', (req, res) => {
    res.json({ url: null });
});

// =============================================
// API: PROXIMO NUMERO DE ANIMAL
// Formato: AÑO(2dig) + CORRELATIVO(3dig)
// =============================================
app.get('/api/proximo-numero', async (req, res) => {
    try {
        const anio = req.query.anio || String(new Date().getFullYear()).slice(-2);
        const rows = await dbAll("SELECT numero FROM animales WHERE numero LIKE ?", [anio + '%']);
        let maxCorr = 0;
        rows.forEach(r => {
            if (r.numero && r.numero.startsWith(anio)) {
                const corr = parseInt(r.numero.slice(2)) || 0;
                if (corr > maxCorr) maxCorr = corr;
            }
        });
        const siguiente = anio + String(maxCorr + 1).padStart(3, '0');
        res.json({ proximo_numero: siguiente, anio, correlativo: maxCorr + 1 });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// GET Configuración Admin
app.get('/api/admin-config', (req, res) => {
    try {
        const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        res.json(config);
    } catch (e) {
        res.status(500).json({ error: 'Error al leer config' });
    }
});

// POST Guardar Configuración Admin
app.post('/api/admin-config', (req, res) => {
    try {
        const newConfig = req.body;
        fs.writeFileSync(configPath, JSON.stringify(newConfig, null, 2));
        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ error: 'Error al guardar config' });
    }
});

// =============================================
// API: CONSULTA LECHE (con filtros por fecha/vaca)
// =============================================
app.get('/api/consulta-leche', async (req, res) => {
    try {
        const { desde, hasta, vaca, turno } = req.query;
        let sql = 'SELECT * FROM control_leche WHERE 1=1';
        const params = [];
        if (desde) { sql += ' AND fecha >= ?'; params.push(desde); }
        if (hasta) { sql += ' AND fecha <= ?'; params.push(hasta); }
        if (vaca) { sql += ' AND numero_animal = ?'; params.push(vaca); }
        if (turno) { sql += ' AND turno = ?'; params.push(turno); }
        sql += ' ORDER BY fecha DESC LIMIT 1000';

        const rows = await dbAll(sql, params);
        const totalKg = rows.reduce((s, r) => s + (parseFloat(r.kg) || 0), 0);
        // Normalizar nombre de campo para compatibilidad
        const normalizados = rows.map(r => ({ ...r, nombre: r.nombre_animal || r.nombre || '', turno: r.turno || '' }));
        res.json({ registros: normalizados, total_kg: totalKg.toFixed(1), total_registros: rows.length });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// =============================================
// API: LISTA DE TOROS (unicos de servicios)
// =============================================
app.get('/api/toros', async (req, res) => {
    try {
        // servicios tiene columna 'numero' no 'numero_vaca'
        const rows = await dbAll("SELECT DISTINCT toro, raza_toro FROM servicios WHERE toro IS NOT NULL AND toro != '' ORDER BY toro");
        res.json(rows);
    } catch (e) {
        res.status(500).json([]);
    }
});

// =============================================
// SPA fallback - toda ruta sirve el index.html
// =============================================
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// =============================================
// INICIO DEL SERVIDOR
// =============================================
async function iniciar() {
    await crearTablas();
    await crearAdminPorDefecto();
    await initOCR();

    app.listen(PORT, '0.0.0.0', () => {
        const nets = os.networkInterfaces();
        let localIP = 'localhost';
        let tailscaleIP = '';
        
        for (const name of Object.keys(nets)) {
            for (const net of nets[name]) {
                if (net.family === 'IPv4' && !net.internal) {
                    if (name.toLowerCase().includes('tailscale') || net.address.startsWith('100.')) {
                        tailscaleIP = net.address;
                    } else {
                        localIP = net.address;
                    }
                }
            }
        }

        console.log('');
        console.log('  =============================================');
        console.log('  SERVIDOR SISGAN PRO ACTIVO');
        console.log('  =============================================');
        console.log('  URL LOCAL:     http://localhost:' + PORT);
        console.log('  URL WIFI:      http://' + (localIP || '---') + ':' + PORT);
        
        if (tailscaleIP) {
            console.log('  URL TAILSCALE: http://' + tailscaleIP + ':' + PORT + ' (Acceso Remoto)');
        }
        
        console.log('  =============================================');
        console.log('  Usuario: admin');
        console.log('  Clave:   admin123');
        console.log('  =============================================');
    });
}

iniciar().catch(err => {
    console.error('ERROR FATAL:', err.message);
    process.exit(1);
});
