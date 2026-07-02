const express = require('express');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const multer = require('multer');
const sqlite3 = require('sqlite3').verbose();
const jwt = require('jsonwebtoken');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const app = express();
const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET || 'sisgan-pro-secret-key-v2';

app.use(helmet());
app.use(express.json({ limit: '50mb' }));
app.use(express.static(path.join(__dirname, 'public')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use(logPeticion);

const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    message: { success: false, error: 'Demasiadas solicitudes, espere' }
});
app.use('/api/', limiter);

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

function hashPasswordSecure(p) {
    const salt = crypto.randomBytes(16).toString('hex');
    const hash = crypto.createHash('sha256').update(p + salt).digest('hex');
    return `${salt}:${hash}`;
}

function verifyPassword(password, storedHash) {
    const [salt, hash] = storedHash.split(':');
    return crypto.createHash('sha256').update(password + salt).digest('hex') === hash;
}

function generarToken(user) {
    return jwt.sign(
        { id: user.id, user: user.usuario, nombre: user.nombre, rol: user.rol },
        JWT_SECRET,
        { expiresIn: '24h' }
    );
}

function verificarToken(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ success: false, error: 'Token requerido' });
    }
    
    try {
        const token = authHeader.substring(7);
        const decoded = jwt.verify(token, JWT_SECRET);
        req.user = decoded;
        next();
    } catch (e) {
        return res.status(401).json({ success: false, error: 'Token inválido o expirado' });
    }
}

function logPeticion(req, res, next) {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] ${req.method} ${req.path}`);
    next();
}

function validarNumero(numero) {
    return numero && typeof numero === 'string' && numero.trim().length > 0;
}

function validarTexto(texto) {
    return texto && typeof texto === 'string' && texto.trim().length > 0;
}

function validarNumeroPositivo(num) {
    const n = parseFloat(num);
    return !isNaN(n) && n > 0;
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

    try { await dbRun('ALTER TABLE animales ADD COLUMN estatus_repro TEXT DEFAULT \'Vacía\''); } catch (_) { }

    console.log('  Tablas: OK');
}

async function crearAdminPorDefecto() {
    const admin = await dbGet("SELECT * FROM usuarios WHERE usuario='admin'");
    if (!admin) {
        const passHash = hashPasswordSecure('admin123');
        await dbRun('INSERT INTO usuarios (usuario, password, nombre, rol, activo) VALUES (?,?,?,?,1)',
            ['admin', passHash, 'Administrador', 'admin']);
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
        
        if (verifyPassword(password, user.password)) {
            const token = generarToken(user);
            res.json({ success: true, token });
        } else {
            res.status(401).json({ success: false, error: 'Contraseña incorrecta' });
        }
    } catch (e) {
        console.error('Error login:', e.message);
        res.status(500).json({ success: false, error: 'Error al procesar login' });
    }
});

// =============================================
// Middleware de autenticación para APIs protegidas
// =============================================
function protegerApi(req, res, next) {
    if (req.path === '/api/login' || req.path === '/api/configuraciones/:clave' || req.path === '/api/admin-config') {
        return next();
    }
    return verificarToken(req, res, next);
}

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
        console.error('Error config GET:', e.message);
        res.status(500).json({ success: false, error: 'Error al obtener configuración' });
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
        console.error('Error config POST:', e.message);
        res.status(500).json({ success: false, error: 'Error al guardar configuración' });
    }
});

// =============================================
// API: DASHBOARD
// Espera: { animales, leche_hoy, proximos[] }
// =============================================
app.get('/api/dashboard', protegerApi, async (req, res) => {
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
        console.error('Error dashboard:', e.message);
        res.status(500).json({ animales: 0, leche_hoy: 0, proximos: [], error: 'Error al cargar dashboard' });
    }
});

// =============================================
// API: LISTA ANIMALES para buscador
// Espera: [{ numero, nombre, estatus }]
// =============================================
app.get('/api/animales-produccion', protegerApi, async (req, res) => {
    try {
        const rows = await dbAll("SELECT numero, nombre, estatus, lote, tipo FROM animales ORDER BY numero");
        res.json(rows);
    } catch (e) {
        console.error('Error animales-produccion:', e.message);
        res.status(500).json([]);
    }
});

// =============================================
// API: DETALLE DEL ANIMAL
// =============================================
app.get('/api/detalle/:numero', protegerApi, async (req, res) => {
    try {
        if (!validarNumero(req.params.numero)) {
            return res.status(400).json({ error: 'Número inválido' });
        }

        const animal = await dbGet('SELECT * FROM animales WHERE numero = ?', [req.params.numero]);
        if (!animal) return res.status(404).json({ error: 'Animal no encontrado' });

        if (animal.fecha_nac) {
            const nac = new Date(animal.fecha_nac + 'T12:00:00');
            const diffDays = Math.floor((new Date() - nac) / 86400000);
            const anos = Math.floor(diffDays / 365);
            const meses = Math.floor((diffDays % 365) / 30);
            animal.edad = `${anos} años, ${meses} meses`;
        } else {
            animal.edad = '-';
        }
        res.json(animal);
    } catch (e) {
        console.error('Error detalle:', e.message);
        res.status(500).json({ error: 'Error al obtener detalle' });
    }
});

// =============================================
// API: PARTOS DE UN ANIMAL
// Espera: { partos[], total_partos, intervalo_partos }
// =============================================
app.get('/api/partos/:numero', protegerApi, async (req, res) => {
    try {
        if (!validarNumero(req.params.numero)) {
            return res.status(400).json({ partos: [], total_partos: 0, intervalo_partos: 'N/A', error: 'Número inválido' });
        }

        const partos = await dbAll('SELECT * FROM partos WHERE num_madre = ? ORDER BY fecha DESC', [req.params.numero]);

        let intervalo_partos = 'N/A';
        if (partos.length >= 2) {
            const d1 = new Date(partos[0].fecha + 'T12:00:00');
            const d2 = new Date(partos[1].fecha + 'T12:00:00');
            const dias = Math.abs(Math.round((d1 - d2) / 86400000));
            intervalo_partos = `${dias} días (${(dias / 30.44).toFixed(1)} meses)`;
        }

        const partosNormalizados = partos.map(p => ({
            ...p,
            numero_vaca: p.num_madre,
            nombre_madre: p.nom_madre,
            sexo_cria: p.sexo,
            num_asignado: p.num_asignado
        }));

        res.json({ partos: partosNormalizados, total_partos: partos.length, intervalo_partos });
    } catch (e) {
        console.error('Error partos:', e.message);
        res.status(500).json({ partos: [], total_partos: 0, intervalo_partos: 'N/A', error: 'Error al obtener partos' });
    }
});

// =============================================
// API: HISTORIAL LECHE DE UN ANIMAL
// =============================================
app.get('/api/leche/:numero', protegerApi, async (req, res) => {
    try {
        if (!validarNumero(req.params.numero)) {
            return res.status(400).json([]);
        }

        const rows = await dbAll('SELECT * FROM control_leche WHERE numero_animal = ? ORDER BY fecha DESC', [req.params.numero]);
        const normalizados = rows.map(r => ({
            ...r,
            turno: r.turno || '',
            kg: parseFloat(r.kg) || 0
        }));
        res.json(normalizados);
    } catch (e) {
        console.error('Error leche:', e.message);
        res.status(500).json([]);
    }
});

// =============================================
// API: SERVICIOS / PALPACIONES DE UN ANIMAL
// =============================================
app.get('/api/servicios/:numero', protegerApi, async (req, res) => {
    try {
        if (!validarNumero(req.params.numero)) {
            return res.status(400).json({ servicios: [], total_servicios: 0, error: 'Número inválido' });
        }

        const numero = req.params.numero;
        const servicios = await dbAll('SELECT *, "Servicio" as origen FROM servicios WHERE numero = ? ORDER BY fecha DESC', [numero]);
        const palpaciones = await dbAll('SELECT *, "Palpación" as origen FROM palpaciones WHERE numero = ? ORDER BY fecha DESC', [numero]);
        
        const unificados = [...servicios, ...palpaciones].sort((a,b) => new Date(b.fecha) - new Date(a.fecha));
        
        res.json({ 
            servicios: unificados, 
            total_servicios: servicios.length,
            total_palpaciones: palpaciones.length,
            unificados: unificados
        });
    } catch (e) {
        console.error('Error servicios:', e.message);
        res.status(500).json({ servicios: [], total_servicios: 0, error: 'Error al obtener servicios' });
    }
});

// =============================================
// API: REGISTRAR PALPACIÓN
// =============================================
app.post('/api/registrar-palpacion', protegerApi, async (req, res) => {
    try {
        const { fecha, numero, nombre, diagnostico, observaciones, tecnico, creado_por } = req.body;
        
        if (!validarNumero(numero)) return res.status(400).json({ success: false, error: 'Número inválido' });
        if (!validarTexto(fecha)) return res.status(400).json({ success: false, error: 'Fecha inválida' });

        await dbRun('INSERT INTO palpaciones (fecha, numero, nombre, diagnostico, observaciones, tecnico, creado_por, creado_en) VALUES (?,?,?,?,?,?,?,?)',
            [fecha, numero, nombre || '', diagnostico || '', observaciones || '', tecnico || '', creado_por || 'sistema', ahora()]);
        
        const diagLower = (diagnostico || '').toLowerCase();
        let nuevoEstatus = 'Vacía';
        if (diagLower.includes('preñada') || diagLower.includes('prenada')) nuevoEstatus = 'Preñada';
        
        let sqlRepro = 'UPDATE animales SET estatus_repro = ?';
        const valsRepro = [nuevoEstatus];
        
        if (nuevoEstatus === 'Preñada' && req.body.fecha_parto_est && validarTexto(req.body.fecha_parto_est)) {
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
        console.error('Error registrar-palpacion:', e.message);
        res.status(500).json({ success: false, error: 'Error al registrar palpación' });
    }
});

// =============================================
// API: REGISTRAR / ACTUALIZAR ANIMAL
// =============================================
app.post('/api/registrar-animal', protegerApi, async (req, res) => {
    try {
        const { numero, nombre, fecha_nac, sexo, raza, lote, tipo, estatus, propietario, num_madre, nom_madre, padre, peso_nacer, comentarios, foto_animal, foto_hierro, fecha_parto_est, estatus_repro } = req.body;
        
        if (!validarNumero(numero)) return res.status(400).json({ success: false, error: 'Número inválido' });

        const existe = await dbGet('SELECT numero FROM animales WHERE numero = ?', [numero]);

        if (existe) {
            let sql = 'UPDATE animales SET nombre=?, fecha_nac=?, sexo=?, raza=?, lote=?, tipo=?, estatus=?, propietario=?, num_madre=?, nom_madre=?, padre=?, peso_nacer=?, comentarios=?, estatus_repro=?';
            const vals = [nombre || '', fecha_nac || '', sexo || 'Hembra', raza || '', lote || '', tipo || 'Vaca', estatus || 'Vivos', propietario || '', num_madre || '', nom_madre || '', padre || '', peso_nacer || '', comentarios || '', estatus_repro || 'Vacía'];
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
        console.error('Error registrar-animal:', e.message);
        res.status(500).json({ success: false, error: 'Error al registrar animal' });
    }
});

// =============================================
// API: GUARDAR NUEVO ANIMAL (formulario basico)
// =============================================
app.post('/api/nuevo-animal', protegerApi, async (req, res) => {
    try {
        const { numero, nombre, sexo } = req.body;
        if (!validarNumero(numero) || !validarTexto(nombre)) {
            return res.status(400).json({ success: false, error: 'Número y nombre son obligatorios' });
        }
        await dbRun("INSERT OR IGNORE INTO animales (numero, nombre, sexo, estatus) VALUES (?,?,?,'Vivos')", [numero, nombre, sexo || 'Hembra']);
        res.json({ success: true });
    } catch (e) {
        console.error('Error nuevo-animal:', e.message);
        res.status(500).json({ success: false, error: 'Error al crear animal' });
    }
});

// =============================================
// API: REGISTRAR LECHE (individual, mantenida para compatibilidad)
// Envio: { numero, nombre, peso_tobo, peso_tobo_kg, ordeno, fecha }
// =============================================
app.post('/api/registrar-leche', protegerApi, async (req, res) => {
    try {
        const numero = req.body.numero;
        const nombre = req.body.nombre || '';
        const pesoTotal = parseFloat(req.body.peso_tobo) || 0;
        const pesoTobo = parseFloat(req.body.peso_tobo_kg) || 0.865;
        const fecha = req.body.fecha || new Date().toISOString().split('T')[0];
        const creadoPor = req.body.creado_por || 'sistema';

        if (!validarNumero(numero)) return res.status(400).json({ success: false, error: 'Número inválido' });

        const pesoNeto = Math.max(0, pesoTotal - pesoTobo);
        await dbRun('INSERT INTO control_leche (fecha, numero_animal, nombre_animal, kg, turno, creado_por, creado_en) VALUES (?,?,?,?,?,?,?)',
            [fecha, numero, nombre, pesoNeto, 'M', creadoPor, ahora()]);

        res.json({ success: true, peso_neto: pesoNeto, turno: 'M' });
    } catch (e) {
        console.error('Error registrar-leche:', e.message);
        res.status(500).json({ success: false, error: 'Error al registrar leche' });
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
app.post('/api/confirmar-leche', protegerApi, async (req, res) => {
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
                await dbRun(
                    'INSERT INTO control_leche (fecha, numero_animal, nombre_animal, kg, turno, creado_por, creado_en) VALUES (?,?,?,?,?,?,?)',
                    [fechaReal, e.numero, e.nombre || '', kg, turnoReal, creadoPor, ahora()]
                );
            }
        }

        if (fs.existsSync(BORRADOR_LECHE_PATH)) fs.unlinkSync(BORRADOR_LECHE_PATH);

        res.json({ success: true, total: entradas.length });
    } catch (e) {
        console.error('Error confirmar-leche:', e.message);
        res.status(500).json({ success: false, error: 'Error al confirmar leche' });
    }
});

// =============================================
// API: REGISTRAR QUESO
// =============================================
app.post('/api/registrar-queso', protegerApi, async (req, res) => {
    try {
        const { fecha, equipo, peso_kg, producto, creado_por } = req.body;
        
        if (!validarNumeroPositivo(peso_kg)) {
            return res.status(400).json({ success: false, error: 'Peso inválido' });
        }

        const fechaReg = fecha || new Date().toISOString().split('T')[0];
        await dbRun('INSERT INTO queso (fecha, equipo, peso_kg, creado_por, creado_en) VALUES (?,?,?,?,?)',
            [fechaReg, equipo || 'MAÑANA', parseFloat(peso_kg), creado_por || 'sistema', ahora()]);
        res.json({ success: true });
    } catch (e) {
        console.error('Error registrar-queso:', e.message);
        res.status(500).json({ success: false, error: 'Error al registrar queso' });
    }
});

// =============================================
// API: INFO DEL SISTEMA
// =============================================
app.get('/api/info', (req, res) => {
    res.json({
        version: '2.0.0',
        features: ['OCR', 'Rate Limiting', 'Helmet Security', 'JWT Auth', 'Data Validation'],
        api: '/api/'
    });
});

// =============================================
// API: REGISTRAR PARTO
// =============================================
app.post('/api/registrar-parto', protegerApi, async (req, res) => {
    try {
        const { fecha, num_madre, nom_madre, num_asignado, sexo_cria, sexo, peso, estado, observacion, estatus_cria, padre, creado_por } = req.body;
        
        if (!validarNumero(num_madre) || !validarTexto(fecha)) {
            return res.status(400).json({ success: false, error: 'Datos inválidos (madre y fecha obligatorios)' });
        }

        const sexoReal = sexo_cria || sexo || '';
        await dbRun('INSERT INTO partos (fecha, num_madre, nom_madre, num_asignado, sexo, peso, estado, observacion, estatus_cria, creado_por, creado_en) VALUES (?,?,?,?,?,?,?,?,?,?,?)',
            [fecha, num_madre, nom_madre || '', num_asignado || '', sexoReal, parseFloat(peso) || 0, estado || 'Vivo', observacion || '', estatus_cria || '', creado_por || 'sistema', ahora()]);

        let fichaCreada = false;
        if ((estado === 'Vivo' || estado === 'vivo') && num_asignado) {
            const existe = await dbGet('SELECT numero FROM animales WHERE numero = ?', [num_asignado]);
            if (!existe) {
                const sexUpper = (sexoReal || '').toUpperCase();
                const prefijo = (sexUpper === 'HEMBRA' || sexUpper === 'H') ? 'H' : 'M';
                const nombreCria = `${prefijo} de ${(nom_madre || num_madre)}`;
                const tipoCria = (prefijo === 'H') ? 'Becerra' : 'Becerro';
                
                await dbRun("INSERT INTO animales (numero, nombre, sexo, fecha_nac, num_madre, nom_madre, padre, estatus, lote, tipo, estatus_repro) VALUES (?,?,?,?,?,?,?,?,'Crías',?, 'Vacía')",
                    [num_asignado, nombreCria, sexoReal || 'Hembra', fecha, num_madre, nom_madre || '', padre || '', 'Vivos', tipoCria]);
                fichaCreada = true;
            } else {
                const sexUpper = (sexoReal || '').toUpperCase();
                const tipoCria = (sexUpper === 'HEMBRA' || sexUpper === 'H') ? 'Becerra' : 'Becerro';
                await dbRun("UPDATE animales SET lote='Crías', tipo=? WHERE numero=?", [tipoCria, num_asignado]);
            }
        }

        await dbRun("UPDATE animales SET lote='Ordeño', tipo='Vaca', estatus_repro='En Lactancia' WHERE numero=?", [num_madre]);

        res.json({ success: true, ficha_creada: fichaCreada });
    } catch (e) {
        console.error('Error registrar-parto:', e.message);
        res.status(500).json({ success: false, error: 'Error al registrar parto' });
    }
});

// =============================================
// API: REGISTRAR SERVICIO
// =============================================
app.post('/api/registrar-servicio', protegerApi, async (req, res) => {
    try {
        const numero_vaca = req.body.numero_vaca || req.body.numero;
        const { fecha, nombre, tipo, toro, raza_toro, creado_por } = req.body;
        
        if (!validarNumero(numero_vaca) || !validarTexto(fecha)) {
            return res.status(400).json({ success: false, error: 'Datos inválidos (vaca y fecha obligatorios)' });
        }

        await dbRun('INSERT INTO servicios (fecha, numero, nombre, tipo, toro, raza_toro, creado_por, creado_en) VALUES (?,?,?,?,?,?,?,?)',
            [fecha, numero_vaca, nombre || '', tipo || 'Monta', toro || '', raza_toro || '', creado_por || 'sistema', ahora()]);
        res.json({ success: true });
    } catch (e) {
        console.error('Error registrar-servicio:', e.message);
        res.status(500).json({ success: false, error: 'Error al registrar servicio' });
    }
});

// =============================================
// API: CREAR USUARIO ADMIN
// =============================================
app.post('/api/crear-admin', async (req, res) => {
    try {
        const { usuario, password } = req.body;
        if (!usuario || !password) {
            return res.status(400).json({ success: false, error: 'Usuario y password son obligatorios' });
        }
        
        if (usuario.length < 4 || password.length < 4) {
            return res.status(400).json({ success: false, error: 'Usuario y password deben tener al menos 4 caracteres' });
        }
        
        const existe = await dbGet('SELECT * FROM usuarios WHERE usuario = ?', [usuario]);
        if (existe) {
            return res.status(400).json({ success: false, error: 'El usuario ya existe' });
        }
        
        await dbRun('INSERT INTO usuarios (usuario, password, nombre, rol, activo) VALUES (?,?,?,?,1)',
            [usuario, hashPasswordSecure(password), 'Administrador', 'admin']);
        res.json({ success: true, message: 'Usuario creado exitosamente' });
    } catch (e) {
        console.error('Error crear-admin:', e.message);
        res.status(500).json({ success: false, error: 'Error al crear usuario' });
    }
});

// =============================================
// API: REGISTRAR BAJA
// Tipos: Muerte, Venta, Robo, Sacrificio, Transferencia, Descarte
// También actualiza el estatus del animal en la tabla animales
// =============================================
app.post('/api/registrar-baja', protegerApi, async (req, res) => {
    try {
        const {
            fecha, numero_animal, nombre_animal, tipo_baja, causa,
            comprador, precio_total, peso_venta, guia_movilizacion,
            tiene_seguro, observaciones, creado_por
        } = req.body;

        if (!validarNumero(numero_animal) || !validarTexto(tipo_baja) || !validarTexto(fecha)) {
            return res.status(400).json({ success: false, error: 'Faltan datos obligatorios (animal, tipo, fecha)' });
        }

        const MAPA_ESTATUS = {
            'Muerte': 'Muertos',
            'Venta': 'Vendidos',
            'Robo': 'Robados',
            'Sacrificio': 'Sacrificados',
            'Transferencia': 'Transferidos',
            'Descarte': 'Descartados'
        };
        const nuevoEstatus = MAPA_ESTATUS[tipo_baja] || tipo_baja;

        await dbRun(
            `INSERT INTO bajas (fecha, numero_animal, nombre_animal, tipo_baja, causa, comprador, precio_total, peso_venta, guia_movilizacion, tiene_seguro, observaciones, creado_por, creado_en)
             VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)`,
            [fecha, numero_animal, nombre_animal || '', tipo_baja, causa || '', comprador || '',
                parseFloat(precio_total) || 0, parseFloat(peso_venta) || 0,
                guia_movilizacion || '', tiene_seguro || 'No', observaciones || '',
                creado_por || 'sistema', ahora()]
        );

        await dbRun('UPDATE animales SET estatus = ? WHERE numero = ?', [nuevoEstatus, numero_animal]);

        res.json({ success: true, nuevo_estatus: nuevoEstatus });
    } catch (e) {
        console.error('Error registrar-baja:', e.message);
        res.status(500).json({ success: false, error: 'Error al registrar baja' });
    }
});

// =============================================
// API: LISTAR BAJAS (con paginación simple)
// =============================================
app.get('/api/bajas', protegerApi, async (req, res) => {
    try {
        const rows = await dbAll('SELECT * FROM bajas ORDER BY id DESC LIMIT 100');
        res.json({ success: true, data: rows });
    } catch (e) {
        console.error('Error bajas:', e.message);
        res.status(500).json({ success: false, error: 'Error al listar bajas' });
    }
});

// =============================================
// API: OCR - Detectar peso en imagen
// =============================================
app.post('/api/ocr-peso', protegerApi, upload.single('foto'), async (req, res) => {
    try {
        if (!req.file) return res.status(400).json({ error: 'No se recibió imagen' });

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
        console.error('Error ocr-peso:', e.message);
        if (req.file?.path) try { fs.unlinkSync(req.file.path); } catch (_) { }
        res.status(500).json({ error: 'Error al procesar OCR' });
    }
});

// =============================================
// API: SUBIR FOTO DEL ANIMAL
// =============================================
app.post('/api/upload-foto', protegerApi, upload.single('foto'), (req, res) => {
    if (!req.file) return res.status(400).json({ success: false, error: 'No se recibió foto' });
    res.json({ success: true, filename: req.file.filename });
});

// =============================================
// API: TABLAS (Panel Admin)
// =============================================
app.get('/api/tablas/:nombre', protegerApi, async (req, res) => {
    try {
        const PERMITIDAS = ['animales', 'control_leche', 'partos', 'servicios', 'queso', 'palpaciones'];
        const tabla = req.params.nombre;
        if (!PERMITIDAS.includes(tabla)) {
            return res.status(403).json({ error: 'Tabla no permitida' });
        }

        let orderBy = (tabla === 'animales') ? 'rowid DESC' : 'id DESC';
        if (tabla === 'animales' && req.query.col && req.query.col !== 'rowid') {
            orderBy = `${req.query.col} ASC`;
        }

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
        console.error('Error tablas:', e.message);
        res.status(500).json({ success: false, error: 'Error al obtener tablas' });
    }
});

// =============================================
// API: EDITAR CELDA (Panel Admin)
// =============================================
app.post('/api/save-cell', protegerApi, async (req, res) => {
    try {
        const { tabla, id, columna, valor } = req.body;
        const PERMITIDAS = ['animales', 'control_leche', 'partos', 'servicios', 'queso', 'palpaciones'];
        if (!PERMITIDAS.includes(tabla)) {
            return res.status(403).json({ error: 'Tabla no permitida' });
        }

        const pkCol = (tabla === 'animales') ? 'numero' : 'id';
        await dbRun(`UPDATE ${tabla} SET ${columna} = ? WHERE ${pkCol} = ?`, [valor, id]);
        res.json({ success: true });
    } catch (e) {
        console.error('Error save-cell:', e.message);
        res.status(500).json({ success: false, error: 'Error al guardar celda' });
    }
});

// Borrar fila completa
app.post('/api/borrar-fila', protegerApi, async (req, res) => {
    try {
        const { tabla, id } = req.body;
        const PERMITIDAS = ['animales', 'control_leche', 'partos', 'servicios', 'queso', 'palpaciones'];
        if (!PERMITIDAS.includes(tabla)) {
            return res.status(403).json({ error: 'Tabla no permitida' });
        }
        const pkCol = (tabla === 'animales') ? 'numero' : 'id';
        await dbRun(`DELETE FROM ${tabla} WHERE ${pkCol} = ?`, [id]);
        res.json({ success: true });
    } catch (e) {
        console.error('Error borrar-fila:', e.message);
        res.status(500).json({ success: false, error: 'Error al borrar fila' });
    }
});

// =============================================
// API: AGREGAR FILA (Panel Admin)
// El index.html llama a POST /api/... con tabla en el select
// =============================================
app.post('/api/agregar-fila', protegerApi, async (req, res) => {
    try {
        const { tabla } = req.body;
        const PERMITIDAS = ['animales', 'control_leche', 'partos', 'servicios', 'queso', 'palpaciones'];
        if (!PERMITIDAS.includes(tabla)) {
            return res.status(403).json({ error: 'Tabla no permitida' });
        }
        if (tabla === 'animales') {
            await dbRun("INSERT INTO animales (numero, nombre) VALUES (?,?)", [Date.now().toString().slice(-6), '...']);
        } else {
            await dbRun(`INSERT INTO ${tabla} (creado_en) VALUES (?)`, [ahora()]);
        }
        res.json({ success: true });
    } catch (e) {
        console.error('Error agregar-fila:', e.message);
        res.status(500).json({ success: false, error: 'Error al agregar fila' });
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
        if (!validarTexto(anio) || anio.length !== 2) {
            return res.status(400).json({ error: 'Año inválido' });
        }
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
        console.error('Error proximo-numero:', e.message);
        res.status(500).json({ error: 'Error al obtener próximo número' });
    }
});

// GET Configuración Admin
app.get('/api/admin-config', protegerApi, (req, res) => {
    try {
        const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        res.json(config);
    } catch (e) {
        console.error('Error leer config:', e.message);
        res.status(500).json({ error: 'Error al leer configuración' });
    }
});

// POST Guardar Configuración Admin
app.post('/api/admin-config', protegerApi, (req, res) => {
    try {
        const newConfig = req.body;
        fs.writeFileSync(configPath, JSON.stringify(newConfig, null, 2));
        res.json({ success: true });
    } catch (e) {
        console.error('Error guardar config:', e.message);
        res.status(500).json({ error: 'Error al guardar configuración' });
    }
});

// =============================================
// API: CONSULTA LECHE (con filtros por fecha/vaca)
// =============================================
app.get('/api/consulta-leche', protegerApi, async (req, res) => {
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
        const normalizados = rows.map(r => ({ ...r, nombre: r.nombre_animal || r.nombre || '', turno: r.turno || '' }));
        res.json({ registros: normalizados, total_kg: totalKg.toFixed(1), total_registros: rows.length });
    } catch (e) {
        console.error('Error consulta-leche:', e.message);
        res.status(500).json({ error: 'Error al consultar leche' });
    }
});

// =============================================
// API: LISTA DE TOROS (unicos de servicios)
// =============================================
app.get('/api/toros', protegerApi, async (req, res) => {
    try {
        const rows = await dbAll("SELECT DISTINCT toro, raza_toro FROM servicios WHERE toro IS NOT NULL AND toro != '' ORDER BY toro");
        res.json(rows);
    } catch (e) {
        console.error('Error toros:', e.message);
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
    try {
        await crearTablas();
        await crearAdminPorDefecto();
        await initOCR();

        app.listen(PORT, () => {
            console.log('');
            console.log('=============================================');
            console.log('   SISGAN PRO - Iniciando servidor...');
            console.log('=============================================');
            console.log('  SERVIDOR ACTIVO EN PUERTO: ' + PORT);
            console.log('  URL: http://localhost:' + PORT);
            console.log('  Usuario admin por defecto');
            console.log('  Se recomienda cambiar la contraseña por defecto');
            console.log('');
            console.log('=============================================');
        });
    } catch (err) {
        console.error('ERROR FATAL al iniciar:', err.message);
        process.exit(1);
    }
}

iniciar().catch(err => {
    console.error('ERROR FATAL:', err.message);
    process.exit(1);
});
