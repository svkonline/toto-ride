import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'driver_service.dart';

void main() {
  runApp(const TotoDriverApp());
}

class TotoDriverApp extends StatelessWidget {
  const TotoDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toto Driver',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const DriverHomePage(),
    );
  }
}

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  bool isOnline = false;
  final DriverService _service = DriverService();
  final Location _location = Location();
  final MapController _mapController = MapController();
  
  LatLng _currentPosition = const LatLng(22.5726, 88.3639); // Kolkata Default

  @override
  void initState() {
    super.initState();
    _service.initSocket();
    _service.register('9876543210', 'Toto Driver 1');

    _service.listenForRides((data) {
      if (!mounted) return;
      _showRideRequestDialog(data);
    });

    // Check location permission initially
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }
    
    // Get initial location
    LocationData locationData = await _location.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      setState(() {
        _currentPosition = LatLng(locationData.latitude!, locationData.longitude!);
      });
      _mapController.move(_currentPosition, 16.0);
    }
  }

  void _showRideRequestDialog(dynamic data) {
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('New Ride Request!'),
        content: Text('Pickup: ${data['pickup']['address'] ?? "Unknown"}'),
        actions: [
          TextButton(
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: const Text('Accept'),
            onPressed: () {
              _service.acceptRide(data['id']);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride Accepted!')));
            },
          )
        ],
      )
    );
  }

  void _toggleOnline() async {
    if (!isOnline) {
      _startTracking();
    }
    setState(() => isOnline = !isOnline);
  }

  void _startTracking() {
    _location.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
         final newPos = LatLng(currentLocation.latitude!, currentLocation.longitude!);
         setState(() => _currentPosition = newPos);
         _mapController.move(newPos, _mapController.camera.zoom);
         _service.updateLocation(newPos.latitude, newPos.longitude);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.totoride.driver',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition,
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.electric_rickshaw, color: Colors.orange, size: 40),
                  ),
                ],
              ),
            ],
          ),
          
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Card(
                margin: const EdgeInsets.all(16),
                color: isOnline ? Colors.green : Colors.grey[800],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    isOnline ? 'ONLINE' : 'OFFLINE',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOnline ? Colors.red : Colors.green,
                  ),
                  onPressed: _toggleOnline,
                  child: Text(
                    isOnline ? 'GO OFFLINE' : 'GO ONLINE',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
