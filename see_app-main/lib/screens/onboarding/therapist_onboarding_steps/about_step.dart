import 'package:flutter/material.dart';
import 'package:see_app/utils/theme.dart';

class AboutStep extends StatelessWidget {
  const AboutStep({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final InputDecoration inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
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
            const Text('About You', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Tell parents a little about your approach and passion.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            TextField(
              maxLines: 5,
              decoration: inputDecoration.copyWith(
                hintText: 'e.g., "I specialize in creating a fun and supportive environment for children to develop their communication skills..."',
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
} 