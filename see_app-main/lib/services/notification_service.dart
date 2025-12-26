import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:see_app/models/notification.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection references
  CollectionReference get _notificationsCollection => _firestore.collection('notifications');
  
  // Stream controller for real-time notifications
  final StreamController<List<AppNotification>> _notificationsController = 
    StreamController<List<AppNotification>>.broadcast();
  
  Stream<List<AppNotification>> get notificationsStream => _notificationsController.stream;
  
  // Cache of notifications
  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;
  
  // Unread count
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;
  
  // Subscription for cleanup
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;
  
  NotificationService() {
    _initNotificationsListener();
  }
  
  void _initNotificationsListener() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    _notificationsSubscription = _notificationsCollection
      .where('userId', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .listen(
        (snapshot) {
          _notifications = snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList();
          
          _unreadCount = _notifications.where((n) => !n.read).length;
          
          _notificationsController.add(_notifications);
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error in notifications subscription: $error');
        },
      );
  }
  
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = AppNotification(
        id: '', // Will be set by Firestore
        userId: userId,
        type: type,
        title: title,
        message: message,
        timestamp: DateTime.now(),
        read: false,
        data: data,
      );
      
      await _notificationsCollection.add(notification.toFirestore());
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    }
  }
  
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }
  
  Future<void> markAllAsRead() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      final batch = _firestore.batch();
      final unreadNotifications = await _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
      
      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }
  
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }
  
  Future<void> deleteAllNotifications() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      final batch = _firestore.batch();
      final notifications = await _notificationsCollection
        .where('userId', isEqualTo: userId)
        .get();
      
      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      rethrow;
    }
  }
  
  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    _notificationsController.close();
    super.dispose();
  }
} 