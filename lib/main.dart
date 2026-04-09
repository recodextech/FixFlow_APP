import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'providers/worker_provider.dart';
import 'providers/contractor_provider.dart';
import 'services/preferences_service.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';

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
        ChangeNotifierProvider(create: (_) => WorkerProvider()),
        ChangeNotifierProvider(create: (_) => ContractorProvider()),
      ],
      child: MaterialApp(
        title: 'FixFlow',
        theme: buildAppTheme(),
        home: const _AuthGate(),
        routes: {
          '/home': (_) => const HomeScreen(),
          '/login': (_) => const LoginScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Checks auth state, fetches user accounts, and routes accordingly.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  Future<bool> _initSession() async {
    final isAuth = await AuthService().isAuthenticated();
    if (!isAuth) return false;

    try {
      final accounts = await ApiService().getUserAccounts();
      PreferencesService().loadUserAccounts(
        userId: accounts.userId,
        worker: accounts.worker,
        contractor: accounts.contractor,
      );
    } catch (_) {
      // If accounts fetch fails, logout and return to login
      await AuthService().logout();
      await PreferencesService().clearAll();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
