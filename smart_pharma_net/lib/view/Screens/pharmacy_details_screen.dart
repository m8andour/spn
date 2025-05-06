import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pharmacy_model.dart';
import '../../viewmodels/pharmacy_viewmodel.dart';
import 'add_medicine_screen.dart';

class PharmacyDetailsScreen extends StatelessWidget {
  final PharmacyModel pharmacy;

  const PharmacyDetailsScreen({Key? key, required this.pharmacy}) : super(key: key);

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Pharmacy'),
          content: Text('Are you sure you want to delete ${pharmacy.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final viewModel = Provider.of<PharmacyViewModel>(context, listen: false);
      try {
        await viewModel.deletePharmacy(pharmacy.id);
        if (context.mounted) {
          // Pop twice to go back to Available Pharmacies screen
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pharmacy deleted successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete pharmacy: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pharmacy.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMedicineScreen(
                pharmacyId: pharmacy.id,
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF636AE8),
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                title: Text('Name: ${pharmacy.name}'),
                subtitle: Text('City: ${pharmacy.city}'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('Location'),
                subtitle: Text(
                  'Latitude: ${pharmacy.latitude}\nLongitude: ${pharmacy.longitude}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('License Information'),
                subtitle: Text('License Number: ${pharmacy.licenseNumber}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 