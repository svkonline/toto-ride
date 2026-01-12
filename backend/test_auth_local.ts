import * as authService from './src/services/authService';
import * as driverService from './src/services/driverService';

// Mock DB for isolated test if needed, but services use in-memory maps so it works fine in one run
async function run() {
    try {
        console.log('Testing Auth Service Locally...');

        const phone = '1234567890';
        const pin = '1234';
        const name = 'Test Driver';

        console.log('1. Registering...');
        const driver = await authService.registerDriver(phone, name, pin);
        console.log('   Registered:', driver.id);

        console.log('2. Logging in...');
        const result = await authService.loginDriver(phone, pin);
        console.log('   Login Success! Token generated.');

        if (result.driver.id === driver.id) {
            console.log('✅ PASS: Driver Auth working correctly.');
        } else {
            console.error('❌ FAIL: ID mismatch.');
        }
    } catch (e) {
        console.error('❌ FAIL:', e);
    }
}

run();
