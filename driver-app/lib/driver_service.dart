import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DriverService {
  static const String baseUrl = 'https://toto-ride.onrender.com';
  late IO.Socket socket;
  String? driverId;
  String? token;

  void initSocket() {
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });
    socket.connect();
  }

  Future<void> register(String phone, String name, String pin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/driver/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'name': name, 'pin': pin}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      driverId = data['id'];
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<void> login(String phone, String pin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/driver/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'pin': pin}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      driverId = data['driver']['id'];
      token = data['token'];
      // Re-connect socket with auth if needed, or just update state
    } else {
       throw Exception('Login failed: ${response.body}');
    }
  }

  void updateLocation(double lat, double lng) {
    if (driverId != null) {
      socket.emit('driver_location_update', {
        'driverId': driverId,
        'lat': lat,
        'lng': lng
      });
    }
  }

  Future<void> updateUpiId(String upiId) async {
    if (driverId == null) throw Exception('Driver not logged in');

    final response = await http.post(
      Uri.parse('$baseUrl/api/driver/$driverId/upi'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'upiId': upiId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update UPI ID: ${response.body}');
    }
  }

  void acceptRide(String rideId) {
    if (driverId != null) {
      socket.emit('accept_ride', {
        'rideId': rideId,
        'driverId': driverId
      });
    }
  }

  void listenForRides(Function(dynamic) onNewRide) {
    socket.on('new_ride_request', (data) => onNewRide(data));
  }
}
