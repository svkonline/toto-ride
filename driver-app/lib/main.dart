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
    
    // Show Login Dialog after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _showLoginDialog());

    _service.listenForRides((data) {
      if (!mounted) return;
      _showRideRequestDialog(data);
    });

    _checkLocationPermission();
  }

  void _showLoginDialog() {
    final phoneController = TextEditingController();
    final pinController = TextEditingController();
    final nameController = TextEditingController(); // Only for register
    bool isRegister = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isRegister ? 'Driver Register' : 'Driver Login'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                if (isRegister)
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                TextField(
                  controller: pinController,
                  decoration: const InputDecoration(labelText: '4-Digit PIN'),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                ),
                TextButton(
                  onPressed: () => setState(() => isRegister = !isRegister),
                  child: Text(isRegister ? 'Already have account? Login' : 'New Driver? Register'),
                )
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  try {
                    if (isRegister) {
                      await _service.register(phoneController.text, nameController.text, pinController.text);
                      // Auto login after register or just show success
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registered! Please Login.')));
                      setState(() => isRegister = false);
                    } else {
                      await _service.login(phoneController.text, pinController.text);
                       if (!mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login Successful!')));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: Text(isRegister ? 'Register' : 'Login'),
              )
            ],
          );
        }
      )
    );
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

  void _showUpiDialog() {
    final upiController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set UPI ID'),
        content: TextField(
          controller: upiController,
          decoration: const InputDecoration(
            labelText: 'UPI ID (e.g., 9876543210@ybl)',
            hintText: 'Enter your VPA'
          ),
        ),
        actions: [
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () async {
              try {
                await _service.updateUpiId(upiController.text);
                 if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID Updated!')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            }
          )
        ]
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
              child: Column( // use column to stack online status and UPI button
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
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
                  if (!isOnline) // Only allow editing UPI when offline
                    ElevatedButton.icon(
                      icon: const Icon(Icons.payment),
                      label: const Text('Set UPI ID'),
                      onPressed: _showUpiDialog,
                    ),
                ],
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
