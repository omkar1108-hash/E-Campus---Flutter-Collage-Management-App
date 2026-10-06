import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/session_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

class ECampusApp extends StatelessWidget {
  const ECampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => FirestoreService()),
        ChangeNotifierProvider(
          create: (c) => SessionProvider(c.read<AuthService>(), c.read<FirestoreService>()),
        ),
      ],
      child: MaterialApp(
        title: 'E-Campus',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF1E40AF),
          useMaterial3: true,
        ),
        home: const _Gate(),
      ),
    );
  }
}

/// Chooses the screen from the session state.
class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    switch (session.status) {
      case SessionStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case SessionStatus.signedOut:
        return const AuthScreen();
      case SessionStatus.needsProfile:
        return const ProfileSetupScreen();
      case SessionStatus.ready:
        return const HomeScreen();
      case SessionStatus.error:
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text(session.errorMessage ?? 'Something went wrong.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                      onPressed: session.signOut, child: const Text('Sign out')),
                ],
              ),
            ),
          ),
        );
    }
  }
}
