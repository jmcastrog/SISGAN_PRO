const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const v4Path = path.join('d:', 'SISGAN_V4', 'data', 'sisgan_v4.db');
const proPath = path.join('D:', 'Proyectos', 'SISGAN_PRO', 'data', 'sisgan_pro.db');

async function migrar() {
    const dbV4 = new sqlite3.Database(v4Path);
    const dbPro = new sqlite3.Database(proPath);

    // Mapeo exhaustivo de columnas: { tabla_v4: { columna_v4: columna_pro } }
    const columnMapping = {
        'animales': {
            'fecha_nacimiento': 'fecha_nac',
            'status': 'estatus'
        },
        'control_leche': {
            'numero_animal': 'numero_animal',
            'litros': 'kg'
        },
        'partos': {
            'numero_vaca': 'num_madre',
            'nombre_madre': 'nom_madre',
            'numero_cria': 'num_asignado',
            'sexo_cria': 'sexo',
            'observaciones': 'estado' // En V4 observaciones podía ser estado
        },
        'servicios': {
            'numero_vaca': 'numero',
            'observaciones': 'tipo' // Mapeo preventivo
        }
    };

    const tablas = ['animales', 'control_leche', 'partos', 'servicios'];

    for (const tabla of tablas) {
        console.log(`\n>>> Procesando tabla: ${tabla}`);

        await new Promise((resolve, reject) => {
            dbV4.all(`SELECT * FROM ${tabla}`, [], async (err, rows) => {
                if (err) {
                    console.error(`Error al leer tabla ${tabla} en V4:`, err.message);
                    return resolve();
                }

                if (!rows || rows.length === 0) {
                    console.log(`- Tabla ${tabla} está vacía en V4.`);
                    return resolve();
                }

                // Preparar los registros para la inserción
                const mappedRows = rows.map(row => {
                    const newRow = {};
                    for (const key in row) {
                        const targetCol = (columnMapping[tabla] && columnMapping[tabla][key]) ? columnMapping[tabla][key] : key;
                        newRow[targetCol] = row[key];
                    }
                    return newRow;
                });

                // Filtrar columnas que NO existen en la tabla destino
                // Para simplificar, asumimos que las columnas mapeadas son las correctas
                // pero eliminamos las que no existan en el primer row de PRO (opcional)

                const cols = Object.keys(mappedRows[0]);
                const query = `INSERT OR REPLACE INTO ${tabla} (${cols.join(', ')}) VALUES (${cols.map(() => '?').join(', ')})`;

                dbPro.serialize(() => {
                    dbPro.run("BEGIN TRANSACTION");
                    const stmt = dbPro.prepare(query);

                    mappedRows.forEach(row => {
                        stmt.run(Object.values(row));
                    });

                    stmt.finalize();
                    dbPro.run("COMMIT", (err) => {
                        if (err) {
                            console.error(`Error al insertar registros en ${tabla}:`, err.message);
                        } else {
                            console.log(`[OK] ${mappedRows.length} registros migrados.`);
                        }
                        resolve();
                    });
                });
            });
        });
    }

    dbV4.close();
    dbPro.close();
    console.log('\n✔ MIGRACIÓN COMPLETADA CON ÉXITO');
}

migrar();
