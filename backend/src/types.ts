export interface Driver {
    id: string;
    phone: string;
    name: string;
    isOnline: boolean;
    status: 'PENDING' | 'APPROVED' | 'REJECTED';
    rating?: number;
    ratingCount?: number;
    location?: {
        lat: number;
        lng: number;
    };
    socketId?: string;
    pinHash?: string; // For Auth
    upiId?: string; // For Payments
}

export interface RideRequest {
    passengerId: string;
    pickup: {
        lat: number;
        lng: number;
        address: string;
    };
    drop: {
        lat: number;
        lng: number;
        address: string;
    };
    fare: number;
}

export interface Ride extends RideRequest {
    id: string;
    driverId?: string;
    driverUpiId?: string; // Propagate driver's UPI to ride
    status: 'REQUESTED' | 'ACCEPTED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED';
}

export interface Wallet {
    driverId: string;
    balance: number;
    transactions: Transaction[];
}

export interface Transaction {
    id: string;
    amount: number;
    type: 'CREDIT' | 'DEBIT';
    description: string;
    timestamp: number;
}
