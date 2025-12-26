import 'package:flutter/material.dart';
import 'package:see_app/utils/theme.dart';

class ProfessionalInfoStep extends StatelessWidget {
  const ProfessionalInfoStep({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // A more readable and robust input decoration for dark backgrounds
    final InputDecoration inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
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
            const Text('Professional Info', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('This helps parents understand your background.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            TextField(
              decoration: inputDecoration.copyWith(
                labelText: 'Professional Title',
                hintText: 'e.g., Speech Therapist',
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: inputDecoration.copyWith(
                labelText: 'Years of Experience',
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
} 