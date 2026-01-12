const axios = require('axios');

const BASE_URL = 'https://toto-ride.onrender.com';

async function wait(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function checkHealth() {
    console.log('Checking Server Connectivity (Max wait: 2 mins)...');

    for (let i = 0; i < 24; i++) { // 24 * 5s = 120s
        try {
            console.log(`Attempt ${i + 1}: Pinging Root...`);
            const res = await axios.get(`${BASE_URL}/`, { timeout: 10000 });
            console.log('✅ SUCCESS! Server is Online.');
            console.log('   Response:', res.data);
            return;
        } catch (e) {
            console.log(`   Waiting... (${e.message})`); // e.g. timeout or connection refused
            await wait(5000); // Wait 5s before retry
        }
    }
    console.error('❌ Failed to connect after 2 minutes.');
}

checkHealth();
