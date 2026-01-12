import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ApiService {
  static const String baseUrl = 'https://toto-ride.onrender.com';
  late IO.Socket socket;
  String? userId;
  String? token;

  void initSocket() {
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });
    socket.connect();
  }

  // Reuse Driver Register/Login logic for Passenger (MVP shared logic or separate endpoint?)
  // For MVP, we'll re-use the same structure but ideally should have /api/auth/passenger/...
  // For now, let's assume we use the same endpoint or add a 'role' field if needed.
  // Actually, let's create a passenger auth endpoint in backend or just use the driver one for 'user' creation?
  // Use a separate method in backend or just generic 'register'?
  // Let's stick to strict typing. I'll add passenger auth to backend if missing, 
  // OR just use client-side logic to store 'passenger' role.
  
  // Wait, I only added /api/auth/driver/... in backend. I need /api/auth/passenger/...
  // Let's implement client first, and I'll update backend in next step if needed.
  // Actually, for a quick MVP, let's use the SAME endpoint but I need to clear this up.
  // I will assume I need to add /api/auth/passenger in backend.

  Future<void> register(String phone, String name, String pin) async {
     // TODO: Backend needs this endpoint
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/passenger/register'), 
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'name': name, 'pin': pin}),
    );
     if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      userId = data['id'];
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<void> login(String phone, String pin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/passenger/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'pin': pin}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      userId = data['user']['id'];
      token = data['token'];
    } else {
       throw Exception('Login failed: ${response.body}');
    }
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
