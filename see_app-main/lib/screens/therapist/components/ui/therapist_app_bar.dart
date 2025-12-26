import 'package:flutter/material.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:see_app/models/user.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/connection_request.dart';
import 'package:see_app/services/connection_service.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/screens/therapist/connection_requests_screen.dart';
import 'package:see_app/widgets/notification_badge.dart';

class TherapistAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final AppUser? currentUser;
  final VoidCallback onRefresh;
  final VoidCallback onOpenSettings;
  final VoidCallback? onSearch;
  final bool showSearchAction;

  const TherapistAppBar({
    Key? key,
    required this.title,
    this.currentUser,
    required this.onRefresh,
    required this.onOpenSettings,
    this.onSearch,
    this.showSearchAction = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    final therapistId = Provider.of<AuthService>(context, listen: false).currentUser?.id;

    return AppBar(
      elevation: 0,
      backgroundColor: isDark 
          ? theme_utils.SeeAppTheme.darkSecondaryBackground
          : theme_utils.SeeAppTheme.primaryColor,
      foregroundColor: Colors.white,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (showSearchAction && onSearch != null)
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: onSearch,
            tooltip: 'Search',
          ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: onRefresh,
          tooltip: 'Refresh',
        ),
        if (therapistId != null)
          NotificationBadge(
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ConnectionRequestsScreen()),
                );
              },
              tooltip: 'Notifications',
            ),
            badgeColor: theme_utils.SeeAppTheme.alertHigh,
            textColor: Colors.white,
          ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: onOpenSettings,
          tooltip: 'Settings',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildAvatar(),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    String? photoUrl = currentUser?.photoUrl;
    String initials = '';
    
    if (currentUser != null) {
      final nameParts = currentUser!.displayName.split(' ');
      if (nameParts.isNotEmpty) {
        initials = nameParts[0][0];
        if (nameParts.length > 1) {
          initials += nameParts[nameParts.length - 1][0];
        }
      }
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: theme_utils.SeeAppTheme.accentColor,
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
      child: photoUrl == null
          ? Text(
              initials.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
