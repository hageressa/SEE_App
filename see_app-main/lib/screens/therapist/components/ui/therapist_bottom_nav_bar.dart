import 'package:flutter/material.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

class TherapistBottomNavBar extends StatelessWidget {
  final int currentTabIndex;
  final Function(int) onTabChanged;

  const TherapistBottomNavBar({
    Key? key,
    required this.currentTabIndex,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark 
          ? theme_utils.SeeAppTheme.darkSecondaryBackground
          : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentTabIndex,
        onTap: onTabChanged,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: theme_utils.SeeAppTheme.primaryColor,
        unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'Clients',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Analytics',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Messages',
          ),
        ],
      ),
    );
  }
}
