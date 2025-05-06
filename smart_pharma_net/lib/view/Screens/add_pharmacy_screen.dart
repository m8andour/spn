// ignore_for_file: deprecated_member_use, unnecessary_null_comparison, unused_import

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/viewmodels/pharmacy_viewmodel.dart';

class AddPharmacyScreen extends StatefulWidget {
  const AddPharmacyScreen({super.key});

  @override
  State<AddPharmacyScreen> createState() => _AddPharmacyScreenState();
}

class _AddPharmacyScreenState extends State<AddPharmacyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  LatLng? _selectedLocation;
  bool _isLoading = false;
  late final MapController _mapController;
  bool _isMapReady = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _getCurrentLocation());
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
        _isMapReady = true;
      });

      _mapController.move(_selectedLocation!, 15.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        final pharmacyViewModel = Provider.of<PharmacyViewModel>(context, listen: false);

        final latitude = double.parse(_latitudeController.text);
        final longitude = double.parse(_longitudeController.text);

        await pharmacyViewModel.addPharmacy(
          name: _nameController.text,
          city: _cityController.text,
          licenseNumber: _licenseNumberController.text,
          latitude: latitude,
          longitude: longitude,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pharmacy added successfully')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Error adding pharmacy';
          if (e.toString().contains('Authentication') || 
              e.toString().contains('login') ||
              e.toString().contains('Session expired')) {
            errorMessage = 'Session expired. Please login again.';
            // You might want to navigate to login screen here
          } else {
            errorMessage = e.toString();
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Pharmacy'),
        centerTitle: true,
        backgroundColor: const Color(0xFF636AE8),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(_nameController, 'name', 'Please enter pharmacy name'),
                    const SizedBox(height: 16),
                    _buildTextField(_cityController, 'city', 'Please enter city name'),
                    const SizedBox(height: 16),
                    _buildTextField(_licenseNumberController, 'license_number', 'Please enter license number'),
                    const SizedBox(height: 16),
                    _buildMapSection(),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use Current Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF636AE8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLatLngFields(),
                    const SizedBox(height: 16),
                    _buildPasswordFields(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String errorText) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return errorText;
        return null;
      },
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _selectedLocation ?? const LatLng(31.9539, 35.9106),
            zoom: 13.0,
            onMapReady: () => setState(() => _isMapReady = true),
            onTap: (_, point) {
              setState(() {
                _selectedLocation = point;
                _latitudeController.text = point.latitude.toStringAsFixed(6);
                _longitudeController.text = point.longitude.toStringAsFixed(6);
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            if (_selectedLocation != null && _isMapReady)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: Color(0xFF636AE8), size: 40),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatLngFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _latitudeController,
            keyboardType: TextInputType.number,
            decoration: _latLngDecoration('Latitude'),
            validator: _latLngValidator,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _longitudeController,
            keyboardType: TextInputType.number,
            decoration: _latLngDecoration('Longitude'),
            validator: _latLngValidator,
          ),
        ),
      ],
    );
  }

  InputDecoration _latLngDecoration(String label) {
    return InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.location_on),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  String? _latLngValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a value';
    }
    final double? num = double.tryParse(value);
    if (num == null) {
      return 'Please enter a valid number';
    }
    String formatted = num.toStringAsFixed(4);
    String digitsOnly = formatted.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length > 9) {
      return 'Maximum 9 digits allowed';
    }
    return null;
  }

  Widget _buildPasswordFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: _passwordDecoration('Password'),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter password';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_showPassword,
            decoration: _passwordDecoration('Confirm Password'),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please confirm password';
              if (value != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
        ),
      ],
    );
  }

  InputDecoration _passwordDecoration(String label) {
    return InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      suffixIcon: IconButton(
        icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
        onPressed: () => setState(() => _showPassword = !_showPassword),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF636AE8),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Add Pharmacy', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFF636AE8)),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16, color: Color(0xFF636AE8)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _licenseNumberController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mapController.dispose();
    super.dispose();
  }
}
