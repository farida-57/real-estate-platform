import '../models/user_model.dart';
import 'api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  Future<UserModel?> login(String email, String password) async {
    try {
      print('[AuthService] Logging in with email: $email');

      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      final response = await _apiService.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      print('[AuthService] Login response status: ${response.statusCode}');
      print('[AuthService] Login response data: ${response.data}');

      if (response.statusCode == 200) {
        final token = response.data['token'];
        if (token != null && token.isNotEmpty) {
          await _storage.write(key: 'jwt_token', value: token);
          print('[AuthService] Token saved successfully');
        } else {
          print('[AuthService] Warning: No token received in response');
        }

        try {
          return UserModel.fromJson(response.data);
        } catch (parseError) {
          print('[AuthService] Error parsing user data: $parseError');
          print('[AuthService] Response data was: ${response.data}');
          rethrow;
        }
      } else if (response.statusCode == 400) {
        throw Exception(response.data['message'] ?? 'Invalid credentials');
      } else if (response.statusCode == 401) {
        throw Exception('Email or password incorrect');
      } else {
        throw Exception(
          'Login failed: ${response.data['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('[AuthService] Login error: $e');
      rethrow;
    }
  }

  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
  }) async {
    try {
      print('[AuthService] Registering user: $email');

      // Validate inputs
      if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
        throw Exception('All fields are required');
      }

      final response = await _apiService.post(
        '/auth/register',
        data: {
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      print('[AuthService] Register response status: ${response.statusCode}');
      print('[AuthService] Register response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final token = response.data['token'];
        if (token != null && token.isNotEmpty) {
          await _storage.write(key: 'jwt_token', value: token);
          print('[AuthService] Token saved successfully');
        } else {
          print('[AuthService] Warning: No token received in response');
        }

        try {
          return UserModel.fromJson(response.data);
        } catch (parseError) {
          print('[AuthService] Error parsing user data: $parseError');
          print('[AuthService] Response data was: ${response.data}');
          rethrow;
        }
      } else if (response.statusCode == 400) {
        throw Exception(response.data['message'] ?? 'Invalid request data');
      } else {
        throw Exception(
          'Registration failed: ${response.data['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('[AuthService] Register error: $e');
      rethrow;
    }
  }

  Future<UserModel?> getProfile() async {
    try {
      print('[AuthService] Getting user profile');
      final response = await _apiService.get('/auth/profile');

      print('[AuthService] Profile response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else if (response.statusCode == 401) {
        // If token is invalid or expired
        print('[AuthService] Token expired, logging out');
        await logout();
        throw Exception('Token expired');
      } else {
        throw Exception(
          'Failed to get profile: ${response.data['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('[AuthService] Get profile error: $e');
      // If token is invalid or expired, logout
      if (e.toString().contains('401') || e.toString().contains('token')) {
        await logout();
      }
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      print('[AuthService] Updating profile');
      final response = await _apiService.put('/auth/profile', data: data);

      print('[AuthService] Update profile response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
          'Failed to update profile: ${response.data['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('[AuthService] Update profile error: $e');
      rethrow;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      print('[AuthService] Changing password');
      final response = await _apiService.put('/auth/profile', data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });

      print('[AuthService] Change password response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
          'Failed to change password: ${response.data['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('[AuthService] Change password error: $e');
      rethrow;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      print('[AuthService] Deleting account');
      final response = await _apiService.delete('/auth/profile');

      print('[AuthService] Delete account response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        await logout();
        return true;
      } else {
        throw Exception(
          'Failed to delete account: ${response.data['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('[AuthService] Delete account error: $e');
      rethrow;
    }
  }
}
