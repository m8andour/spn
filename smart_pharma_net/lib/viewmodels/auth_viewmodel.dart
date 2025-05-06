import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_pharma_net/repositories/auth_repository.dart';
import 'package:smart_pharma_net/viewmodels/base_viewmodel.dart';
import 'package:smart_pharma_net/services/api_service.dart';

class AuthViewModel extends BaseViewModel {
  final AuthRepository _authRepository;
  final ApiService _apiService;
  bool _isAdmin = false;
  bool _isPharmacy = false;

  AuthViewModel(this._authRepository, this._apiService);

  bool get isAdmin => _isAdmin;
  bool get isPharmacy => _isPharmacy;

  Future<bool> login(String email, String password) async {
    setLoading(true);
    setError(null);
    
    try {
      print('Attempting admin login with email: $email');
      final result = await _authRepository.login(email, password);
      
      print('Admin login response in viewmodel: $result');
      
      if (result != null) {
        final accessToken = result['access']?.toString();
        final refreshToken = result['refresh']?.toString();
        
        if (accessToken == null || refreshToken == null) {
          throw Exception('Invalid response: missing tokens');
        }
        
        print('Saving admin tokens and role');
        await _authRepository.saveTokens(
          accessToken,
          refreshToken,
          role: 'admin'
        );
        
        _isAdmin = true;
        _isPharmacy = false;
        notifyListeners();
        
        print('Admin login successful');
        return true;
      }
      
      throw Exception('Invalid admin credentials');
    } catch (e) {
      print('Admin login error: $e');
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String gender,
    required String phone,
    required String nationalID,
  }) async {
    setLoading(true);
    setError(null);
    
    try {
      final result = await _authRepository.register(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        password: password,
        gender: gender,
        phone: phone,
        nationalID: nationalID,
      );
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _isAdmin = false;
    _isPharmacy = false;
    notifyListeners();
  }

  Future<bool> isLoggedIn() async {
    final isValid = await _authRepository.isLoggedIn();
    if (isValid) {
      final role = await getUserRole();
      _isAdmin = role == 'admin';
      _isPharmacy = role == 'pharmacy';
      notifyListeners();
    }
    print('Token validation check - IsLoggedIn: $isValid');
    return isValid;
  }

  Future<String?> getUserRole() async {
    final role = await _authRepository.getUserRole();
    print('Getting user role: $role');
    return role;
  }

  Future<String> pharmacyLogin({
    required String name,
    required String password,
  }) async {
    try {
      print('Attempting pharmacy login for: $name');
      final response = await _apiService.pharmacyLogin(name, password);

      print('Pharmacy login response: $response');

      if (response != null) {
        final pharmacyId = response['id']?.toString();
        final pharmacyName = response['name']?.toString();
        
        print('Extracted pharmacy data - ID: $pharmacyId, Name: $pharmacyName');
        print('Expected pharmacy name: $name');
        
        if (pharmacyId == null || pharmacyId.isEmpty) {
          print('Invalid response format - missing pharmacy ID');
          throw Exception('Access denied. This account does not have permission to access this pharmacy.');
        }
        
        if (pharmacyName == null || pharmacyName.toLowerCase() != name.toLowerCase()) {
          print('Name mismatch - Response: $pharmacyName, Expected: $name');
          throw Exception('Invalid pharmacy credentials - wrong pharmacy');
        }

        final accessToken = response['access'];
        final refreshToken = response['refresh'];
        
        print('Saving tokens - Access: ${accessToken != null}, Refresh: ${refreshToken != null}');
        
        await _authRepository.saveTokens(
          accessToken,
          refreshToken,
          role: 'pharmacy',
          additionalData: {'pharmacy_id': pharmacyId},
        );
        _isAdmin = false;
        _isPharmacy = true;
        notifyListeners();
        
        print('Login successful for pharmacy: $pharmacyName (ID: $pharmacyId)');
        return pharmacyId;
      } else {
        print('Empty response from server');
        throw Exception('Login failed: Invalid response');
      }
    } catch (e) {
      print('Pharmacy login error: $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<String?> getPharmacyId() async {
    try {
      final role = await _apiService.userRole;
      if (role != 'pharmacy') {
        print('Not logged in as pharmacy, cannot get pharmacy ID');
        return null;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final storedId = prefs.getString('pharmacy_id');
      
      if (storedId != null && storedId.isNotEmpty) {
        print('Retrieved pharmacy ID from local storage: $storedId');
        return storedId;
      }
      
      print('No pharmacy ID in local storage, trying API call');
      try {
        final response = await _apiService.get('account/pharmacy/me');
        if (response != null && response.containsKey('id')) {
          final apiPharmacyId = response['id'].toString();
          print('Retrieved pharmacy ID from API: $apiPharmacyId');
          
          await _apiService.saveAdditionalData('pharmacy_id', apiPharmacyId);
          
          return apiPharmacyId;
        }
      } catch (apiError) {
        print('Error getting pharmacy ID from API: $apiError');
      }
      
      print('Could not retrieve pharmacy ID from any source');
      return null;
    } catch (e) {
      print('Error getting pharmacy ID: $e');
      return null;
    }
  }
}