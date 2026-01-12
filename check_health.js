const axios = require('axios');

const BASE_URL = 'https://toto-ride.onrender.com';

async function checkHealth() {
    console.log('Checking Server Connectivity...');

    // 1. Check Root
    try {
        console.log('1. Pinging Root / ...');
        const res1 = await axios.get(`${BASE_URL}/`, { timeout: 5000 });
        console.log('✅ Root OK:', res1.data);
    } catch (e) {
        console.error('❌ Root Fail:', e.message);
    }

    // 2. Check Stats
    try {
        console.log('2. Pinging /api/admin/stats ...');
        const res2 = await axios.get(`${BASE_URL}/api/admin/stats`, { timeout: 5000 });
        console.log('✅ Stats OK:', res2.data);
    } catch (e) {
        console.error('❌ Stats Fail:', e.message);
    }
}

checkHealth();
