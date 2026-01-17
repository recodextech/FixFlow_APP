import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/selection_screen.dart';
import 'screens/worker_profile_screen.dart';
import 'screens/contractor_profile_screen.dart';
import 'screens/home_screen.dart';
import 'providers/worker_provider.dart';
import 'providers/contractor_provider.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferencesService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WorkerProvider()),
        ChangeNotifierProvider(create: (context) => ContractorProvider()),
      ],
      child: MaterialApp(
        title: 'FixFlow - Worker & Contractor Manager',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const _HomeRoute(),
        onGenerateRoute: (settings) {
          if (settings.name == '/') {
            return MaterialPageRoute(builder: (_) => const _HomeRoute());
          }
          return null;
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class _HomeRoute extends StatelessWidget {
  const _HomeRoute();

  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesService();

    // Check if user has an existing profile
    bool hasWorkerProfile = prefs.hasWorkerProfile();
    bool hasContractorProfile = prefs.hasContractorProfile();

    // If both profiles exist, show home screen to choose
    if (hasWorkerProfile && hasContractorProfile) {
      return const HomeScreen();
    }

    // If only worker profile exists, show worker profile
    if (hasWorkerProfile) {
      final workerId = prefs.getWorkerId();
      return WorkerProfileScreen(workerId: workerId!);
    }

    // If only contractor profile exists, show contractor profile
    if (hasContractorProfile) {
      final contractorId = prefs.getContractorId();
      return ContractorProfileScreen(contractorId: contractorId!);
    }

    // If no profile exists, show selection screen
    return const SelectionScreen();
  }
}
