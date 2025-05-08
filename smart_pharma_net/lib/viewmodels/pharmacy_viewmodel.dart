// ignore_for_file: unnecessary_null_comparison, unused_import

import 'package:flutter/foundation.dart';
import 'package:smart_pharma_net/models/pharmacy_model.dart';
import 'package:smart_pharma_net/repositories/pharmacy_repository.dart';
import 'package:smart_pharma_net/services/api_service.dart';
import 'package:smart_pharma_net/viewmodels/base_viewmodel.dart';

class PharmacyViewModel extends ChangeNotifier {
  final PharmacyRepository _pharmacyRepository;
  List<PharmacyModel> _pharmacies = [];
  bool _isLoading = false;
  String _error = '';

  PharmacyViewModel(this._pharmacyRepository);

  List<PharmacyModel> get pharmacies => _pharmacies;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> addPharmacy({
    required String name,
    required String city,
    required String licenseNumber,
    required double latitude,
    required double longitude,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final pharmacyData = {
        'name': name.trim(),
        'city': city.trim(),
        'license_number': licenseNumber.trim(),
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'password': password,
        'confirm_password': confirmPassword,
      };

      await _pharmacyRepository.addPharmacy(pharmacyData);
      await loadPharmacies(searchQuery: '');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Failed to add pharmacy: $e');
    }
  }

  Future<void> loadPharmacies({required String searchQuery}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _pharmacies = await _pharmacyRepository.getAllPharmacies();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PharmacyModel> getPharmacyDetails(String id) async {
    try {
      return await _pharmacyRepository.getPharmacyDetails(id);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> deletePharmacy(String pharmacyId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _pharmacyRepository.deletePharmacy(pharmacyId);
      _pharmacies.removeWhere((pharmacy) => pharmacy.id == pharmacyId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  loadMedicines(String pharmacyId) {}
}