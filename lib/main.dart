import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_user_screen.dart';
import 'providers/worker_provider.dart';
import 'providers/contractor_provider.dart';
import 'providers/language_provider.dart';
import 'services/preferences_service.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'widgets/app_toast.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Only what the first frame needs blocks startup. Messaging setup waits on
  // a permission prompt and a token request, so it runs after the app shows.
  await Future.wait([Firebase.initializeApp(), PreferencesService().init()]);
  runApp(const MyApp());
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await NotificationService.initialize();
    NotificationService.showPendingMessage();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkerProvider()),
        ChangeNotifierProvider(create: (_) => ContractorProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return MaterialApp(
            title: 'FixFlow',
            navigatorKey: AppToast.navigatorKey,
            theme: buildAppTheme(languageProvider.locale),
            locale: languageProvider.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizationsDelegate.supportedLocales,
            localeResolutionCallback:
                AppLocalizationsDelegate.localeResolutionCallback,
            home: const _AuthGate(),
            routes: {
              '/home': (_) => const HomeScreen(),
              '/login': (_) => const LoginScreen(),
            },
            debugShowCheckedModeBanner: false,
            // Dismiss the keyboard when tapping outside a text field. Mobile
            // platforms don't unfocus on outside taps by default. Taps on
            // buttons or other fields still win the gesture arena.
            builder: (context, child) => GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// Checks auth state, fetches user accounts, and routes accordingly.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  // Created once: building the future in build() re-ran the whole session
  // check (token refresh + accounts request) on every rebuild.
  late final Future<_StartupDestination> _destination = _initSession();

  Future<_StartupDestination> _initSession() async {
    final isAuth = await AuthService().validateSessionOnStartup();
    if (!isAuth) return _StartupDestination.login;

    try {
      final accounts = await ApiService().getUserAccounts();
      PreferencesService().loadUserAccounts(
        userId: accounts.userId,
        worker: accounts.worker,
        contractor: accounts.contractor,
      );

      if (accounts.hasAnyProfile) {
        // Push registration doesn't affect routing, so don't wait for it.
        NotificationService.registerDeviceForActiveAccount();
        return _StartupDestination.home;
      }
      return _StartupDestination.createUser;
    } catch (_) {
      // If accounts fetch fails, logout and return to login
      await AuthService().logout();
      await PreferencesService().clearAll();
      return _StartupDestination.login;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StartupDestination>(
      future: _destination,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == _StartupDestination.home) {
          return const HomeScreen();
        }
        if (snapshot.data == _StartupDestination.createUser) {
          return const CreateUserScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

enum _StartupDestination { login, createUser, home }
