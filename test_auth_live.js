const axios = require('axios');

const BASE_URL = 'https://toto-ride.onrender.com';

async function testAuth() {
    console.log('Testing Auth on:', BASE_URL);
    const phone = '9999999999';
    const pin = '1234';
    const name = 'Test Driver';

    try {
        console.log('1. Attempting Register...');
        try {
            const regRes = await axios.post(`${BASE_URL}/api/auth/driver/register`, { phone, name, pin });
            console.log('✅ Register Success:', regRes.data.id);
        } catch (e) {
            if (e.response && e.response.data && e.response.data.error === 'Driver already exists') {
                console.log('ℹ️ Driver already registered, proceeding to login...');
            } else {
                throw e;
            }
        }

        console.log('2. Attempting Login...');
        const loginRes = await axios.post(`${BASE_URL}/api/auth/driver/login`, { phone, pin });
        console.log('✅ Login Success!');
        console.log('   Token:', loginRes.data.token ? 'Received OK' : 'Missing');
        console.log('   Driver Name:', loginRes.data.driver.name);

    } catch (error) {
        console.error('❌ Test Failed:', error.response ? error.response.data : error.message);
    }
}

testAuth();
