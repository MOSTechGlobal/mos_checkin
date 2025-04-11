import 'dart:convert';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mos_checkin/utils/prefs.dart';

import '../routes/app_routes.dart';
import 'api_errors/error_dialog.dart';

class Api {
  static const String baseUrl = 'https://api.moscaresolutions.com';
  // static const String baseUrl = 'http://192.168.1.10:5001';
  static Future<String?>? _refreshFuture;

  static Future<String?> _refreshToken() async {
    try {
      final email = await Prefs.getEmail();
      final password = await Prefs.getPassword();
      log('Refreshing token for $email');

      if (email != null && password != null) {
        var credentials = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        String? bearer = await credentials.user!.getIdToken();
        await Prefs.setToken(bearer!);
        return bearer;
      } else {
        // If credentials are missing, navigate to login
        Get.offAllNamed(AppRoutes.login);
        return null;
      }
    } catch (e) {
      log('Error refreshing token: $e');
      showTokenRefreshErrorDialog(); // Show error dialog once here
      return null;
    }
  }

  static Future<dynamic> _makeRequest(String method, String endpoint,
      {Map<String, dynamic>? data}) async {
    final token = await Prefs.getToken();
    final company = await Prefs.getCompanyName();

    final tenantId =
        (company != null && company.isNotEmpty) ? company : 'moscare';
    final bearerToken = 'Bearer $token';
    final uri = Uri.parse('$baseUrl/api/$endpoint');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': bearerToken,
      'x-tenant-id': tenantId,
    };

    http.Response response;
    try {
      if (method == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (method == 'POST') {
        response =
            await http.post(uri, headers: headers, body: jsonEncode(data));
      } else if (method == 'PUT') {
        response =
            await http.put(uri, headers: headers, body: jsonEncode(data));
      } else if (method == 'DELETE') {
        response =
            await http.delete(uri, headers: headers, body: jsonEncode(data));
      } else {
        throw UnsupportedError('Unsupported HTTP method: $method');
      }

      // Parse the response body regardless of status code
      final responseBody = json.decode(response.body);

      // Handle successful response
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseBody;
      }
      // Handle token expiration
      else if (response.statusCode == 403 || response.statusCode == 401) {
        if (_refreshFuture == null) {
          _refreshFuture = _refreshToken();
        }
        String? newToken = await _refreshFuture;
        _refreshFuture = null;

        if (newToken != null) {
          await Prefs.setToken(newToken);
          final newBearerToken = 'Bearer $newToken';
          headers['Authorization'] = newBearerToken;

          if (method == 'GET') {
            response = await http.get(uri, headers: headers);
          } else if (method == 'POST') {
            response =
                await http.post(uri, headers: headers, body: jsonEncode(data));
          } else if (method == 'PUT') {
            response =
                await http.put(uri, headers: headers, body: jsonEncode(data));
          } else if (method == 'DELETE') {
            response = await http.delete(uri,
                headers: headers, body: jsonEncode(data));
          }

          final retryResponseBody = json.decode(response.body);
          if (response.statusCode == 200 || response.statusCode == 201) {
            return retryResponseBody;
          } else {
            log('Error after retry ($method): ${response.statusCode} - ${response.body}');
            return retryResponseBody; // Return error response after retry
          }
        } else {
          log('Token refresh failed for $method $endpoint');
          return responseBody; // Return original error response
        }
      } else {
        log('Error ($method): ${response.statusCode} - ${response.body}');
        return responseBody; // Return error response for non-200/201 status codes
      }
    } catch (e) {
      log('Error ($method): $e');
      // Return a generic error response if JSON parsing or network fails
      return {
        'success': false,
        'message': 'Network or parsing error: $e',
      };
    }
  }

  static Future get(String endpoint, [Map<String, dynamic>? data]) async {
    return await _makeRequest('GET', endpoint, data: data);
  }

  static Future post(String endpoint, Map<String, dynamic> data) async {
    return await _makeRequest('POST', endpoint, data: data);
  }

  static Future put(String endpoint, Map<String, dynamic> data) async {
    return await _makeRequest('PUT', endpoint, data: data);
  }

  static Future delete(String endpoint, [Map<String, dynamic>? data]) async {
    return await _makeRequest('DELETE', endpoint, data: data);
  }
}
