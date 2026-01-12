import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DriverService {
  static const String baseUrl = 'http://localhost:3000';
  late IO.Socket socket;
  String? driverId;

  void initSocket() {
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });
    socket.connect();
  }

  Future<void> register(String phone, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/driver/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'name': name}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      driverId = data['id'];
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
