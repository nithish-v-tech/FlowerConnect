import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/shop_model.dart';
import '../models/product_model.dart';

class ApiService {
  // Configurable base URL: 10.0.2.2 for Android emulator, 127.0.0.1 for Desktop/Web
  static String baseUrl = defaultTargetPlatform == TargetPlatform.android && !kIsWeb
      ? 'http://10.0.2.2:8000'
      : 'http://127.0.0.1:8000';

  static String? authToken;
  static bool isBackendOnline = false;
  static Duration requestTimeout = const Duration(seconds: 2);

  static Map<String, String> get _headers {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authToken != null) {
      map['Authorization'] = 'Bearer $authToken';
    }
    return map;
  }

  /// Health check to detect if FastAPI server is reachable
  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(requestTimeout);
      isBackendOnline = response.statusCode == 200;
      return isBackendOnline;
    } catch (_) {
      isBackendOnline = false;
      return false;
    }
  }

  /// Request 6-digit OTP from FastAPI backend
  static Future<Map<String, dynamic>> requestOtp(String phone) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/request-otp'),
            headers: _headers,
            body: jsonEncode({'phone': phone}),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        isBackendOnline = true;
        return jsonDecode(response.body);
      } else {
        final err = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': err['detail'] ?? 'Failed to send OTP.'
        };
      }
    } catch (e) {
      debugPrint('[ApiService] requestOtp offline fallback: $e');
      isBackendOnline = false;
      // Resilient local simulation fallback
      return {
        'status': 'success',
        'phone': phone,
        'otp_code': '123456',
        'message': 'Simulated OTP sent (Offline Mode)'
      };
    }
  }

  /// Verify OTP and receive JWT Bearer token + User profile
  static Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
    String? fullName,
    UserRole? role,
    String? shopName,
    String? shopType,
    String? address,
  }) async {
    try {
      final payload = <String, dynamic>{
        'phone': phone,
        'otp': otp,
      };
      if (fullName != null) payload['full_name'] = fullName;
      if (role != null) payload['role'] = _roleToBackendString(role);
      if (shopName != null) payload['shop_name'] = shopName;
      if (shopType != null) payload['shop_type'] = shopType;
      if (address != null) payload['address'] = address;

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/verify-otp'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        isBackendOnline = true;
        final data = jsonDecode(response.body);
        if (data['access_token'] != null) {
          authToken = data['access_token'];
        }
        return data;
      } else {
        final err = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': err['detail'] ?? 'Failed to verify OTP.'
        };
      }
    } catch (e) {
      debugPrint('[ApiService] verifyOtp offline fallback: $e');
      isBackendOnline = false;
      return {'status': 'offline'};
    }
  }

  /// Complete new profile registration in backend
  static Future<Map<String, dynamic>> registerProfile({
    required String phone,
    required String fullName,
    required UserRole role,
    String? email,
    String? shopName,
    String? shopType,
    String? shopAddress,
  }) async {
    try {
      final payload = <String, dynamic>{
        'phone': phone,
        'otp': '123456',
        'full_name': fullName,
        'role': _roleToBackendString(role),
      };
      if (shopName != null) payload['shop_name'] = shopName;
      if (shopType != null) payload['shop_type'] = shopType;
      if (shopAddress != null) payload['address'] = shopAddress;

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/register'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        isBackendOnline = true;
        final data = jsonDecode(response.body);
        if (data['access_token'] != null) {
          authToken = data['access_token'];
        }
        return data;
      } else {
        final err = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': err['detail'] ?? 'Registration failed.'
        };
      }
    } catch (e) {
      debugPrint('[ApiService] registerProfile offline: $e');
      isBackendOnline = false;
      return {'status': 'offline'};
    }
  }

  /// Fetch shops list dynamically from FastAPI database
  static Future<List<ShopModel>?> fetchShops() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/shops/'), headers: _headers)
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        isBackendOnline = true;
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => ShopModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('[ApiService] fetchShops offline fallback: $e');
      isBackendOnline = false;
    }
    return null;
  }

  /// Fetch products list dynamically from FastAPI database
  static Future<List<ProductModel>?> fetchProducts({String? shopId}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/products/').replace(
        queryParameters: shopId != null ? {'shop_id': shopId} : null,
      );
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        isBackendOnline = true;
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => ProductModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('[ApiService] fetchProducts offline fallback: $e');
      isBackendOnline = false;
    }
    return null;
  }

  /// Admin approves a pending merchant in FastAPI database
  static Future<bool> approveVendor(String shopId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/admin/vendors/approve/$shopId'),
            headers: _headers,
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        isBackendOnline = true;
        return true;
      }
    } catch (e) {
      debugPrint('[ApiService] approveVendor error: $e');
    }
    return false;
  }

  /// Fetch platform financial metrics from FastAPI database
  static Future<Map<String, dynamic>?> fetchAdminMetrics() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/admin/metrics'), headers: _headers)
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        isBackendOnline = true;
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService] fetchAdminMetrics offline: $e');
    }
    return null;
  }

  static String _roleToBackendString(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'CUSTOMER';
      case UserRole.flowerMerchant:
        return 'FLOWER_MERCHANT';
      case UserRole.bouquetMerchant:
        return 'BOUQUET_MERCHANT';
      case UserRole.giftMerchant:
        return 'GIFT_MERCHANT';
      case UserRole.deliveryPartner:
        return 'DELIVERY_PARTNER';
      case UserRole.admin:
        return 'ADMIN';
    }
  }
}
