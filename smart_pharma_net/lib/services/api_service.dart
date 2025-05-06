import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/pharmacy_model.dart';
typedef Pharmacy = PharmacyModel; // Alias for backward compatibility


class ApiService {
  static const String baseUrl = 'https://smart-pharma-net.vercel.app/';
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey = 'user_role';
  static const int timeoutSeconds = 30;
  static const Duration tokenRefreshThreshold = Duration(minutes: 15);

  // SharedPreferences instance
  late final SharedPreferences _prefs;

  // Initialize SharedPreferences
  Future<SharedPreferences> init() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs;
  }
  
  // Save additional data to SharedPreferences
  Future<void> saveAdditionalData(String key, String value) async {
    try {
      await _prefs.setString(key, value);
      print('Saved additional data: $key = $value');
    } catch (e) {
      print('Error saving additional data: $e');
      rethrow;
    }
  }

  // Token management
  Future<String?> getAccessToken() async {
    return _prefs.getString(tokenKey);
  }

  Future<String?> get _refreshToken async {
    return _prefs.getString(refreshTokenKey);
  }

  Future<String?> get userRole async {
    return _prefs.getString(userRoleKey);
  }

  Future<void> saveTokens(String accessToken, String refreshToken,
      {String role = 'admin'}) async {
    print(
        'Saving tokens - Access Token: ${accessToken.substring(0, min<int>(20, accessToken.length))}');
    await _prefs.setString(tokenKey, accessToken);
    await _prefs.setString(refreshTokenKey, refreshToken);
    await _prefs.setString(userRoleKey, role);
    print('Tokens saved successfully');
  }

  Future<void> _saveTokens(String accessToken, String refreshToken,
      {String role = 'admin'}) async {
    await saveTokens(accessToken, refreshToken, role: role);
  }

  Future<void> clearTokens() async {
    print('Clearing all tokens');
    await _prefs.remove(tokenKey);
    await _prefs.remove(refreshTokenKey);
    await _prefs.remove(userRoleKey);
    print('Tokens cleared successfully');
  }

  Future<void> _clearTokens() async {
    await clearTokens();
  }

  Map<String, String> get headers {
    final token = _prefs.getString(tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, String> get pharmacyHeaders {
    final token = _prefs.getString(tokenKey);
    final role = _prefs.getString(userRoleKey);
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    // Add X-User-Role header only if it's required by the API
    // Some APIs might not need this header
    if (role != null) {
      headers['X-User-Role'] = role;
    }
    
    print('Generated pharmacy headers: $headers');
    return headers;
  }

  // Token validation
  Future<bool> get isTokenExpired async {
    final token = await getAccessToken();
    return token == null || JwtDecoder.isExpired(token);
  }

  Future<bool> get shouldRefreshToken async {
    final token = await getAccessToken();
    if (token == null) return false;

    final expiryDate = JwtDecoder.getExpirationDate(token);
    final timeUntilExpiry = expiryDate.difference(DateTime.now());

    return timeUntilExpiry < tokenRefreshThreshold;
  }

  Future<bool> refreshToken() async {
    print('Attempting to refresh token...');
    try {
      final currentRefreshToken = await _refreshToken;

      if (currentRefreshToken == null) {
        print('No refresh token available');
        return false;
      }

      print('Sending refresh token request with token: ${currentRefreshToken.substring(0, min<int>(10, currentRefreshToken.length))}...');
      
      // Use basic headers without auth token for refresh request
      final refreshHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      final response = await http
          .post(
            Uri.parse('$baseUrl/account/token/refresh/'),
            headers: refreshHeaders,
            body: json.encode({
              'refresh': currentRefreshToken,
            }),
          )
          .timeout(const Duration(seconds: timeoutSeconds));

      print('Refresh token response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newAccessToken = data['access'];
        
        // Keep the current refresh token if a new one isn't provided
        final newRefreshToken = data['refresh'] ?? currentRefreshToken;
        
        // Get the current user role
        final currentRole = await userRole ?? 'admin';
        
        // Save both tokens
        await _saveTokens(newAccessToken, newRefreshToken, role: currentRole);
        print('Token refreshed successfully');
        return true;
      } else if (response.statusCode == 401) {
        // Refresh token is invalid/expired
        print('Refresh token is invalid or expired');
        await _clearTokens();
        return false;
      } else {
        print('Token refresh failed with status ${response.statusCode}: ${response.body}');
        // Don't clear tokens on server errors, only on auth errors
        if (response.statusCode >= 400 && response.statusCode < 500) {
          await _clearTokens();
        }
        return false;
      }
    } catch (e) {
      print('Error refreshing token: $e');
      // Only clear tokens if we're certain it's an auth error
      if (e.toString().contains('401') || 
          e.toString().contains('auth') || 
          e.toString().contains('token')) {
        await _clearTokens();
      }
      return false;
    }
  }

  Future<dynamic> addPharmacy({
    required String name,
    required String city,
    required String licenseNumber,
    required double latitude,
    required double longitude,
    required String password,
    required String confirmPassword,
  }) async {
    return await _authenticatedRequest(() async {
      final token = await getAccessToken();
      if (token == null) {
        throw Exception('Authentication required. Please login again.');
      }

      final requestData = {
        'name': name,
        'city': city,
        'license_number': licenseNumber,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'password': password,
        'confirm_password': confirmPassword,
      };

      print('Adding pharmacy with data: $requestData');

      final response = await http.post(
        Uri.parse('$baseUrl/account/pharmacy/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: timeoutSeconds));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        // If we get 401, try refreshing token once
        final refreshed = await refreshToken();
        if (refreshed) {
          final newToken = await getAccessToken();
          if (newToken != null) {
            // Retry with new token
            final retryResponse = await http.post(
              Uri.parse('$baseUrl/account/pharmacy/'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $newToken',
              },
              body: json.encode(requestData),
            ).timeout(const Duration(seconds: timeoutSeconds));

            return _parseResponse(retryResponse);
          }
        }
        throw Exception('Session expired. Please login again.');
      }

      return _parseResponse(response);
    });
  }

  // Response handling
  dynamic _parseResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }

      try {
        return json.decode(response.body);
      } catch (e) {
        print('Error decoding response body: $e');
        throw Exception('Invalid response format');
      }
    } else {
      try {
        if (response.body.contains('<!doctype html>')) {
          throw Exception('Server error: ${response.statusCode}');
        }
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ??
            errorBody['message'] ??
            'Request failed with status ${response.statusCode}');
      } catch (e) {
        print('Error parsing error response: $e');
        print('Response body: ${response.body}');
        throw Exception('Request failed with status ${response.statusCode}');
      }
    }
  }

  Future<T> _authenticatedRequest<T>(Future<T> Function() request) async {
    try {
      // Check if token is expired
      if (await isTokenExpired) {
        print('Access token is expired, attempting to refresh');
        // If token is completely expired, try to refresh
        final refreshed = await refreshToken();
        if (!refreshed) {
          // If refresh fails, throw an auth error
          print('Token refresh failed, authentication required');
          throw Exception('Authentication required. Please login again.');
        }
      } else if (await shouldRefreshToken) {
        // If token is close to expiry, refresh it preemptively
        print('Token close to expiry, refreshing preemptively');
        await refreshToken();
      }

      // Execute the request
      try {
        return await request();
      } catch (requestError) {
        // Handle 401 responses from the actual request
        if (requestError.toString().contains('401') || 
            requestError.toString().toLowerCase().contains('unauthorized')) {
          print('Received 401 from request, attempting token refresh');
          
          // Try refreshing the token
          final refreshed = await refreshToken();
          if (refreshed) {
            // If refresh succeeds, retry the request
            print('Token refreshed successfully, retrying request');
            return await request();
          } else {
            // If refresh fails, throw auth error
            print('Token refresh failed after 401, authentication required');
            throw Exception('Session expired. Please login again.');
          }
        }
        // If it's not a 401, rethrow
        rethrow;
      }
    } catch (e) {
      // If any error occurs during the request, check if it's an auth error
      if (e.toString().contains('401') ||
          e.toString().contains('authentication') ||
          e.toString().contains('unauthorized') ||
          e.toString().contains('token')) {
        print('Authentication error detected: $e');
        await _clearTokens();
        throw Exception('Session expired. Please login again.');
      }
      rethrow;
    }
  }

  // Authentication endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Attempting login for email: $email');

      final response = await http
          .post(
            Uri.parse(baseUrl + 'account/owner/login/'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: timeoutSeconds));

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = json.decode(response.body);
        print('Login successful, response: $responseBody');

        // Save tokens
        if (responseBody['access'] != null) {
          print('Saving access token...');

          await _saveTokens(
            responseBody['access'],
            responseBody['refresh'] ?? '',
            role: responseBody['role'] ?? 'admin',
          );

          // Verify token was saved
          final savedToken = await getAccessToken();
          print('Verified saved token: $savedToken');
        } else {
          throw Exception('No access token in response');
        }

        return responseBody;
      } else if (response.statusCode == 308) {
        // Handle permanent redirect
        final location = response.headers['location'];
        if (location != null) {
          final redirectResponse = await http
              .post(
                Uri.parse(location),
                headers: headers,
                body: json.encode({
                  'email': email,
                  'password': password,
                }),
              )
              .timeout(const Duration(seconds: timeoutSeconds));

          if (redirectResponse.statusCode == 200) {
            final redirectBody = json.decode(redirectResponse.body);

            // Validate response format
            if (!redirectBody.containsKey('access') ||
                !redirectBody.containsKey('refresh')) {
              throw Exception('Invalid response format from redirect');
            }

            // Save tokens
            await _saveTokens(
              redirectBody['access'],
              redirectBody['refresh'],
              role: redirectBody['role'] ?? 'admin',
            );

            return {
              'access': redirectBody['access'],
              'refresh': redirectBody['refresh'],
              'role': redirectBody['role'] ?? 'admin',
            };
          } else {
            throw Exception('Login failed: Redirect failed');
          }
        } else {
          throw Exception('Login failed: Missing redirect location');
        }
      }

      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      print('Login failed with error: ${errorBody['detail']}');
      throw Exception(errorBody['detail'] ?? 'Login failed');
    } catch (e) {
      print('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<Map<String, dynamic>> registerPharmacy({
    required String name,
    required String city,
    required String latitude,
    required String longitude,
    required String licenseNumber,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      // First, check if user is logged in
      final token = await getAccessToken();
      final refreshToken = await _refreshToken;

      print('Tokennnnnnn: $token');
      print('Refresh Token: $refreshToken');

      if (token == null) {
        // No access token available - user needs to log in
        throw Exception('You need to log in before registering a pharmacy.');
      }

      print('Preparing to add pharmacy with data: ${{
        'name': name,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'license_number': licenseNumber,
        'password': password,
        'confirm_password': confirmPassword,
      }}');

      print('Access Token: ${token.substring(0, min(20, token.length))}...');

      final requestData = {
        'id': 0,
        'name': name,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'license_number': licenseNumber,
        'password': password,
        'confirm_password': confirmPassword,
      };

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      print('Tokennnnnnn: $token');
      print('Refresh Token: $refreshToken');

      print('Request Headers: $headers');
      print('Request Body: ${json.encode(requestData)}');

      final response = await http
          .post(
            Uri.parse(baseUrl + 'account/pharmacy/'),
            headers: headers,
            body: json.encode(requestData),
          )
          .timeout(const Duration(seconds: timeoutSeconds));

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Handle 401 Unauthorized specifically
      if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Parse the response body into a Map
        final dynamic responseData = json.decode(response.body);

        if (responseData is List && responseData.isNotEmpty) {
          // If the API returns a list, take the first item
          return responseData[0] as Map<String, dynamic>;
        } else if (responseData is Map<String, dynamic>) {
          // If the API returns a single object
          return responseData;
        } else {
          throw Exception('Unexpected response format from server');
        }
      }

      // Handle other error responses
      try {
        final errorBody = json.decode(response.body);
        throw Exception(
            'Failed to register pharmacy: ${errorBody['detail'] ?? errorBody['message'] ?? 'Registration failed with status code ${response.statusCode}'}');
      } catch (e) {
        if (e is FormatException) {
          throw Exception(
              'Failed to register pharmacy with status code ${response.statusCode}: ${response.body}');
        }
        rethrow;
      }
    } catch (e) {
      print('Error adding pharmacy: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String gender,
    required String phone,
    required String nationalID,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(baseUrl + 'account/register/'),
            headers: headers,
            body: json.encode({
              'user': {
                'first_name': firstName,
                'last_name': lastName,
                'username': username,
                'email': email,
                'password': password,
              },
              'gender': gender,
              'phone': phone,
              'nationalID': nationalID,
            }),
          )
          .timeout(const Duration(seconds: timeoutSeconds));

      return _parseResponse(response);
    } catch (e) {
      throw Exception(
          'Registration failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> logout() async {
    try {
      // First clear tokens locally to ensure immediate UI response
      await _clearTokens();

      // Then attempt to invalidate on server, but don't wait for response
      final refreshTokenValue = await _refreshToken;
      if (refreshTokenValue != null) {
        http
            .post(
          Uri.parse('$baseUrl/account/logout/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'refresh': refreshTokenValue}),
        )
            .timeout(
          const Duration(seconds: 5), // Shorter timeout for logout
          onTimeout: () {
            // If server request times out, just ignore since tokens are already cleared locally
            return http.Response('', 200);
          },
        );
      }
    } catch (e) {
      // Even if server request fails, we've already cleared local tokens
      print('Logout server notification failed: $e');
    }
  }

  // Pharmacy endpoints
  // Future<List<dynamic>> getAllPharmacies() async {
  //   return await _authenticatedRequest(() async {
  //     return await http.get(
  //       Uri.parse('$baseUrl/account/pharmacy/'),
  //       headers: headers,
  //     );
  //   });
  // }

  // Future<List<dynamic>> searchPharmacies(String query) async {
  //   return await _authenticatedRequest(() async {
  //     return await http.get(
  //       Uri.parse('$baseUrl/account/pharmacy/search?query=${Uri.encodeComponent(query.trim())}'),
  //       headers: headers,
  //     );
  //   });
  // }

  // Future<Map<String, dynamic>> getPharmacyDetails(String id) async {
  //   return await _authenticatedRequest(() async {
  //     return await http.get(
  //       Uri.parse('$baseUrl/account/pharmacy/$id'),
  //       headers: headers,
  //     );
  //   });
  // }

  // Future<List<dynamic>> getNearbyPharmacies(double lat, double lng, double radius) async {
  //   return await _authenticatedRequest(() async {
  //     return await http.get(
  //       Uri.parse('$baseUrl/pharmacy/nearby?lat=$lat&lng=$lng&radius=$radius'),
  //       headers: headers,
  //     );
  //   });
  // }

  // Add a specific method for pharmacy login
  Future<Map<String, dynamic>> pharmacyLogin(
      String name, String password) async {
    try {
      // Ensure the URL has trailing slash and is properly formatted
      const endpoint = 'account/pharmacy/login/';
      final url = '$baseUrl$endpoint';
      
      print('Attempting pharmacy login with name: $name');
      print('Request URL: $url');
      print('Request payload: ${json.encode({
            'name': name.trim(),
            'password': password.trim(),
          })}');

      // Set up request with redirect handling
      final client = http.Client();
      try {
        // Create request manually to follow redirects
        final request = http.Request('POST', Uri.parse(url));
        request.headers['Content-Type'] = 'application/json';
        request.body = json.encode({
          'name': name.trim(),
          'password': password.trim(),
        });
        
        // Send the request and follow redirects
        final streamedResponse = await client.send(request)
            .timeout(const Duration(seconds: timeoutSeconds));
            
        // Get the response after potential redirects
        final response = await http.Response.fromStream(streamedResponse);
        
        print('Pharmacy login response status: ${response.statusCode}');
        print('Pharmacy login response body: ${response.body}');
        
        // Handle different response codes
        if (response.statusCode == 400) {
          final errorBody = json.decode(response.body);
          final errorMessage =
              errorBody['detail'] ?? errorBody['error'] ?? 'Invalid credentials';
          print('Login failed with 400 error: $errorMessage');
          throw Exception(errorMessage);
        }

        if (response.statusCode == 401) {
          print('Login failed with 401 error: Invalid credentials');
          throw Exception('Invalid pharmacy name or password');
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseBody = json.decode(response.body);
          print('Login successful, response body: $responseBody');

          if (!responseBody.containsKey('access') ||
              !responseBody.containsKey('refresh')) {
            print('Invalid response format - missing tokens');
            throw Exception('Invalid response format: missing tokens');
          }
          
          // Extract pharmacy ID directly from the pharmacy object in the response
          String pharmacyId = '';
          if (responseBody.containsKey('pharmacy') && responseBody['pharmacy'] is Map) {
            final pharmacy = responseBody['pharmacy'];
            pharmacyId = pharmacy['id']?.toString() ?? '';
            print('Extracted pharmacy ID from response: $pharmacyId');
          }

          // Save the tokens
          await _saveTokens(responseBody['access'], responseBody['refresh'],
              role: 'pharmacy');

          return {
            'id': pharmacyId,  // Use the extracted pharmacy ID
            'name': name.trim(),
            'access': responseBody['access'],
            'refresh': responseBody['refresh'],
          };
        }

        print('Login failed with unexpected status: ${response.statusCode}');
        throw Exception(
            'Login failed: Unexpected response status ${response.statusCode}');
      } finally {
        client.close(); // Ensure the client is closed
      }
    } catch (e) {
      print('Error in pharmacy login: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addMedicine({
    required String pharmacyLocation,
    required String name,
    required String category,
    required String description,
    required String price,
    required int quantity,
    required String expDate,
    required bool canBeSell,
    required int quantityToSell,
    required String priceSell,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl + 'medicine/medicines/'),
        headers: headers,
        body: json.encode({
          'pharmacy_location': pharmacyLocation,
          'name': name,
          'category': category,
          'description': description,
          'price': price,
          'quantity': quantity,
          'exp_date': expDate,
          'can_be_sell': canBeSell,
          'quantity_to_sell': quantityToSell,
          'price_sell': priceSell,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to add medicine');
      }
    } catch (e) {
      print('Error adding medicine: $e');
      rethrow;
    }
  }

  // HTTP Methods
  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      print('Making GET request to: $baseUrl$endpoint');
      print('Using headers: ${headers ?? this.headers}');

      final response = await http.get(
        Uri.parse(baseUrl + endpoint),
        headers: headers ?? this.headers,
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.body}');
      }
    } catch (e) {
      print('Error in GET request: $e');
      rethrow;
    }
  }

  Future<dynamic> authenticatedGet(String endpoint) async {
    try {
      print('Starting authenticated request...');
      print('Making initial request...');

      final response = await http.get(
        Uri.parse(baseUrl + endpoint),
        headers: pharmacyHeaders,
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        print('Received 401, attempting token refresh...');
        final success = await refreshToken();
        if (success) {
          // Retry the request with new token
          final retryResponse = await http.get(
            Uri.parse(baseUrl + endpoint),
            headers: pharmacyHeaders,
          );

          if (retryResponse.statusCode == 200) {
            return json.decode(retryResponse.body);
          }
        }
        throw Exception('Authentication failed');
      } else {
        throw Exception('Failed to load data: ${response.body}');
      }
    } catch (e) {
      print('Error in authenticated request: $e');
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    try {
      // For authenticated requests, use the authenticated request flow
      final response = await _authenticatedRequest(() async {
        return await http.post(
          Uri.parse(baseUrl + endpoint),
          headers: headers ?? this.headers,
          body: json.encode(data),
        ).timeout(const Duration(seconds: timeoutSeconds));
      });
      return _parseResponse(response);
    } catch (e) {
      print('POST request error: $e');
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    try {
      // For authenticated requests, use the authenticated request flow
      final response = await _authenticatedRequest(() async {
        return await http.put(
          Uri.parse(baseUrl + endpoint),
          headers: headers ?? this.headers,
          body: json.encode(data),
        ).timeout(const Duration(seconds: timeoutSeconds));
      });
      return _parseResponse(response);
    } catch (e) {
      print('PUT request error: $e');
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint, String id, {Map<String, String>? headers}) async {
    try {
      // Ensure we have a valid token before proceeding
      final token = await getAccessToken();
      if (token == null) {
        throw Exception('Authentication required. Please login again.');
      }

      // Construct the full URL with the ID in the path
      final fullUrl = baseUrl + endpoint + id;
      print('DELETE request to: $fullUrl');
      
      // Use pharmacyHeaders which includes the authorization token
      final requestHeaders = headers ?? pharmacyHeaders;
      print('Using headers: $requestHeaders');

      // For authenticated requests, use the authenticated request flow
      final response = await _authenticatedRequest(() async {
        return await http.delete(
          Uri.parse(fullUrl),
          headers: requestHeaders,
        ).timeout(const Duration(seconds: timeoutSeconds));
      });
      
      print('DELETE response status: ${response.statusCode}');
      print('DELETE response body: ${response.body}');
      
      return _parseResponse(response);
    } catch (e) {
      print('DELETE request error: $e');
      rethrow;
    }
  }

  // Utility methods
  Future<bool> get isLoggedIn async {
    final token = await getAccessToken();
    if (token == null) return false;
    return !JwtDecoder.isExpired(token);
  }
}