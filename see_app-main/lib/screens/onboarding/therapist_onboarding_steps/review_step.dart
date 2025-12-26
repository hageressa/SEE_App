import 'package:flutter/material.dart';

class ReviewStep extends StatelessWidget {
  const ReviewStep({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // In a real app, pull summary data from state
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('All Set!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 80),
          const SizedBox(height: 24),
          const Text('You\'ve completed the basic setup. You can edit your profile at any time from your dashboard.', 
            style: TextStyle(color: Colors.white70, fontSize: 16), 
            textAlign: TextAlign.center
          ),
          const SizedBox(height: 48),
          const Text('Click "Finish" below to go to your dashboard.', 
            style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic), 
            textAlign: TextAlign.center
          ),
        ],
      ),
    );
  }
} 