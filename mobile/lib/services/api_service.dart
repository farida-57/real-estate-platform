import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  // Base URL - Use 10.0.2.2 for Android Emulator, or your machine local IP
  // static const String baseUrl = 'http://10.0.2.2:5000/api'; // Émulateur Android
  static const String baseUrl = 'http://192.168.100.56:5000/api'; 

  ApiService() {
    _dio.options.baseUrl = baseUrl;

    // Configure validation status - accept all status codes don't throw exception
    _dio.options.validateStatus = (status) {
      return status != null && status < 500;
    };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('[API] Request: ${options.method} ${options.path}');
          print('[API] Headers: ${options.headers}');
          print('[API] Data: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('[API] Response: ${response.statusCode}');
          print('[API] Response data: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('[API] Error: ${e.message}');
          print('[API] Status Code: ${e.response?.statusCode}');
          print('[API] Response: ${e.response?.data}');
          // Handle global errors (e.g., 401 logout)
          if (e.response?.statusCode == 401) {
            // Log out user or refresh token
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  // Update user profile
  Future<void> updateUserProfile(String path, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(path, data: data);
      if (response.statusCode == 200) {
        // Handle successful update
        print('Profile updated successfully');
      }
    } catch (error) {
      print('UPDATE PROFILE ERROR:');
    }
  }
}
