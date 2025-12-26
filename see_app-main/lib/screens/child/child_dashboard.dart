import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_firestore/firebase_firestore.dart';
import 'package:your_app/services/auth_service.dart';
import 'package:your_app/screens/login_screen.dart';

class ChildDashboard extends StatefulWidget {
  // ... (existing code)
  @override
  _ChildDashboardState createState() => _ChildDashboardState();
}

class _ChildDashboardState extends State<ChildDashboard> {
  // ... (existing code)

  Future<void> _handleLogout() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
      
      // Cancel any active subscriptions
      _missionsSubscription?.cancel();
      _emotionsSubscription?.cancel();
      
      // Terminate Firebase connections
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.terminate();
      } catch (e) {
        debugPrint('Error terminating Firestore: $e');
        // Continue with logout even if there's an error
      }
      
      // Get auth service
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      
      // Add a small delay to let Firebase connections close
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (!context.mounted) return;
      
      // Navigate to login screen and clear stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error during logout: $e');
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (!context.mounted) return;
      
      // Show error but still try to navigate to login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
      
      // Force navigation to login screen even if there was an error
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (existing code)
  }
} 