import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

/// Navigation drawer component for the parent dashboard
class ParentDrawer extends StatelessWidget {
  final Function() onNavigateToHistory;
  final Function() onNavigateToReports;
  final Function() onNavigateToMessages;
  final Function() onNavigateToSettings;
  final Function() onNavigateToHelp;
  final Function() onLogout;
  
  const ParentDrawer({
    super.key,
    required this.onNavigateToHistory,
    required this.onNavigateToReports,
    required this.onNavigateToMessages,
    required this.onNavigateToSettings,
    required this.onNavigateToHelp,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white, // Change to white for better visibility
      width: MediaQuery.of(context).size.width * 0.85, // Explicit width constraint
      elevation: 16.0, // Increased elevation for more pronounced shadow
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(context),
            const Divider(color: Colors.grey),
            _buildDrawerMainItems(context),
            const Divider(color: Colors.grey),
            _buildDrawerSecondaryItems(context),
            const Spacer(),
            const Divider(color: Colors.grey),
            _buildDrawerItem(
              context: context,
              icon: Icons.exit_to_app,
              title: 'Logout',
              onTap: onLogout,
              textColor: Colors.red,
              iconColor: Colors.red,
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
          ],
        ),
      ),
    );
  }
  
  /// Builds the header section for the drawer
  Widget _buildDrawerHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          final currentUser = authService.currentUser;
          String userName = 'Parent';
          String userEmail = 'parent@example.com';
          
          // Get actual user data if available
          if (currentUser != null) {
            userName = currentUser.name;
            userEmail = currentUser.email;
          }
          
          return Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.2),
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: theme_utils.SeeAppTheme.primaryColor,
                  ),
                ),
              ).animate()
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ),
              const SizedBox(width: theme_utils.SeeAppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: theme_utils.SeeAppTheme.spacing4),
                    Text(
                      userEmail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  /// Builds the main menu items for the drawer
  Widget _buildDrawerMainItems(BuildContext context) {
    return Column(
      children: [
        _buildDrawerItem(
          context: context,
          icon: Icons.dashboard_outlined,
          title: 'Dashboard', 
          isSelected: true,
          onTap: () => Navigator.pop(context),
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.history,
          title: 'History',
          onTap: () {
            Navigator.pop(context);
            onNavigateToHistory();
          },
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.format_list_bulleted,
          title: 'Reports',
          onTap: () {
            Navigator.pop(context);
            onNavigateToReports();
          },
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.message_outlined,
          title: 'Messages',
          badgeCount: 2,
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).pushNamed('/messages');
          },
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.calendar_today,
          title: 'Appointments',
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).pushNamed('/appointments');
          },
        ),
      ],
    );
  }
  
  /// Builds the secondary menu items for the drawer
  Widget _buildDrawerSecondaryItems(BuildContext context) {
    return Column(
      children: [
        _buildDrawerItem(
          context: context,
          icon: Icons.settings_outlined,
          title: 'Settings',
          onTap: () {
            Navigator.pop(context);
            onNavigateToSettings();
          },
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () {
            Navigator.pop(context);
            onNavigateToHelp();
          },
        ),
      ],
    );
  }
  
  /// Builds a drawer menu item
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    bool isSelected = false,
    int badgeCount = 0,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Stack(
        children: [
          Icon(
            icon,
            color: iconColor ?? (isSelected ? theme_utils.SeeAppTheme.primaryColor : Colors.black54),
          ),
          if (badgeCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme_utils.SeeAppTheme.alertHigh,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? (isSelected ? theme_utils.SeeAppTheme.primaryColor : Colors.black87),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: isSelected ? theme_utils.SeeAppTheme.primaryColor.withOpacity(0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
      ),
      onTap: onTap,
    );
  }
}