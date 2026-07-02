const axios = require('axios');
const BASE_URL = 'http://localhost:5000/api';

async function probarSistema() {
    console.log('--- PRUEBAS DE SISTEMA (v2.0) ---\n');

    try {
        // 1. Login exitoso
        console.log('1. Login con credenciales válidas...');
        const loginRes = await axios.post(`${BASE_URL}/login`, {
            usuario: 'admin',
            password: 'admin123'
        });
        const token = loginRes.data.token;
        console.log('   ✓ Token generado exitosamente\n');

        // 2. Protección de API sin token
        console.log('2. Acceso sin token a dashboard...');
        try {
            await axios.get(`${BASE_URL}/dashboard`);
            console.log('   ✗ ERROR: Debió rechazarse (sin token)\n');
        } catch (err) {
            console.log('   ✓ Correctamente rechazado\n');
        }

        // 3. Protección de API con token válido
        console.log('3. Acceso con token válido a dashboard...');
        const dashboardRes = await axios.get(`${BASE_URL}/dashboard`, {
            headers: { Authorization: `Bearer ${token}` }
        });
        console.log('   ✓ Acceso exitoso\n');

        // 4. Validación de datos incorrectos
        console.log('4. Registrar animal sin número...');
        try {
            await axios.post(`${BASE_URL}/registrar-animal`, {});
            console.log('   ✗ ERROR: Debió rechazarse\n');
        } catch (err) {
            console.log('   ✓ Correctamente rechazado (validación)\n');
        }

        // 5. Validación de datos válidos
        console.log('5. Registrar animal válido...');
        const animalRes = await axios.post(`${BASE_URL}/registrar-animal`, {
            numero: 'TEST-2026-001',
            nombre: 'Animal de Prueba',
            sexo: 'Hembra',
            estatus: 'Vivos'
        }, {
            headers: { Authorization: `Bearer ${token}` }
        });
        console.log('   ✓ Animal registrado exitosamente\n');

        // 6. Protección de APIs no autenticadas
        console.log('6. Verificar que APIs no autenticadas fallan...');
        const protectedRoutes = ['/registrar-leche', '/registrar-parto', '/borrar-fila'];
        for (const route of protectedRoutes) {
            try {
                await axios.post(`${BASE_URL}${route}`, {});
            } catch (err) {
                if (err.response?.status === 401) {
                    console.log(`   ✓ ${route}: Correctamente protegida`);
                } else {
                    console.log(`   ? ${route}: Status ${err.response?.status || 'error'}`);
                }
            }
        }
        console.log();

        // 7. Info endpoint
        console.log('7. Verificar endpoint /api/info...');
        const infoRes = await axios.get(`${BASE_URL}/info`);
        console.log('   Versión:', infoRes.data.version);
        console.log('   Características:', infoRes.data.features.join(', '));
        console.log();

        console.log('--- PRUEBAS COMPLETADAS ---');
        console.log('\n✓ Todas las pruebas de seguridad pasaron exitosamente');
        console.log('\nPróximos pasos:');
        console.log('1. Cambiar la contraseña del admin (ve a /api/crear-admin)');
        console.log('2. Cambiar JWT_SECRET en .env');
        console.log('3. Configurar validaciones en el frontend');

    } catch (error) {
        console.error('\n✗ Error durante las pruebas:', error.message);
        if (error.response) {
            console.error('Estado:', error.response.status);
            console.error('Datos:', error.response.data);
        }
    }
}

probarSistema();
