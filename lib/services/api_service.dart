import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/medicine.dart';

class ApiService {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const Duration _requestTimeout = Duration(seconds: 10);

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }

    return 'http://localhost:5000';
  }

  Uri _buildUri(String path) => Uri.parse('$baseUrl$path');

  String _extractMessage(http.Response response, String fallbackMessage) {
    if (response.body.isEmpty) {
      return fallbackMessage;
    }

    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Ignore invalid response bodies and use the fallback message.
    }

    return fallbackMessage;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> login(String email, String password) async {
    try {
      final res = await http
          .post(
            _buildUri('/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_requestTimeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['accessToken'] as String);
        return null;
      }

      return _extractMessage(res, 'Login gagal. Periksa email dan password.');
    } on TimeoutException {
      return 'Koneksi ke backend timeout. Pastikan server aktif di $baseUrl.';
    } catch (_) {
      return 'Tidak bisa terhubung ke backend di $baseUrl.';
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<List<Medicine>> getMedicines() async {
    final token = await getToken();
    final res = await http.get(
      _buildUri('/api/medicines'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Medicine.fromJson(e)).toList();
    }
    throw Exception('Gagal mengambil data');
  }

  Future<void> addMedicine(Medicine medicine) async {
    final token = await getToken();
    final res = await http.post(
      _buildUri('/api/medicines'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(medicine.toJson()),
    );
    if (res.statusCode != 201) {
      throw Exception(_extractMessage(res, 'Gagal menambah obat'));
    }
  }

  Future<void> updateMedicine(int id, Medicine medicine) async {
    final token = await getToken();
    final res = await http.put(
      _buildUri('/api/medicines/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(medicine.toJson()),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractMessage(res, 'Gagal update obat'));
    }
  }

  Future<void> deleteMedicine(int id) async {
    final token = await getToken();
    final res = await http.delete(
      _buildUri('/api/medicines/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception(_extractMessage(res, 'Gagal hapus obat'));
    }
  }
}
