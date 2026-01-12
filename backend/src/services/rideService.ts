import { Ride, RideRequest, Driver } from '../types';
import * as driverService from './driverService';
import * as walletService from './walletService';

// In-memory store
const rides: Map<string, Ride> = new Map();

export const createRideRequest = (request: RideRequest): Ride => {
    const id = 'ride_' + Date.now();
    const newRide: Ride = {
        ...request,
        id,
        status: 'REQUESTED'
    };
    rides.set(id, newRide);
    return newRide;
};

export const findNearbyDrivers = (lat: number, lng: number): Driver[] => {
    // Mock logic: Return all online drivers for MVP
    // In real app: Geo-query (Redis/Mongo)
    return driverService.getAllOnlineDrivers();
};

export const acceptRide = (rideId: string, driverId: string): Ride | null => {
    const ride = rides.get(rideId);
    const driver = driverService.getAllOnlineDrivers().find(d => d.id === driverId); // Simple lookup

    if (ride && ride.status === 'REQUESTED' && driver) {
        ride.status = 'ACCEPTED';
        ride.driverId = driverId;
        ride.driverUpiId = driver.upiId;
        return ride;
    }
    return null;
};

export const completeRide = (rideId: string): Ride | null => {
    const ride = rides.get(rideId);
    if (ride && ride.status === 'ACCEPTED' && ride.driverId) {
        ride.status = 'COMPLETED';

        // Process Payment: Assume Cash for now.
        // Driver keeps cash, so we DEBIT commission (e.g., 10%) from wallet.
        const commission = ride.fare * 0.10;
        walletService.addTransaction(
            ride.driverId,
            commission,
            'DEBIT',
            `Commission for ride ${ride.id}`
        );

        return ride;
    }
    return null;
};
