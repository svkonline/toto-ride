import { RideRequest } from '../types';

export interface Passenger {
    id: string;
    phone: string;
    name: string;
    pinHash?: string;
    rating?: number;
}

// In-memory store
const passengers: Map<string, Passenger> = new Map();

export const findPassengerByPhone = (phone: string): Passenger | undefined => {
    return Array.from(passengers.values()).find(p => p.phone === phone);
};

export const registerPassenger = (phone: string, name: string, pinHash?: string): Passenger => {
    const id = 'user_' + Date.now();
    const newPassenger: Passenger = {
        id,
        phone,
        name,
        rating: 5.0,
        pinHash
    };
    passengers.set(id, newPassenger);
    return newPassenger;
};

export const getPassenger = (id: string): Passenger | undefined => {
    return passengers.get(id);
};
