import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class ErrorState extends StatelessWidget {
  const ErrorState(this.error, {super.key});
  final Object? error;

  @override
  Widget build(BuildContext context) =>
      EmptyState(icon: Icons.error_outline, message: 'Something went wrong.\n$error');
}

void showSnack(BuildContext context, String message) =>
    showSnackOn(ScaffoldMessenger.of(context), message);

/// Use this variant after an `await`, with a messenger captured beforehand.
void showSnackOn(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
