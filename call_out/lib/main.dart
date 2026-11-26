import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'state/auth_state.dart';
import 'utils/theme.dart';
import 'screens/root_scaffold.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';

void main() {
  runApp(const CalloutApp());
}

class CalloutApp extends StatelessWidget {
  const CalloutApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppTheme.brandPurple);

    // AuthState is provided above MaterialApp so LoginScreen and
    // RegisterScreen can call context.read<AuthState>().
    return ChangeNotifierProvider<AuthState>(
      create: (_) => AuthState(InMemoryAuthService()),
      child: MaterialApp(
        title: 'Callout',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            backgroundColor: Color.fromARGB(255, 152, 115, 238),
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),

        // 👇 set up your routes here
        initialRoute: '/home',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const RootScaffold(),
        },
      ),
    );
  }
}
