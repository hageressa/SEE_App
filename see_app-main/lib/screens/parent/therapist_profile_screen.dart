import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'dart:math' as math;
import 'package:see_app/services/connection_service.dart';
import 'package:see_app/screens/messaging/message_screen.dart';

class TherapistProfileScreen extends StatelessWidget {
  final AppUser therapist;

  const TherapistProfileScreen({Key? key, required this.therapist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(therapist.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specialty: ${therapist.additionalInfo?['specialty'] ?? 'Not specified'}'),
            const SizedBox(height: 16),
            Text('About: ${therapist.additionalInfo?['about'] ?? 'No bio available.'}'),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () => _openChat(context, therapist),
                child: const Text('Open Chat'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(BuildContext context, AppUser therapist) async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final parentId = auth.currentUser!.id;

    try {
      final conversation = await db.getOrCreateConversation(parentId, therapist.id);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MessageScreen(
            conversationId: conversation.id,
            otherUserId: therapist.id,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening chat: $e')),
      );
    }
  }

  void _createConnectionRequest(BuildContext context, Child child, AppUser therapist) async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final parentId = Provider.of<AuthService>(context, listen: false).currentUser!.id;

    try {
      // Directly create or get conversation instead of sending a request
      final conversation = await databaseService.getOrCreateConversation(parentId, therapist.id);
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MessageScreen(
            conversationId: conversation.id,
            otherUserId: therapist.id,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating conversation: $e')),
      );
    }
  }
} 