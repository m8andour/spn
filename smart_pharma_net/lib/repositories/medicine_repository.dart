import '../models/medicine_model.dart';
import '../services/api_service.dart';

class MedicineRepository {
  final ApiService _apiService;
  // Update the endpoint to match the API structure
  static final String _endpoint = 'medicine/medicines/';
  static const String _searchEndpoint = 'medicine/search_medicine/';
  
  // Helper method to process API responses for medicines
  List<MedicineModel> _processMedicineList(dynamic response, String source) {
    print('Response received from $source: $response');
    
    if (response is List) {
      final medicines = response.map((json) => MedicineModel.fromJson(json)).toList();
      print('Successfully parsed ${medicines.length} medicines from $source');
      return medicines;
    }
    print('Invalid response format from $source: $response');
    return []; // Return empty list instead of throwing exception
  }

  MedicineRepository(this._apiService);

  Future<List<MedicineModel>> getAllMedicines() async {
    try {
      print('Getting all medicines...');
      print('Using headers: ${_apiService.headers}');
      
      // For viewing medicines, use regular headers (no authentication required)
      final response = await _apiService.get(_endpoint);
      
      return _processMedicineList(response, 'all-medicines');
    } catch (e) {
      print('Error getting medicines: $e');
      return []; // Return empty list instead of throwing exception
    }
  }

  Future<List<MedicineModel>> getMedicinesForPharmacy(String pharmacyId) async {
    try {
      print('Getting medicines for pharmacy: $pharmacyId');
      print('Using headers: ${_apiService.pharmacyHeaders}');
      
      // تجربة الحصول على جميع الأدوية ثم تصفيتها بناءً على معرف الصيدلية
      // بدلاً من محاولة استخدام نقطة نهاية مخصصة للصيدلية
      print('Fetching all medicines and filtering by pharmacy ID: $pharmacyId');
      
      try {
        // عنوان الحصول على جميع الأدوية
        final response = await _apiService.authenticatedGet(_endpoint);
        
        print('Successfully fetched all medicines, now filtering for pharmacy ID: $pharmacyId');
        
        if (response is List) {
          // تحويل الاستجابة إلى قائمة من الأدوية
          final allMedicines = response.map((json) => MedicineModel.fromJson(json)).toList();
          
          // تصفية الأدوية بناءً على معرف الصيدلية
          final pharmacyMedicines = allMedicines.where((medicine) {
            // التحقق من أن معرف الصيدلية للدواء يطابق المعرف المطلوب
            // قد تحتاج إلى تعديل هذا الشرط بناءً على بنية البيانات الفعلية
            final medicinePharmacyId = medicine.pharmacyId.toString();
            return medicinePharmacyId == pharmacyId;
          }).toList();
          
          print('Found ${pharmacyMedicines.length} medicines for pharmacy $pharmacyId');
          return pharmacyMedicines;
        }
        throw Exception('Invalid response format for medicines');
      } catch (e) {
        print('Error fetching medicines: $e');
        // كخيار أخير، إرجاع قائمة فارغة بدلاً من إلقاء استثناء
        print('Returning empty medicine list for pharmacy $pharmacyId due to error');
        return [];
      }
    } catch (e) {
      print('Error getting medicines for pharmacy: $e');
      // إرجاع قائمة فارغة في حالة حدوث خطأ
      return [];
    }
  }

  Future<List<MedicineModel>> searchMedicines(String query) async {
    try {
      print('Searching medicines with query: $query');
      print('Using headers: ${_apiService.headers}');
      
      final response = await _apiService.get(_searchEndpoint, headers: _apiService.headers);
      
      print('Search response received: $response');
      
      if (response is List) {
        final medicines = response.map((json) => MedicineModel.fromJson(json)).toList();
        print('Successfully parsed ${medicines.length} medicines from search');
        return medicines;
      }
      print('Invalid search response format: $response');
      throw Exception('Invalid search response format');
    } catch (e) {
      print('Error searching medicines: $e');
      rethrow;
    }
  }

  Future<MedicineModel> getMedicineDetails(String id) async {
    try {
      print('Getting medicine details for ID: $id');
      print('Using headers: ${_apiService.headers}');
      
      // For viewing medicine details, use regular headers
      final response = await _apiService.get('$_endpoint$id/', headers: _apiService.headers);
      
      print('Medicine details response: $response');
      return MedicineModel.fromJson(response);
    } catch (e) {
      print('Error getting medicine details: $e');
      rethrow;
    }
  }

  Future<MedicineModel> addMedicine(Map<String, dynamic> medicineData) async {
    try {
      print('Adding new medicine...');
      print('Medicine data: $medicineData');
      
      // Validate required fields
      if (!medicineData.containsKey('pharmacy') || medicineData['pharmacy'] == null) {
        throw Exception('Pharmacy ID is required');
      }

      // For adding medicines, we need pharmacy authentication
      final role = await _apiService.userRole;
      print('Current user role: $role');
      
      if (role != 'pharmacy') {
        throw Exception('You must be logged in as a pharmacy to add medicines');
      }
      
      print('Using pharmacy headers: ${_apiService.pharmacyHeaders}');
      final response = await _apiService.post(_endpoint, medicineData, headers: _apiService.pharmacyHeaders);
      print('Add medicine response: $response');
      
      if (response == null) {
        throw Exception('Failed to add medicine: No response from server');
      }
      
      return MedicineModel.fromJson(response);
    } catch (e) {
      print('Error adding medicine: $e');
      if (e.toString().contains('400')) {
        throw Exception('Invalid medicine data. Please check your inputs.');
      } else if (e.toString().contains('401')) {
        throw Exception('Unauthorized. Please login as a pharmacy.');
      } else if (e.toString().contains('403')) {
        throw Exception('Forbidden. You do not have permission to add medicines.');
      } else if (e.toString().contains('FormatException')) {
        throw Exception('Invalid pharmacy ID format. Please check the pharmacy ID.');
      } else {
        throw Exception('Failed to add medicine: ${e.toString()}');
      }
    }
  }

  Future<MedicineModel> updateMedicine(String id, Map<String, dynamic> medicineData) async {
    try {
      print('Updating medicine with ID: $id');
      print('Update data: $medicineData');
      
      // For updating medicines, we need pharmacy authentication
      final role = await _apiService.userRole;
      print('Current user role: $role');
      
      if (role != 'pharmacy') {
        throw Exception('You must be logged in as a pharmacy to update medicines');
      }
      
      print('Using pharmacy headers: ${_apiService.pharmacyHeaders}');
      final response = await _apiService.put('$_endpoint$id/', medicineData, headers: _apiService.pharmacyHeaders);
      print('Update response: $response');
      return MedicineModel.fromJson(response);
    } catch (e) {
      print('Error updating medicine in repository: $e');
      rethrow;
    }
  }

  Future<void> deleteMedicine(String id) async {
    try {
      print('Deleting medicine with ID: $id');
      
      // For deleting medicines, we need pharmacy authentication
      final role = await _apiService.userRole;
      print('Current user role: $role');
      
      if (role != 'pharmacy') {
        throw Exception('You must be logged in as a pharmacy to delete medicines');
      }
      
      print('Using pharmacy headers: ${_apiService.pharmacyHeaders}');
      await _apiService.delete('$_endpoint$id/', '', headers: _apiService.pharmacyHeaders);
      print('Medicine deleted successfully');
    } catch (e) {
      print('Error deleting medicine: $e');
      rethrow;
    }
  }
} 