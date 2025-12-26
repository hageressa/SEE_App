import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/notification.dart';
import 'package:see_app/services/notification_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              context.read<NotificationService>().markAllAsRead();
            },
            tooltip: 'Mark all as read',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              _showDeleteAllDialog(context);
            },
            tooltip: 'Delete all notifications',
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, service, child) {
          if (service.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: service.notifications.length,
            itemBuilder: (context, index) {
              final notification = service.notifications[index];
              return _NotificationTile(notification: notification);
            },
          );
        },
      ),
    );
  }

  Future<void> _showDeleteAllDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notifications'),
        content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<NotificationService>().deleteAllNotifications();
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({
    Key? key,
    required this.notification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) {
        context.read<NotificationService>().deleteNotification(notification.id);
      },
      child: ListTile(
        leading: _buildNotificationIcon(),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              timeago.format(notification.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        onTap: () {
          if (!notification.read) {
            context.read<NotificationService>().markAsRead(notification.id);
          }
          _handleNotificationTap(context);
        },
      ),
    );
  }

  Widget _buildNotificationIcon() {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.newMessage:
        iconData = Icons.message;
        iconColor = theme_utils.SeeAppTheme.primaryColor;
        break;
      case NotificationType.newPatient:
        iconData = Icons.person_add;
        iconColor = Colors.green;
        break;
      case NotificationType.distressAlert:
        iconData = Icons.warning;
        iconColor = Colors.red;
        break;
      case NotificationType.missionCompleted:
        iconData = Icons.star;
        iconColor = Colors.amber;
        break;
      case NotificationType.emotionUpdate:
        iconData = Icons.mood;
        iconColor = Colors.purple;
        break;
      case NotificationType.connectionRequest:
        iconData = Icons.people;
        iconColor = Colors.blue;
        break;
      case NotificationType.connectionAccepted:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case NotificationType.sessionReminder:
        iconData = Icons.calendar_today;
        iconColor = Colors.orange;
        break;
      case NotificationType.other:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
        break;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(
        iconData,
        color: iconColor,
      ),
    );
  }

  void _handleNotificationTap(BuildContext context) {
    // Handle navigation based on notification type and data
    switch (notification.type) {
      case NotificationType.newMessage:
        if (notification.data?['conversationId'] != null) {
          // Navigate to message screen
          // TODO: Implement navigation
        }
        break;
      case NotificationType.newPatient:
        if (notification.data?['childId'] != null) {
          // Navigate to patient profile
          // TODO: Implement navigation
        }
        break;
      case NotificationType.distressAlert:
        if (notification.data?['alertId'] != null) {
          // Navigate to distress alert details
          // TODO: Implement navigation
        }
        break;
      case NotificationType.missionCompleted:
        if (notification.data?['missionId'] != null) {
          // Navigate to mission details
          // TODO: Implement navigation
        }
        break;
      case NotificationType.emotionUpdate:
        if (notification.data?['childId'] != null) {
          // Navigate to emotion details
          // TODO: Implement navigation
        }
        break;
      case NotificationType.connectionRequest:
        if (notification.data?['requestId'] != null) {
          // Navigate to connection request
          // TODO: Implement navigation
        }
        break;
      case NotificationType.connectionAccepted:
        if (notification.data?['therapistId'] != null) {
          // Navigate to therapist profile
          // TODO: Implement navigation
        }
        break;
      case NotificationType.sessionReminder:
        if (notification.data?['sessionId'] != null) {
          // Navigate to session details
          // TODO: Implement navigation
        }
        break;
      case NotificationType.other:
        // No specific action
        break;
    }
  }
} 