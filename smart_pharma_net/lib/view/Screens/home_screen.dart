// ignore_for_file: unused_local_variable, unnecessary_null_comparison, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/view/Screens/menu_bar_screen.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/pharmacy_viewmodel.dart';
import '../../viewmodels/medicine_viewmodel.dart';
import '../../models/medicine_model.dart';
import '../../models/pharmacy_model.dart';
import 'add_medicine_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAdmin = false;
  final Map<String, PharmacyModel> _pharmacyCache = {};

  @override
  void initState() {
    super.initState();
    // Load all medicines when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicineViewModel>().loadMedicines();
      // Check if user is admin
      final authViewModel = context.read<AuthViewModel>();
      _isAdmin = authViewModel.isAdmin;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    try {
      await authViewModel.logout();
      if (mounted) {
        // Navigate to welcome screen and clear all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/welcome',
          (route) => false,  // This removes all previous routes
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadPharmacyDetails(String pharmacyId) async {
    if (!_pharmacyCache.containsKey(pharmacyId)) {
      try {
        final pharmacyViewModel = Provider.of<PharmacyViewModel>(context, listen: false);
        final pharmacy = await pharmacyViewModel.getPharmacyDetails(pharmacyId);
        if (mounted) {
          setState(() {
            _pharmacyCache[pharmacyId] = pharmacy;
          });
        }
      } catch (e) {
        print('Error loading pharmacy details: $e');
      }
    }
  }

  void _showMedicineDetails(MedicineModel medicine) async {
    await _loadPharmacyDetails(medicine.pharmacyId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  medicine.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Category', medicine.category),
                _buildDetailRow('Description', medicine.description),
                _buildDetailRow('Price', '\$${medicine.price}'),
                _buildDetailRow('Quantity', '${medicine.quantity} units'),
                _buildDetailRow('Expiry Date', medicine.expiryDate),
                _buildDetailRow('Pharmacy', _pharmacyCache[medicine.pharmacyId]?.name ?? 'Loading...'),
                _buildDetailRow('Location', _pharmacyCache[medicine.pharmacyId]?.city ?? 'Loading...'),
                if (!_isAdmin) ...[
                  _buildDetailRow('Sell Price', '\$${medicine.priceSell}'),
                  _buildDetailRow('Quantity To Sell', '${medicine.quantityToSell} units'),
                ],
                const SizedBox(height: 20),
                if (_isAdmin)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Check if user is logged in as pharmacy
                            final role = await context.read<AuthViewModel>().getUserRole();
                            if (role != 'pharmacy') {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('You must be logged in as a pharmacy to edit medicines'),
                                  ),
                                );
                              }
                              return;
                            }
                            
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              '/add_medicine',
                              arguments: medicine,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF636AE8),
                          ),
                          child: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Check if user is logged in as pharmacy
                            final role = await context.read<AuthViewModel>().getUserRole();
                            if (role != 'pharmacy') {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('You must be logged in as a pharmacy to delete medicines'),
                                  ),
                                );
                              }
                              return;
                            }
                            
                            Navigator.pop(context);
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm Delete'),
                                content: const Text('Are you sure you want to delete this medicine?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && mounted) {
                              try {
                                await context.read<MedicineViewModel>().deleteMedicine(medicine.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Medicine deleted successfully')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: ${e.toString()}')),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement buy medicine functionality
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF636AE8),
                      ),
                      child: const Text('Buy Now'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart PharmaNet'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MenuBarScreen(),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF636AE8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 35,
                      color: Color(0xFF636AE8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Welcome, ${_isAdmin ? 'Admin' : 'User'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            if (_isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add Medicine'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/add_medicine');
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _handleLogout(context);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                // Check if user is logged in as pharmacy
                final role = await context.read<AuthViewModel>().getUserRole();
                if (role != 'pharmacy') {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You must be logged in as a pharmacy to add medicines'),
                      ),
                    );
                  }
                  return;
                }

                // Get the pharmacy ID from the auth view model
                final pharmacyId = await context.read<AuthViewModel>().getPharmacyId();
                if (pharmacyId == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not get pharmacy ID. Please try logging in again.'),
                      ),
                    );
                  }
                  return;
                }

                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMedicineScreen(
                        pharmacyId: pharmacyId,
                      ),
                    ),
                  );
                }
              },
              backgroundColor: const Color(0xFF636AE8),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: const Color(0xFF636AE8),
            child: SafeArea(
              child: Column(
                children: [
                  const Text(
                    'Available Medications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search medicines...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                      if (value.isEmpty) {
                        context.read<MedicineViewModel>().loadMedicines();
                      } else {
                        context.read<MedicineViewModel>().searchMedicines(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          // Medicines List
          Expanded(
            child: Consumer<MedicineViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (viewModel.error.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${viewModel.error}'),
                        ElevatedButton(
                          onPressed: () => viewModel.loadMedicines(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (viewModel.medicines.isEmpty) {
                  return const Center(
                    child: Text('No medicines found'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => viewModel.loadMedicines(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: viewModel.medicines.length,
                    itemBuilder: (context, index) {
                      final medicine = viewModel.medicines[index];
                      return _buildMedicineCard(medicine);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(MedicineModel medicine) {
    // Load pharmacy details if not already loaded
    _loadPharmacyDetails(medicine.pharmacyId);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF636AE8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                medicine.category,
                style: const TextStyle(
                  color: Color(0xFF636AE8),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              medicine.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '\$${medicine.price}',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF636AE8),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Stock: ${medicine.quantity} units',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Text(
              'Exp: ${medicine.expiryDate}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Text(
              'At: ${_pharmacyCache[medicine.pharmacyId]?.name ?? 'Loading...'}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            if (!_isAdmin && medicine.canBeSell) ...[
              const SizedBox(height: 4),
              Text(
                'Sell Price: \$${medicine.priceSell}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Available to sell: ${medicine.quantityToSell} units',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showMedicineDetails(medicine),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF636AE8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(_isAdmin ? 'Manage' : 'View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}