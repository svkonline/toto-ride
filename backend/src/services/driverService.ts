import { Driver } from '../types';

// In-memory store for MVP
const drivers: Map<string, Driver> = new Map();

export const registerDriver = (phone: string, name: string): Driver => {
    const id = 'driver_' + Date.now();
    const newDriver: Driver = {
        id,
        phone,
        name,
        isOnline: false,
        status: 'PENDING'
    };
    drivers.set(id, newDriver);
    return newDriver;
};

export const getAllDrivers = (): Driver[] => {
    return Array.from(drivers.values());
};

export const updateDriverStatus = (id: string, status: 'APPROVED' | 'REJECTED'): Driver | undefined => {
    const driver = drivers.get(id);
    if (driver) {
        driver.status = status;
        return driver;
    }
    return undefined;
};

export const getDriver = (id: string): Driver | undefined => {
    return drivers.get(id);
};

export const updateDriverLocation = (id: string, lat: number, lng: number): Driver | undefined => {
    const driver = drivers.get(id);
    if (driver) {
        driver.location = { lat, lng };
        driver.isOnline = true; // Auto-online on location update for MVP
        return driver;
    }
    return undefined;
};

export const getAllOnlineDrivers = (): Driver[] => {
    return Array.from(drivers.values()).filter(d => d.isOnline);
};
