import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_app/services/notification_service.dart';
import 'package:see_app/screens/notifications/notifications_screen.dart';

class NotificationBadge extends StatelessWidget {
  final Widget? child;
  final bool showZero;
  final double? badgeSize;
  final double? fontSize;
  final Color? badgeColor;
  final Color? textColor;

  const NotificationBadge({
    Key? key,
    this.child,
    this.showZero = false,
    this.badgeSize,
    this.fontSize,
    this.badgeColor,
    this.textColor,
    }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, service, _) {
        final count = service.unreadCount;
        final showBadge = showZero || count > 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child ?? IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            if (showBadge)
              Positioned(
                right: -8,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: badgeColor ?? Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: badgeSize ?? 16,
                    minHeight: badgeSize ?? 16,
                  ),
                  child: Center(
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: textColor ?? Colors.white,
                        fontSize: fontSize ?? 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
} 