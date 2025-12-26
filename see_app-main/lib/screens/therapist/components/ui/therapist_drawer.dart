import 'package:flutter/material.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

class TherapistDrawer extends StatelessWidget {
  final AppUser? currentUser;
  final VoidCallback onLogout;
  final VoidCallback onNavigateToClients;
  final VoidCallback onNavigateToAnalytics;
  final VoidCallback onNavigateToResources;
  final VoidCallback onNavigateToReports;
  final VoidCallback onNavigateToSchedule;
  final VoidCallback onNavigateToSettings;

  const TherapistDrawer({
    Key? key,
    this.currentUser,
    required this.onLogout,
    required this.onNavigateToClients,
    required this.onNavigateToAnalytics,
    required this.onNavigateToResources,
    required this.onNavigateToReports,
    required this.onNavigateToSchedule,
    required this.onNavigateToSettings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    
    return Drawer(
      child: Container(
        color: isDark ? theme_utils.SeeAppTheme.darkSecondaryBackground : Colors.white,
        child: Column(
          children: [
            _buildDrawerHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.dashboard_customize,
                    title: 'Client Dashboard',
                    onTap: onNavigateToClients,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.insights,
                    title: 'Analytics & Insights',
                    onTap: onNavigateToAnalytics,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.inventory_2,
                    title: 'Therapeutic Resources',
                    onTap: onNavigateToResources,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.assessment,
                    title: 'Progress Reports',
                    onTap: onNavigateToReports,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.calendar_month,
                    title: 'Schedule & Appointments',
                    onTap: onNavigateToSchedule,
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: onNavigateToSettings,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.exit_to_app,
                    title: 'Logout',
                    onTap: onLogout,
                  ),
                ],
              ),
            ),
            _buildDrawerFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme_utils.SeeAppTheme.primaryColor,
            theme_utils.SeeAppTheme.secondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.9),
                backgroundImage: currentUser?.photoUrl != null
                    ? NetworkImage(currentUser!.photoUrl!)
                    : null,
                child: currentUser?.photoUrl == null
                    ? Text(
                        _getInitials(currentUser?.displayName ?? 'T'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme_utils.SeeAppTheme.primaryColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentUser?.displayName ?? 'Therapist',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentUser?.email ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Licensed Professional',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ListTile(
      leading: Icon(
        icon,
        color: theme_utils.SeeAppTheme.primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        onTap();
      },
    );
  }

  Widget _buildDrawerFooter(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.health_and_safety,
            size: 16,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            'SEE App for Professionals',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final nameParts = name.split(' ');
    if (nameParts.isEmpty) return '';
    
    String initials = nameParts[0][0];
    if (nameParts.length > 1) {
      initials += nameParts[nameParts.length - 1][0];
    }
    
    return initials.toUpperCase();
  }
}
