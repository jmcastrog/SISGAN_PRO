const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

const BASE_URL = 'http://localhost:5000/api';

async function verify() {
    console.log('--- Iniciando Verificacion de Categorizacion Automatica ---');

    try {
        // 1. Encontrar una vaca para la prueba
        console.log('\n1. Buscando vaca para prueba de parto...');
        const animalesRes = await fetch(`${BASE_URL}/animales-produccion`);
        const animales = await animalesRes.json();
        const vacas = animales.filter(a => a.tipo && a.tipo.toLowerCase().includes('vaca') && a.estatus === 'Vivos');
        
        if (vacas.length === 0) {
            console.log('No se encontraron vacas vivas para la prueba.');
            return;
        }

        const vaca = vacas[0];
        console.log(`Vaca seleccionada: ${vaca.numero} (${vaca.nombre})`);
        console.log(`Estado inicial - Lote: ${vaca.lote}, Estatus Repro: ${vaca.estatus_repro || 'N/A'}`);

        // 2. Registrar un parto
        console.log('\n2. Registrando parto...');
        const calfNum = `TEST-CRIA-${Date.now().toString().slice(-4)}`;
        const partoData = {
            fecha: new Date().toISOString().split('T')[0],
            num_madre: vaca.numero,
            nom_madre: vaca.nombre,
            num_asignado: calfNum,
            sexo_cria: 'Hembra',
            peso: 32,
            estado: 'Vivo',
            creado_por: 'verificador_script'
        };

        const partoRes = await fetch(`${BASE_URL}/registrar-parto`, {
            method: 'POST',
            body: JSON.stringify(partoData),
            headers: { 'Content-Type': 'application/json' }
        });
        const partoJson = await partoRes.json();
        if (partoJson.success) {
            console.log('Parto registrado con exito.');
        } else {
            console.error('Error registrando parto:', partoJson.error);
            return;
        }

        // 3. Verificar cambios en la madre
        console.log('\n3. Verificando cambios en la madre...');
        const madreDetalleRes = await fetch(`${BASE_URL}/detalle/${vaca.numero}`);
        const madreDetalle = await madreDetalleRes.json();
        console.log(`Estado actual Madre - Lote: ${madreDetalle.lote}, Estatus Repro: ${madreDetalle.estatus_repro}, Fecha Parto Est: ${madreDetalle.fecha_parto_est}`);
        
        const loteOk = (madreDetalle.lote === 'Ordeno' || madreDetalle.lote === 'Ordeño');
        const estatusOk = (madreDetalle.estatus_repro === 'En Lactancia');
        
        if (loteOk && estatusOk) {
            console.log('OK: Madre actualizada correctamente (Ordeno / En Lactancia).');
        } else {
            console.log(`KO: Madre NO actualizada correctamente. Lote OK: ${loteOk}, Estatus OK: ${estatusOk}`);
        }

        // 4. Verificar existencia de la cria
        console.log('\n4. Verificando nueva cria...');
        const criaDetalleRes = await fetch(`${BASE_URL}/detalle/${calfNum}`);
        if (criaDetalleRes.ok) {
            const criaDetalle = await criaDetalleRes.json();
            console.log(`Cria encontrada: ${criaDetalle.numero} (${criaDetalle.nombre})`);
            console.log(`Lote: ${criaDetalle.lote}, Tipo: ${criaDetalle.tipo}`);
            const loteCriaOk = (criaDetalle.lote === 'Crias' || criaDetalle.lote === 'Crías');
            const tipoCriaOk = (criaDetalle.tipo === 'Becerra' || criaDetalle.tipo === 'Becerras');
            if (loteCriaOk && tipoCriaOk) {
                console.log('OK: Cria creada correctamente en el lote "Crias".');
            } else {
                console.log(`KO: Cria creada con datos incorrectos. Lote OK: ${loteCriaOk}, Tipo OK: ${tipoCriaOk}`);
            }
        } else {
            console.log(`KO: No se encontro la cria ${calfNum}.`);
        }

        // 5. Registrar palpacion
        console.log('\n5. Registrando palpacion ("Prenada")...');
        const palpacionData = {
            fecha: new Date().toISOString().split('T')[0],
            numero: vaca.numero,
            nombre: vaca.nombre,
            diagnostico: 'Prenada',
            fecha_parto_est: '2026-12-25',
            tecnico: 'Verificator',
            creado_por: 'verificador_script'
        };

        const palpRes = await fetch(`${BASE_URL}/registrar-palpacion`, {
            method: 'POST',
            body: JSON.stringify(palpacionData),
            headers: { 'Content-Type': 'application/json' }
        });
        const palpJson = await palpRes.json();
        if (palpJson.success) {
            console.log('Palpacion registrada con exito.');
        } else {
            console.error('Error registrando palpacion:', palpJson.error);
            return;
        }

        // 6. Verificar cambios finales
        console.log('\n6. Verificando estatus final ("Prenada")...');
        const finalDetalleRes = await fetch(`${BASE_URL}/detalle/${vaca.numero}`);
        const finalDetalle = await finalDetalleRes.json();
        console.log(`Estado final Madre - Estatus Repro: ${finalDetalle.estatus_repro}, Fecha Parto Est: ${finalDetalle.fecha_parto_est}`);
        
        const estatusFinalOk = (finalDetalle.estatus_repro === 'Prenada' || finalDetalle.estatus_repro === 'Preñada');
        const fechaOk = (finalDetalle.fecha_parto_est === '2026-12-25');
        
        if (estatusFinalOk && fechaOk) {
            console.log('OK: Palpacion actualizo correctamente el estatus y fecha estimada.');
        } else {
            console.log(`KO: Palpacion NO actualizo correctamente. Estatus OK: ${estatusFinalOk}, Fecha OK: ${fechaOk}`);
        }

    } catch (error) {
        console.error('Error durante la verificacion:', error.message);
    }
}

verify();
