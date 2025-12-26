import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newMessage,
  newPatient,
  distressAlert,
  missionCompleted,
  emotionUpdate,
  connectionRequest,
  connectionAccepted,
  sessionReminder,
  other
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool read;
  final DateTime? readAt;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.read,
    this.readAt,
    this.data,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] as String,
      type: _stringToNotificationType(data['type'] as String),
      title: data['title'] as String,
      message: data['message'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      read: data['read'] as bool? ?? false,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      data: data['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'read': read,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'data': data,
    };
  }

  static NotificationType _stringToNotificationType(String type) {
    return NotificationType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => NotificationType.other,
    );
  }
} 