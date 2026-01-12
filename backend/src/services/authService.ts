import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import * as driverService from './driverService';
import * as passengerService from './passengerService';

const SECRET_KEY = process.env.JWT_SECRET || 'super_secret_key_123';

// --- DRIVER AUTH ---
export const registerDriver = async (phone: string, name: string, pin: string) => {
    // ... (existing logic)
    const existing = driverService.findDriverByPhone(phone);
    if (existing) throw new Error('Driver already exists');

    const salt = await bcrypt.genSalt(10);
    const pinHash = await bcrypt.hash(pin, salt);
    return driverService.registerDriver(phone, name, pinHash);
};

export const loginDriver = async (phone: string, pin: string) => {
    const driver = driverService.findDriverByPhone(phone);
    if (!driver) throw new Error('Driver not found');
    if (!driver.pinHash) throw new Error('Please register again to set a PIN');

    const isMatch = await bcrypt.compare(pin, driver.pinHash);
    if (!isMatch) throw new Error('Invalid PIN');

    const token = jwt.sign({ id: driver.id, role: 'driver' }, SECRET_KEY, { expiresIn: '7d' });
    return { driver, token };
};

// --- PASSENGER AUTH ---
export const registerPassenger = async (phone: string, name: string, pin: string) => {
    const existing = passengerService.findPassengerByPhone(phone);
    if (existing) throw new Error('User already exists');

    const salt = await bcrypt.genSalt(10);
    const pinHash = await bcrypt.hash(pin, salt);
    return passengerService.registerPassenger(phone, name, pinHash);
};

export const loginPassenger = async (phone: string, pin: string) => {
    const user = passengerService.findPassengerByPhone(phone);
    if (!user) throw new Error('User not found');
    if (!user.pinHash) throw new Error('Please register again');

    const isMatch = await bcrypt.compare(pin, user.pinHash);
    if (!isMatch) throw new Error('Invalid PIN');

    const token = jwt.sign({ id: user.id, role: 'passenger' }, SECRET_KEY, { expiresIn: '7d' });
    return { user, token };
};
