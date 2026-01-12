import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import * as driverService from './driverService';

const SECRET_KEY = process.env.JWT_SECRET || 'super_secret_key_123';

export const registerDriver = async (phone: string, name: string, pin: string) => {
    // 1. Check if driver exists (optional for MVP)
    const existing = driverService.findDriverByPhone(phone);
    if (existing) {
        throw new Error('Driver already exists');
    }

    // 2. Hash PIN
    const salt = await bcrypt.genSalt(10);
    const pinHash = await bcrypt.hash(pin, salt);

    // 3. Register Driver
    const driver = driverService.registerDriver(phone, name, pinHash);
    return driver;
};

export const loginDriver = async (phone: string, pin: string) => {
    // 1. Find Driver
    const driver = driverService.findDriverByPhone(phone);
    if (!driver) {
        throw new Error('Driver not found');
    }

    // 2. Verify PIN
    if (!driver.pinHash) {
        // Fallback for old drivers without PIN (MVP transition)
        // Ensure they can't login or treating empty PIN as valid? 
        // Better: Fail.
        throw new Error('Please register again to set a PIN');
    }

    const isMatch = await bcrypt.compare(pin, driver.pinHash);
    if (!isMatch) {
        throw new Error('Invalid PIN');
    }

    // 3. Generate Token
    const token = jwt.sign({ id: driver.id, role: 'driver' }, SECRET_KEY, { expiresIn: '7d' });

    return { driver, token };
};
