import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/repositories/auth_repository.dart';
import 'package:smart_pharma_net/repositories/medicine_repository.dart';
import 'package:smart_pharma_net/repositories/pharmacy_repository.dart';
import 'package:smart_pharma_net/services/api_service.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/medicine_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/pharmacy_viewmodel.dart';
import 'package:smart_pharma_net/view/Screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize ApiService
  final apiService = ApiService();
  await apiService.init();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => apiService,
        ),
        Provider<MedicineRepository>(
          create: (context) => MedicineRepository(
            context.read<ApiService>(),
          ),
        ),
        ChangeNotifierProvider<MedicineViewModel>(
          create: (context) => MedicineViewModel(
            context.read<MedicineRepository>(),
          ),
        ),
        ProxyProvider<ApiService, AuthRepository>(
          update: (_, apiService, __) => AuthRepository(apiService),
        ),
        ProxyProvider<ApiService, PharmacyRepository>(
          update: (_, apiService, __) => PharmacyRepository(apiService),
        ),
        ChangeNotifierProxyProvider2<AuthRepository, ApiService, AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthRepository>(),
            context.read<ApiService>(),
          ),
          update: (context, authRepo, apiService, previous) => 
            previous ?? AuthViewModel(authRepo, apiService),
        ),
        ChangeNotifierProxyProvider<PharmacyRepository, PharmacyViewModel>(
          create: (context) => PharmacyViewModel(context.read<PharmacyRepository>()),
          update: (context, pharmacyRepo, previous) => 
            previous ?? PharmacyViewModel(pharmacyRepo),
        ),
      ],
      child: MaterialApp(
        title: 'Smart PharmaNet',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: const WelcomeScreen(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Pharma Net',
      theme: ThemeData(
        primaryColor: const Color(0xFF636AE8),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF636AE8)),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(), // or your initial screen
    );
  }
}