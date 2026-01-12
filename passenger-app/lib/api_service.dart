import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ApiService {
  static const String baseUrl = 'https://toto-ride.onrender.com'; // Live Backend
  late IO.Socket socket;

  void initSocket() {
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });
    socket.connect();
    print('Socket init called');
  }

  Future<Map<String, dynamic>> requestRide(Map<String, dynamic> rideData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ride/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(rideData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to book ride');
    }
  }

  void listenForDrivers(Function(dynamic) onDriverMoved) {
    socket.on('driver_moved', (data) => onDriverMoved(data));
  }
}
