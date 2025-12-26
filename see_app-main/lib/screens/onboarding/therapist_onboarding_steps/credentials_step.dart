import 'package:flutter/material.dart';
import 'package:see_app/utils/theme.dart';

class CredentialsStep extends StatelessWidget {
  const CredentialsStep({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final InputDecoration inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      labelStyle: const TextStyle(color: Colors.white),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
        borderSide: const BorderSide(color: Colors.white, width: 2.0),
      ),
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Credentials', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('This information is optional but recommended.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            TextField(
              decoration: inputDecoration.copyWith(
                labelText: 'Highest Degree (e.g., M.S. in Speech Pathology)',
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: inputDecoration.copyWith(
                labelText: 'License Number (Optional)',
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
} 