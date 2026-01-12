import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import dotenv from 'dotenv';
import * as driverService from './services/driverService';
import * as rideService from './services/rideService';
import * as walletService from './services/walletService';
import * as ratingService from './services/ratingService';
import * as adminService from './services/adminService';

dotenv.config();

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
    res.send('Toto Ride Backend is Running 🛺');
});

// Routes (Inline for MVP simplicity)
import * as authService from './services/authService';

// ...

// Routes
app.post('/api/auth/driver/register', async (req, res) => {
    try {
        const { phone, name, pin } = req.body;
        if (!phone || !name || !pin) {
            return res.status(400).json({ error: 'Missing fields' });
        }
        const driver = await authService.registerDriver(phone, name, pin);
        res.json(driver);
    } catch (e: any) {
        res.status(400).json({ error: e.message });
    }
});

app.post('/api/auth/driver/login', async (req, res) => {
    try {
        const { phone, pin } = req.body;
        if (!phone || !pin) {
            return res.status(400).json({ error: 'Missing fields' });
        }
        const result = await authService.loginDriver(phone, pin);
        res.json(result);
    } catch (e: any) {
        res.status(401).json({ error: e.message });
    }
});

// Passenger Auth Routes
app.post('/api/auth/passenger/register', async (req, res) => {
    try {
        const { phone, name, pin } = req.body;
        if (!phone || !name || !pin) return res.status(400).json({ error: 'Missing fields' });
        const user = await authService.registerPassenger(phone, name, pin);
        res.json(user);
    } catch (e: any) {
        res.status(400).json({ error: e.message });
    }
});

app.post('/api/auth/passenger/login', async (req, res) => {
    try {
        const { phone, pin } = req.body;
        if (!phone || !pin) return res.status(400).json({ error: 'Missing fields' });
        const result = await authService.loginPassenger(phone, pin);
        res.json(result);
    } catch (e: any) {
        res.status(401).json({ error: e.message });
    }
});

app.post('/api/ride/request', (req, res) => {
    const request = req.body; // Validate types in real app
    const ride = rideService.createRideRequest(request);

    // Find drivers
    const drivers = rideService.findNearbyDrivers(request.pickup.lat, request.pickup.lng);

    // Notify via Socket
    // In production, we'd emit to specific driver rooms
    io.emit('new_ride_request', ride);

    res.json(ride);
});

// Wallet & Earnings
app.get('/api/driver/:driverId/wallet', (req, res) => {
    const wallet = walletService.getWallet(req.params.driverId);
    res.json(wallet);
});

app.post('/api/ride/:rideId/complete', (req, res) => {
    const ride = rideService.completeRide(req.params.rideId);
    if (ride) {
        io.emit('ride_status_update', ride);
        res.json(ride);
    } else {
        res.status(400).json({ error: 'Ride not found or invalid status' });
    }
});

app.post('/api/driver/:driverId/rate', (req, res) => {
    const { rating } = req.body;
    if (!rating || rating < 1 || rating > 5) {
        return res.status(400).json({ error: 'Invalid rating' });
    }
    const driver = ratingService.rateDriver(req.params.driverId, rating);
    if (driver) {
        res.json(driver);
    } else {
        res.status(404).json({ error: 'Driver not found' });
    }
});

app.get('/api/admin/stats', (req, res) => {
    const stats = adminService.getDashboardStats();
    res.json(stats);
});

app.get('/api/admin/drivers', (req, res) => {
    const drivers = driverService.getAllDrivers();
    res.json(drivers);
});

app.post('/api/admin/driver/:id/status', (req, res) => {
    const { status } = req.body;
    if (status !== 'APPROVED' && status !== 'REJECTED') {
        return res.status(400).json({ error: 'Invalid status' });
    }
    const driver = driverService.updateDriverStatus(req.params.id, status);
    if (driver) {
        res.json(driver);
    } else {
        res.status(404).json({ error: 'Driver not found' });
    }
});

app.post('/api/driver/:id/upi', (req, res) => {
    const { upiId } = req.body;
    if (!upiId) return res.status(400).json({ error: 'Missing UPI ID' });

    const driver = driverService.updateDriverUpi(req.params.id, upiId);
    if (driver) {
        res.json(driver);
    } else {
        res.status(404).json({ error: 'Driver not found' });
    }
});

// Socket.io connection
io.on('connection', (socket) => {
    console.log('User connected:', socket.id);

    // Driver Locations
    socket.on('driver_location_update', (data: { driverId: string, lat: number, lng: number }) => {
        driverService.updateDriverLocation(data.driverId, data.lat, data.lng);
        // Broadcast to passengers monitoring map
        socket.broadcast.emit('driver_moved', { driverId: data.driverId, lat: data.lat, lng: data.lng });
    });

    // Ride Acceptance
    socket.on('accept_ride', (data: { rideId: string, driverId: string }) => {
        const ride = rideService.acceptRide(data.rideId, data.driverId);
        if (ride) {
            io.emit('ride_status_update', ride); // Notify all relevant parties
        }
    });

    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
    });
});

const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
