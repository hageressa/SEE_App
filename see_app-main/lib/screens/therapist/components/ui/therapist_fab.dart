import 'package:flutter/material.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

class TherapistFab extends StatelessWidget {
  final int currentTabIndex;
  final VoidCallback onAddClient;
  final VoidCallback onCreateRecommendation;
  final VoidCallback onCreateMission;
  final VoidCallback onSendMessage;

  const TherapistFab({
    Key? key,
    required this.currentTabIndex,
    required this.onAddClient,
    required this.onCreateRecommendation,
    required this.onCreateMission,
    required this.onSendMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Don't show FAB if it's not relevant for the current tab
    if (currentTabIndex < 0 || currentTabIndex > 3) {
      return const SizedBox.shrink();
    }

    // Return the appropriate FAB based on the current tab
    return FloatingActionButton(
      onPressed: _getAction(),
      backgroundColor: theme_utils.SeeAppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      tooltip: _getTooltip(),
      child: Icon(_getIcon()),
    );
  }

  // Get the appropriate icon for the current tab
  IconData _getIcon() {
    switch (currentTabIndex) {
      case 0: // Overview tab
        return Icons.add_task; // Create recommendation
      case 1: // Clients tab
        return Icons.person_add; // Add client
      case 2: // Analytics tab
        return Icons.assignment_add; // Create mission
      case 3: // Messages tab
        return Icons.message; // Send message
      default:
        return Icons.add;
    }
  }

  // Get the appropriate tooltip for the current tab
  String _getTooltip() {
    switch (currentTabIndex) {
      case 0: // Overview tab
        return 'Create Recommendation';
      case 1: // Clients tab
        return 'Add Client';
      case 2: // Analytics tab
        return 'Create Mission';
      case 3: // Messages tab
        return 'Send Message';
      default:
        return 'Add';
    }
  }

  // Get the appropriate action for the current tab
  VoidCallback _getAction() {
    switch (currentTabIndex) {
      case 0: // Overview tab
        return onCreateRecommendation;
      case 1: // Clients tab
        return onAddClient;
      case 2: // Analytics tab
        return onCreateMission;
      case 3: // Messages tab
        return onSendMessage;
      default:
        return () {};
    }
  }
}
