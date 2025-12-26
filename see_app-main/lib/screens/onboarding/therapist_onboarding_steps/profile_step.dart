import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_app/services/auth_service.dart';

class ProfileStep extends StatelessWidget {
  const ProfileStep({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Your Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              // TODO: Implement image picker logic
            },
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white24,
              child: Icon(Icons.camera_alt, size: 48, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Tap to add a photo', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 40),

          // Display user info in a more structured way
          Card(
            color: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.person, color: Colors.white70),
                    title: Text('Full Name', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    subtitle: Text(user?.displayName ?? 'N/A', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  Divider(color: Colors.white24, height: 1),
                  ListTile(
                    leading: Icon(Icons.email, color: Colors.white70),
                    title: Text('Email', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    subtitle: Text(user?.email ?? 'N/A', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 