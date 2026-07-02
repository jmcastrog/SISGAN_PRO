const express = require('express');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const multer = require('multer');
const sqlite3 = require('sqlite3').verbose();

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
        control_leche: { visible: ['fecha', 'numero_animal', 'nombre_animal', 'kg', 'turno'], order: ['fecha', 'numero_animal', 'nombre_animal', 'kg', 'turno'] },
        partos: { visible: ['fecha', 'num_madre', 'nom_madre', 'num_asignado', 'sexo', 'peso'], order: ['fecha', 'num_madre', 'nom_madre', 'num_asignado', 'sexo', 'peso'] },
        servicios: { visible: ['fecha', 'numero', 'nombre', 'toro', 'raza_toro'], order: ['fecha', 'numero', 'nombre', 'toro', 'raza_toro'] },
        queso: { visible: ['fecha', 'equipo', 'peso_kg'], order: ['fecha', 'equipo', 'peso_kg'] },
        palpaciones: { visible: ['fecha', 'numero', 'nombre', 'diagnostico', 'observaciones', 'tecnico'], order: ['fecha', 'numero', 'nombre', 'diagnostico', 'observaciones', 'tecnico'] }
    };
    fs.writeFileSync(configPath, JSON.stringify(defaultConfig, null, 2));
}

// --- BASE DE DATOS (sqlite3 nativo) ---
const dbPath = path.join(__dirname, 'data', 'sisgan_pro.db');
const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('  ERROR abriendo base de datos:', err.message);
        process.exit(1);
    }
    console.log('  Base de datos: OK (' + dbPath + ')');
});

// Usar modo WAL para mejor rendimiento
db.run('PRAGMA journal_mode=WAL');
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
        numero TEXT PRIMARY KEY,
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
        peso_nacer TEXT,
        comentarios TEXT,
        foto_animal TEXT,
        foto_hierro TEXT,
        fecha_parto_est TEXT
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
// API: DASHBOARD
// Espera: { animales, leche_hoy, proximos[] }
// =============================================
app.get('/api/dashboard', async (req, res) => {
    try {
        const hoy = new Date().toISOString().split('T')[0];

        const r1 = await dbGet("SELECT COUNT(*) as c FROM animales WHERE estatus = 'Vivos'");
        const totalAnimales = r1?.c || 0;

        const r2 = await dbGet("SELECT SUM(kg) as total FROM control_leche WHERE fecha = ?", [hoy]);
        const lecheHoy = parseFloat(r2?.total) || 0;

        // Proximos partos (en los proximos 60 dias)
        const limite = new Date();
        limite.setDate(limite.getDate() + 60);
        const limiteStr = limite.toISOString().split('T')[0];
        const proximos = await dbAll(
            "SELECT numero, nombre, fecha_parto_est FROM animales WHERE fecha_parto_est >= ? AND fecha_parto_est <= ? ORDER BY fecha_parto_est ASC LIMIT 10",
            [hoy, limiteStr]
        );

        res.json({ animales: totalAnimales, leche_hoy: lecheHoy, proximos });
    } catch (e) {
        res.status(500).json({ animales: 0, leche_hoy: 0, proximos: [], error: e.message });
    }
});

// =============================================
// API: LISTA ANIMALES para buscador
// Espera: [{ numero, nombre, estatus }]
// =============================================
app.get('/api/animales-produccion', async (req, res) => {
    try {
        const rows = await dbAll("SELECT numero, nombre, estatus FROM animales ORDER BY numero");
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
        const partos = await dbAll('SELECT * FROM partos WHERE num_madre = ? ORDER BY fecha DESC', [req.params.numero]);

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
        const rows = await dbAll('SELECT * FROM control_leche WHERE numero_animal = ? ORDER BY fecha DESC', [req.params.numero]);
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
// API: SERVICIOS DE UN ANIMAL
// =============================================
app.get('/api/servicios/:numero', async (req, res) => {
    try {
        // La BD usa columna 'numero' en servicios
        const rows = await dbAll('SELECT * FROM servicios WHERE numero = ? ORDER BY fecha DESC', [req.params.numero]);
        res.json({ servicios: rows, total_servicios: rows.length });
    } catch (e) {
        res.status(500).json({ servicios: [], total_servicios: 0, error: e.message });
    }
});

// =============================================
// API: REGISTRAR / ACTUALIZAR ANIMAL
// =============================================
app.post('/api/registrar-animal', async (req, res) => {
    try {
        const { numero, nombre, raza, lote, tipo, estatus, propietario, num_madre, padre, comentarios, foto_animal, foto_hierro, fecha_parto_est } = req.body;
        if (!numero) return res.status(400).json({ success: false, error: 'Falta el numero' });

        const existe = await dbGet('SELECT numero FROM animales WHERE numero = ?', [numero]);

        if (existe) {
            let sql = 'UPDATE animales SET nombre=?, raza=?, lote=?, tipo=?, estatus=?, propietario=?, num_madre=?, padre=?, comentarios=?';
            const vals = [nombre, raza || '', lote || '', tipo || 'Vaca', estatus || 'Vivos', propietario || '', num_madre || '', padre || '', comentarios || ''];
            if (foto_animal) { sql += ', foto_animal=?'; vals.push(foto_animal); }
            if (foto_hierro) { sql += ', foto_hierro=?'; vals.push(foto_hierro); }
            if (fecha_parto_est !== undefined) { sql += ', fecha_parto_est=?'; vals.push(fecha_parto_est); }
            sql += ' WHERE numero=?';
            vals.push(numero);
            await dbRun(sql, vals);
        } else {
            await dbRun(
                'INSERT INTO animales (numero, nombre, raza, lote, tipo, estatus, propietario, num_madre, padre, comentarios, foto_animal, foto_hierro, fecha_parto_est) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)',
                [numero, nombre || '', raza || '', lote || '', tipo || 'Vaca', estatus || 'Vivos', propietario || '', num_madre || '', padre || '', comentarios || '', foto_animal || '', foto_hierro || '', fecha_parto_est || '']
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
// API: REGISTRAR LECHE
// Envio: { numero, nombre, peso_tobo, peso_tobo_kg, ordeno, fecha }
// =============================================
app.post('/api/registrar-leche', async (req, res) => {
    try {
        const numero = req.body.numero;
        const nombre = req.body.nombre || '';
        const pesoTotal = parseFloat(req.body.peso_tobo) || 0;
        const pesoTobo = parseFloat(req.body.peso_tobo_kg) || 0.865;
        // El campo 'ordeño' viene con ñ desde el frontend - buscamos todas las variantes
        const bodyStr = JSON.stringify(req.body);
        const ordeno = req.body['orde\u00f1o'] || req.body['ordeno'] || req.body['turno'] ||
            (bodyStr.includes('"M"') ? 'M' : 'T') || 'M';
        const fecha = req.body.fecha || new Date().toISOString().split('T')[0];
        const creadoPor = req.body.creado_por || 'sistema';

        if (!numero) return res.status(400).json({ success: false, error: 'Falta numero' });

        const pesoNeto = Math.max(0, pesoTotal - pesoTobo);
        // nombre_animal es el nombre de la columna real en la BD
        await dbRun('INSERT INTO control_leche (fecha, numero_animal, nombre_animal, kg, turno, creado_por, creado_en) VALUES (?,?,?,?,?,?,?)',
            [fecha, numero, nombre, pesoNeto, ordeno, creadoPor, ahora()]);

        res.json({ success: true, peso_neto: pesoNeto, turno: ordeno });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// =============================================
// API: REGISTRAR QUESO
// =============================================
app.post('/api/registrar-queso', async (req, res) => {
    try {
        const { fecha, equipo, peso_kg, producto, creado_por } = req.body;
        if (!peso_kg) return res.status(400).json({ success: false, error: 'Falta el peso' });

        const fechaReg = fecha || new Date().toISOString().split('T')[0];
        // La BD usa foto_path en lugar de producto
        await dbRun('INSERT INTO queso (fecha, equipo, peso_kg, creado_por, creado_en) VALUES (?,?,?,?,?)',
            [fechaReg, equipo || 'MAÑANA', parseFloat(peso_kg), creado_por || 'sistema', ahora()]);
        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ success: false, error: e.message });
    }
});

// =============================================
// API: REGISTRAR PARTO
// =============================================
app.post('/api/registrar-parto', async (req, res) => {
    try {
        const { fecha, num_madre, nom_madre, num_asignado, sexo_cria, sexo, peso, estado, observacion, estatus_cria, creado_por } = req.body;
        if (!num_madre || !fecha) return res.status(400).json({ success: false, error: 'Faltan datos' });

        // La BD usa: num_madre, nom_madre, sexo (no sexo_cria, no numero_vaca)
        const sexoReal = sexo_cria || sexo || '';
        await dbRun('INSERT INTO partos (fecha, num_madre, nom_madre, num_asignado, sexo, peso, estado, observacion, estatus_cria, creado_por, creado_en) VALUES (?,?,?,?,?,?,?,?,?,?,?)',
            [fecha, num_madre, nom_madre || '', num_asignado || '', sexoReal, parseFloat(peso) || 0, estado || 'Vivo', observacion || '', estatus_cria || '', creado_por || 'sistema', ahora()]);

        let fichaCreada = false;
        if (estado === 'Vivo' && num_asignado) {
            const existe = await dbGet('SELECT numero FROM animales WHERE numero = ?', [num_asignado]);
            if (!existe) {
                await dbRun("INSERT INTO animales (numero, nombre, sexo, fecha_nac, num_madre, nom_madre, estatus) VALUES (?,?,?,?,?,?,'Vivos')",
                    [num_asignado, 'CRIA ' + num_asignado, sexoReal || 'Hembra', fecha, num_madre, nom_madre || '']);
                fichaCreada = true;
            }
        }

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
        // La BD usa 'numero' como FK al animal (no 'numero_vaca')
        const numero_vaca = req.body.numero_vaca || req.body.numero;
        const { fecha, nombre, tipo, toro, raza_toro, creado_por } = req.body;
        if (!numero_vaca || !fecha) return res.status(400).json({ success: false, error: 'Faltan datos' });

        await dbRun('INSERT INTO servicios (fecha, numero, nombre, tipo, toro, raza_toro, creado_por, creado_en) VALUES (?,?,?,?,?,?,?,?)',
            [fecha, numero_vaca, nombre || '', tipo || 'Monta', toro || '', raza_toro || '', creado_por || 'sistema', ahora()]);
        res.json({ success: true });
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

        const result = await Tesseract.recognize(req.file.path, 'eng+spa', { logger: () => { } });
        const text = result.data.text;
        const numbers = text.match(/[\d]+[.,\d]*/g) || [];
        let peso = null;
        if (numbers.length > 0) {
            const parsed = numbers.map(n => parseFloat(n.replace(',', '.'))).filter(n => !isNaN(n) && n > 0 && n < 1000);
            if (parsed.length > 0) peso = Math.max(...parsed);
        }

        try { fs.unlinkSync(req.file.path); } catch (_) { }
        res.json({ peso_ocr: peso, texto: text.trim() });
    } catch (e) {
        if (req.file?.path) try { fs.unlinkSync(req.file.path); } catch (_) { }
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
        let sql = `SELECT * FROM ${tabla}`;
        const params = [];
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
        const { desde, hasta, vaca } = req.query;
        let sql = 'SELECT * FROM control_leche WHERE 1=1';
        const params = [];
        if (desde) { sql += ' AND fecha >= ?'; params.push(desde); }
        if (hasta) { sql += ' AND fecha <= ?'; params.push(hasta); }
        if (vaca) { sql += ' AND numero_animal = ?'; params.push(vaca); }
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

    app.listen(PORT, () => {
        console.log('');
        console.log('  SERVIDOR ACTIVO EN PUERTO: ' + PORT);
        console.log('  URL: http://localhost:' + PORT);
        console.log('');
        console.log('  Usuario: admin');
        console.log('  Clave:   admin123');
        console.log('');
        console.log('=============================================');
    });
}

iniciar().catch(err => {
    console.error('ERROR FATAL:', err.message);
    process.exit(1);
});
