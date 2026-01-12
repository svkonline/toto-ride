import { Driver } from '../types';
import * as driverService from './driverService';

export const rateDriver = (driverId: string, rating: number): Driver | undefined => {
    const driver = driverService.getDriver(driverId);
    if (driver) {
        // Simple average calculation
        // In production, store individual ratings in a separate collection and aggregate
        const currentRating = driver.rating || 5.0;
        const ratingCount = driver.ratingCount || 0; // Need to add this to Type

        const newRating = ((currentRating * ratingCount) + rating) / (ratingCount + 1);

        driver.rating = parseFloat(newRating.toFixed(1));
        driver.ratingCount = ratingCount + 1;

        return driver;
    }
    return undefined;
};
