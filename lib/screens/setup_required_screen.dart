import 'package:flutter/material.dart';

/// Shown when `flutterfire configure` has not been run yet.
class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.settings_suggest, size: 64),
              SizedBox(height: 16),
              Text('Firebase setup required',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text(
                'Connect this app to your Firebase project:\n\n'
                '1. dart pub global activate flutterfire_cli\n'
                '2. flutterfire configure\n'
                '3. Re-run the app\n\n'
                'See the README for the full setup guide.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
