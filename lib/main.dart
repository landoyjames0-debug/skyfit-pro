import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/user_viewmodel.dart';
import 'viewmodels/weather_viewmodel.dart';
import 'views/auth/login_view.dart';
import 'views/auth/register_view.dart';
import 'views/home_view.dart';
import 'views/profile_view.dart';
import 'views/widgets/skyfit_splash_screen.dart';
import 'views/widgets/skyfit_transitions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SkyFitRouteFactory.register(
    '/splash',
    (_) => const SkyFitSplashScreen(nextRoute: '/login'),
    style: SkyFitTransitionStyle.fadeScale,
  );
  SkyFitRouteFactory.register(
    '/login',
    (_) => const LoginView(),
    style: SkyFitTransitionStyle.fadeScale,
  );
  SkyFitRouteFactory.register(
    '/register',
    (_) => const RegisterView(),
    style: SkyFitTransitionStyle.shimmerSlideRight,
  );
  SkyFitRouteFactory.register(
    '/home',
    (_) => const HomeView(),
    style: SkyFitTransitionStyle.circularReveal,
  );
  SkyFitRouteFactory.register(
    '/profile',
    (_) => const ProfileView(),
    style: SkyFitTransitionStyle.shimmerSlideRight,
  );

  runApp(const SkyFitProApp());
}

class SkyFitProApp extends StatelessWidget {
  const SkyFitProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => WeatherViewModel()),
      ],
      child: Consumer<AuthViewModel>(
        builder: (context, authVM, child) => MaterialApp(
          title: 'SkyFit Pro',
          debugShowCheckedModeBanner: false,
          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: authVM.themeMode,
          initialRoute: '/splash',
          onGenerateRoute: SkyFitRouteFactory.generate,
          onUnknownRoute: (settings) => MaterialPageRoute(
            builder: (_) => const Scaffold(
              backgroundColor: Color(0xFF050810),
              body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00D4FF))),
            ),
          ),
        ),
      ),
    );
  }

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF0F4FF),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00D4FF),
      brightness: Brightness.light,
      surface: Colors.white,
      primary: const Color(0xFF0099CC),
      secondary: const Color(0xFF5B41CC),
    ),
    cardColor: Colors.white,
    dividerColor: Colors.black.withValues(alpha: 0.08),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF0D1117)),
      bodyMedium: TextStyle(color: Color(0xFF374151)),
      titleLarge:
          TextStyle(color: Color(0xFF0D1117), fontWeight: FontWeight.bold),
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF050810),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00D4FF),
      brightness: Brightness.dark,
      surface: const Color(0xFF0D1117),
      primary: const Color(0xFF00D4FF),
      secondary: const Color(0xFF7B61FF),
    ),
    cardColor: const Color(0xFF0D1117),
    dividerColor: Colors.white.withValues(alpha: 0.08),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}

class SkyFitUnknownRoute extends Route<dynamic> {
  @override
  Widget buildPageWithStateInfo(
    BuildContext context,
    RouteSettings settings,
    RouteInformation? stateInfo,
  ) {
    return const Scaffold(
      backgroundColor: Color(0xFF050810),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
      ),
    );
  }
}
