// ignore_for_file: unused_local_variable, deprecated_member_use, unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/viewmodels/pharmacy_viewmodel.dart';
import 'package:smart_pharma_net/models/pharmacy_model.dart';
import 'package:smart_pharma_net/view/Screens/admin_login_screen.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/view/Screens/add_pharmacy_screen.dart';
import 'package:smart_pharma_net/view/Screens/pharmacy_details_screen.dart';
import 'package:smart_pharma_net/view/Screens/add_medicine_screen.dart';
import 'package:smart_pharma_net/view/Screens/pharmacy_login_screen.dart';

class AvailablePharmaciesScreen extends StatefulWidget {
  const AvailablePharmaciesScreen({super.key});

  @override
  State<AvailablePharmaciesScreen> createState() =>
      _AvailablePharmaciesScreenState();
}

class _AvailablePharmaciesScreenState extends State<AvailablePharmaciesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPharmacies() async {
    final pharmacyViewModel = Provider.of<PharmacyViewModel>(context, listen: false);
    pharmacyViewModel.loadPharmacies(searchQuery: '');
  }

  @override
  Widget build(BuildContext context) {
    final pharmacyViewModel = Provider.of<PharmacyViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Pharmacies'),
        centerTitle: true,
        backgroundColor: const Color(0xFF636AE8),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search pharmacies...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                pharmacyViewModel.loadPharmacies(searchQuery: value);
              },
            ),
          ),
          // Pharmacies List
          Expanded(
            child: pharmacyViewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : pharmacyViewModel.pharmacies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_pharmacy,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No pharmacies found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: pharmacyViewModel.pharmacies.length,
                        itemBuilder: (context, index) {
                          final pharmacy = pharmacyViewModel.pharmacies[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: const Color(0xFF636AE8),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PharmacyDetailsScreen(
                                              pharmacy: pharmacy),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Stack(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.location_on,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                pharmacy.name,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.badge,
                                                size: 16,
                                                color: Colors.white70,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'License: ${pharmacy.licenseNumber}',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.phone,
                                                size: 16,
                                                color: Colors.white70,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Phone: N/A',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PharmacyLoginScreen(
                                                          pharmacyId:
                                                              pharmacy.id),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor:
                                                  const Color(0xFF636AE8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text('View Medicines'),
                                          ),
                                        ],
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () async {
                                              final confirmed =
                                                  await showDialog<bool>(
                                                context: context,
                                                barrierDismissible:
                                                    false,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text(
                                                        'Delete Pharmacy'),
                                                    content: Text(
                                                        'Are you sure you want to delete ${pharmacy.name}?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(false),
                                                        child: const Text(
                                                            'Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true),
                                                        child: const Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );

                                              if (confirmed == true &&
                                                  context.mounted) {
                                                try {
                                                  await pharmacyViewModel
                                                      .deletePharmacy(
                                                          pharmacy.id);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Pharmacy deleted successfully'),
                                                        duration: Duration(
                                                            seconds: 2),
                                                      ),
                                                    );
                                                    
                                                    await pharmacyViewModel.loadPharmacies(searchQuery: _searchController.text.trim());
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'Failed to delete pharmacy: $e'),
                                                        backgroundColor:
                                                            Colors.red,
                                                        duration: Duration(
                                                            seconds: 3),
                                                      ),
                                                    );
                                                  }
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddPharmacyScreen(),
            ),
          );

          if (context.mounted) {
            print('Refreshing pharmacy list after add');
            final pharmacyViewModel =
                Provider.of<PharmacyViewModel>(context, listen: false);
            await pharmacyViewModel.loadPharmacies(searchQuery: '');
          }
        },
        backgroundColor: const Color(0xFF636AE8),
        child: const Icon(Icons.add),
      ),
    );
  }
}