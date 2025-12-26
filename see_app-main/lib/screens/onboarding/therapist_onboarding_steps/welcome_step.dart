import 'package:flutter/material.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to SEE!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Let\'s get your professional profile set up in just a few quick steps.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            const Icon(Icons.rocket_launch_outlined, color: Colors.white, size: 80),
            const SizedBox(height: 48),
            const Text(
              'Use the "Next" button below to begin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white54, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
} 