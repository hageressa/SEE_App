import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

/// Bottom navigation bar component for the parent dashboard
class ParentBottomNavBar extends StatelessWidget {
  final int currentTabIndex;
  final Function(int) onTabChanged;

  const ParentBottomNavBar({
    super.key,
    required this.currentTabIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomAppBar(
        elevation: 8,
        height: 60,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 'Home', 0),
              _buildNavItem(Icons.dashboard_outlined, 'Dashboard', 1),
              const SizedBox(width: 40), // Space for FAB
              _buildNavItem(Icons.medical_services_outlined, 'Therapists', 2),
              _buildNavItem(Icons.chat_bubble_outline, 'Messages', 3),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a navigation item for the bottom nav bar
  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = index == currentTabIndex;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          onTabChanged(index);
          HapticFeedback.selectionClick();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? theme_utils.SeeAppTheme.primaryColor : Colors.grey,
                  size: 20,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? theme_utils.SeeAppTheme.primaryColor : Colors.grey,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}