import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'api_service.dart';

void main() {
  runApp(const TotoPassengerApp());
}

class TotoPassengerApp extends StatelessWidget {
  const TotoPassengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toto Ride',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _api = ApiService();
  final MapController _mapController = MapController();
  
  // Kolkata, College Street area
  final LatLng _initialPosition = const LatLng(22.5726, 88.3639);
  
  // Real-time driver markers
  List<Marker> _driverMarkers = [];
  bool _isBooking = false;
  
  @override
  void initState() {
    super.initState();
    _api.initSocket();
    
    // Listen for drivers moving
    _api.listenForDrivers((data) {
      if (data['lat'] != null && data['lng'] != null) {
        _updateDriverMarker(data['driverId'], LatLng(data['lat'], data['lng']));
      }
    });
  }

  void _updateDriverMarker(String driverId, LatLng position) {
    setState(() {
      // Simple logic: Remove old marker for this driver and add new one
      // In prod, use a Map<String, Marker>
      _driverMarkers.removeWhere((m) => m.key == Key(driverId));
      
      _driverMarkers.add(
        Marker(
          key: Key(driverId),
          point: position,
          width: 40,
          height: 40,
          child: const Icon(Icons.electric_rickshaw, color: Colors.green, size: 30),
        )
      );
    });
  }

  void _bookRide() async {
    setState(() => _isBooking = true);
    try {
      await _api.requestRide({
        'passengerId': 'user_123',
        'pickup': {'lat': 22.5726, 'lng': 88.3639, 'address': 'College Street'},
        'drop': {'lat': 22.5826, 'lng': 88.3739, 'address': 'Sealdah Station'},
        'fare': 50
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Requesting nearby Totos...')));
    } catch (e) {
      setState(() => _isBooking = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error booking ride')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.totoride.passenger',
              ),
              MarkerLayer(
                markers: [
                  // Pickup Marker
                  Marker(
                    point: _initialPosition,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                  ..._driverMarkers,
                ],
              ),
            ],
          ),

          // Search Bar Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 10),
                      Text("Where to?", style: TextStyle(fontSize: 18, color: Colors.black54)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Booking Panel
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Economy Ride", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                       Text("Est. Fare: ₹50"),
                       Text("2 min away"),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isBooking ? null : _bookRide,
                    child: _isBooking 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('BOOK NOW', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
