import * as driverService from './driverService';
// In a real app, we'd import rideService repository directly or query DB

export interface AdminStats {
    activeDrivers: number;
    totalRevenue: number; // Mocked for now
    totalRides: number;   // Mocked for now
}

export const getDashboardStats = (): AdminStats => {
    const drivers = driverService.getAllOnlineDrivers();

    // Mock data for MVP demonstration
    // Real implementation would calculate sum of all completed rides in DB
    return {
        activeDrivers: drivers.length,
        totalRevenue: 1540.50, // Mock
        totalRides: 42         // Mock
    };
};
