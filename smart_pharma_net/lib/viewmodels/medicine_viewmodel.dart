import 'package:flutter/foundation.dart';
import '../models/medicine_model.dart';
import '../repositories/medicine_repository.dart';

class MedicineViewModel extends ChangeNotifier {
  final MedicineRepository _medicineRepository;
  List<MedicineModel> _medicines = [];
  bool _isLoading = false;
  String _error = '';

  MedicineViewModel(this._medicineRepository);

  List<MedicineModel> get medicines => _medicines;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> loadMedicines({String? pharmacyId}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      if (pharmacyId != null) {
        _medicines = await _medicineRepository.getMedicinesForPharmacy(pharmacyId);
      } else {
        _medicines = await _medicineRepository.getAllMedicines();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchMedicines(String query) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _medicines = await _medicineRepository.searchMedicines(query);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMedicine({
    required String name,
    required String description,
    required double price,
    required int quantity,
    required String pharmacyId,
    required String category,
    required String expiryDate,
    required bool canBeSell,
    required int quantityToSell,
    required double priceSell,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate pharmacy ID
      if (pharmacyId.isEmpty) {
        throw Exception('Pharmacy ID is required');
      }

      int pharmacyIdInt;
      try {
        pharmacyIdInt = int.parse(pharmacyId);
      } catch (e) {
        throw Exception('Invalid pharmacy ID format');
      }

      final medicineData = {
        'name': name.trim(),
        'category': category.trim(),
        'description': description.trim(),
        'price': price.toString(),
        'quantity': quantity,
        'exp_date': expiryDate,
        'pharmacy': pharmacyIdInt,
        'can_be_sell': canBeSell,
        'quantity_to_sell': quantityToSell,
        'price_sell': priceSell.toString(),
      };

      print('Adding medicine with data: $medicineData');
      await _medicineRepository.addMedicine(medicineData);
      await loadMedicines();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      print('Error adding medicine: $e');
      throw Exception('Failed to add medicine: $e');
    }
  }

  Future<void> updateMedicine({
    required String name,
    required String description,
    required double price,
    required int quantity,
    required String category,
    required String expiryDate,
    required String Id,
    required String id,
    required bool canBeSell,
    required int quantityToSell,
    required double priceSell,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Preparing to update medicine with ID: $Id');
      print('Pharmacy ID for update: $id');
      
      if (id.isEmpty) {
        throw Exception('Pharmacy ID is required for updating medicine');
      }

      final medicineData = {
        'name': name.trim(),
        'category': category.trim(),
        'description': description.trim(),
        'price': price.toString(),
        'quantity': quantity,
        'exp_date': expiryDate,
        'pharmacy': int.parse(id),
        'can_be_sell': canBeSell,
        'quantity_to_sell': quantityToSell,
        'price_sell': priceSell.toString(),
      };
      print('Update payload: $medicineData');

      await _medicineRepository.updateMedicine(Id, medicineData);
      await loadMedicines();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      print('Error in viewmodel while updating medicine: $e');
      throw Exception('Failed to update medicine: $e');
    }
  }

  Future<void> deleteMedicine(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _medicineRepository.deleteMedicine(id);
      _medicines.removeWhere((medicine) => medicine.id == id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Failed to delete medicine: $e');
    }
  }

  Future<MedicineModel> getMedicineDetails(String id) async {
    try {
      return await _medicineRepository.getMedicineDetails(id);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
} 