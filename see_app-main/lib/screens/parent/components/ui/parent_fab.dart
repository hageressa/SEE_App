import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

/// Floating action button component with contextual behavior
class ParentFab extends StatelessWidget {
  final int currentTabIndex;
  final bool isArticleOpen;
  final Function() onSaveArticle;
  final Function() onAddChild;
  final Function() onAddTherapistToFavorites;
  final Function() onCreateNewMessage;

  const ParentFab({
    super.key,
    required this.currentTabIndex,
    this.isArticleOpen = false,
    required this.onSaveArticle,
    required this.onAddChild,
    required this.onAddTherapistToFavorites,
    required this.onCreateNewMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (!_showFab()) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4.0),
      height: 56.0,
      width: 56.0,
      child: FloatingActionButton(
        elevation: 6.0,
        onPressed: () {
          HapticFeedback.mediumImpact();
          _handleFabPress();
        },
        backgroundColor: theme_utils.SeeAppTheme.secondaryColor,
        tooltip: _getFabLabel(),
        child: Icon(_getFabIcon(), color: Colors.white),
      ),
    );
  }
  
  /// Handles FAB press based on current tab
  void _handleFabPress() {
    switch (currentTabIndex) {
      case 0: // Home
        onSaveArticle();
        break;
      case 1: // Dashboard
        onAddChild();
        break;
      case 2: // Therapists
        onAddTherapistToFavorites();
        break;
      case 3: // Messages
        onCreateNewMessage();
        break;
    }
  }
  
  /// Determines whether to show the FAB
  bool _showFab() {
    // Only show FAB when an article is open or on dashboard tab for recording emotions
    if (currentTabIndex == 1) {
      return true; // Always show on Dashboard tab for recording emotions
    } else if (currentTabIndex == 0 && isArticleOpen) {
      return true; // Only show on Home tab when an article is open
    } else if (currentTabIndex == 2 || currentTabIndex == 3) {
      return true; // Show on therapists and messages tabs
    } else {
      return false; // Hide on other tabs
    }
  }
  
  /// Gets the label for the floating action button
  String _getFabLabel() {
    switch (currentTabIndex) {
      case 0: // Home
        return 'Save';
      case 1: // Dashboard
        return 'Add Child';
      case 2: // Therapists
        return 'Add Favorite';
      case 3: // Messages
        return 'New Message';
      default:
        return 'Action';
    }
  }
  
  /// Gets the icon for the floating action button
  IconData _getFabIcon() {
    switch (currentTabIndex) {
      case 0: // Home
        return Icons.bookmark_add_outlined;
      case 1: // Dashboard
        return Icons.add;
      case 2: // Therapists
        return Icons.person_add_outlined;
      case 3: // Messages
        return Icons.edit;
      default:
        return Icons.add;
    }
  }
}