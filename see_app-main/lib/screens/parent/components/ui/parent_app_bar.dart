import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:see_app/widgets/sync_status_indicator.dart';
import 'package:see_app/widgets/notification_badge.dart';

/// Custom app bar component for the parent dashboard
class ParentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool innerBoxIsScrolled;
  final Function() onShowNotifications;
  final Function() onShowSettings;
  final DatabaseService? databaseService;
  final String? userId;

  const ParentAppBar({
    super.key,
    required this.title,
    this.innerBoxIsScrolled = false,
    required this.onShowNotifications,
    required this.onShowSettings,
    this.databaseService,
    this.userId,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      forceElevated: innerBoxIsScrolled,
      backgroundColor: Colors.white,
      elevation: innerBoxIsScrolled ? 4 : 0,
      flexibleSpace: _buildAppBarBackground(),
      title: _buildAppBarTitle(context),
      actions: _buildAppBarActions(context),
      // Add drawer hamburger icon to access the sidebar drawer
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer();
            HapticFeedback.mediumImpact();
          },
          tooltip: 'Menu',
        ),
      ),
    );
  }

  /// Builds the background for the app bar with gradient and decorative elements
  Widget _buildAppBarBackground() {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme_utils.SeeAppTheme.primaryColor,
                theme_utils.SeeAppTheme.primaryColor.withOpacity(0.85),
              ],
            ),
          ),
        ),
        // Decorative shapes for visual interest
        Positioned(
          top: -15,
          right: -15,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -20,
          left: 30,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Builds the title row for the app bar with logo and text
  Widget _buildAppBarTitle(BuildContext context) {
    return Row(
      children: [
        // Logo element
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: theme_utils.SeeAppTheme.spacing8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.visibility,
              color: theme_utils.SeeAppTheme.primaryColor,
              size: 18,
            ),
          ),
        ),
        // Title with gradient text effect
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.white, Colors.white.withOpacity(0.9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        // Add sync status indicator if database service and user ID are available
        if (databaseService != null && userId != null) ...[
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Theme(
              data: Theme.of(context).copyWith(
                iconTheme: const IconThemeData(color: Colors.white), 
                textTheme: Theme.of(context).textTheme.apply(bodyColor: Colors.white),
              ),
              child: SyncStatusIndicator(
                databaseService: databaseService!,
                userId: userId!,
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  /// Builds action buttons for the app bar
  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      NotificationBadge(
        child: IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            onShowNotifications();
          },
          tooltip: 'Notifications',
        ),
        badgeColor: theme_utils.SeeAppTheme.alertHigh,
        textColor: Colors.white,
      ),
      IconButton(
        icon: const Icon(Icons.settings_outlined, color: Colors.white),
        onPressed: () {
          HapticFeedback.lightImpact();
          onShowSettings();
        },
        tooltip: 'Settings',
      ),
    ];
  }
}