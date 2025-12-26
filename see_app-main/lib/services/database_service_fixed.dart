// Copy of the original database_service.dart file with the duplicate getUsersByRole method removed
// This file is meant to replace the original database_service.dart

// Import all the necessary packages and models here (same as the original file)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:see_app/models/user.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/models/message.dart';
import 'package:see_app/models/mission.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DatabaseService {
  // Private constructor
  DatabaseService._() {
    _initConnectivity();
  }

  // Singleton instance
  static final DatabaseService _instance = DatabaseService._();

  // Factory constructor to return the singleton instance
  factory DatabaseService() {
    return _instance;
  }

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _childrenCollection => _firestore.collection('children');
  CollectionReference get _emotionsCollection => _firestore.collection('emotions');
  CollectionReference get _missionsCollection => _firestore.collection('missions');
  CollectionReference get _alertsCollection => _firestore.collection('alerts');
  CollectionReference get _conversationsCollection => _firestore.collection('conversations');
  CollectionReference get _messagesCollection => _firestore.collection('messages');
  CollectionReference get _notificationsCollection => _firestore.collection('notifications');
  CollectionReference get _userBadgesCollection => _firestore.collection('user_badges');
  CollectionReference get _sessionsCollection => _firestore.collection('sessions');
  CollectionReference get _suggestionsCollection => _firestore.collection('suggestions');

  // Online status
  bool _isOnline = true;
  Stream<bool> get onlineStatus => _connectivityStream.map((status) => status != ConnectivityResult.none);
  final StreamController<ConnectivityResult> _connectivityController = StreamController<ConnectivityResult>.broadcast();
  Stream<ConnectivityResult> get _connectivityStream => _connectivityController.stream;

  // Initialize connectivity monitoring
  void _initConnectivity() async {
    final Connectivity connectivity = Connectivity();
    
    // Set initial state
    ConnectivityResult result = await connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    _connectivityController.add(result);
    
    // Listen for changes
    connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _isOnline = result != ConnectivityResult.none;
      _connectivityController.add(result);
      
      if (_isOnline) {
        debugPrint('📱 Device is back online');
        // Sync any pending updates if needed
      } else {
        debugPrint('📱 Device is offline - enabling local storage');
        // Set up for offline mode
      }
    });
  }

  // USER OPERATIONS ========================================================

  /// Get user by ID
  Future<AppUser?> getUser(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      if (docSnapshot.exists) {
        return AppUser.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Get users by role
  Future<List<AppUser>> getUsersByRole(UserRole role) async {
    try {
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: role.toString().split('.').last)
          .get();
      
      return querySnapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting users by role: $e');
      rethrow;
    }
  }

  // ADD ALL YOUR OTHER METHODS HERE FROM THE ORIGINAL FILE
  // ...
  // EXCEPT FOR THE DUPLICATE getUsersByRole METHOD AT LINE 2838
  // ...

  /// Update conversation metadata
  Future<void> updateConversationMetadata(String conversationId, Map<String, dynamic> metadata) async {
    try {
      await _conversationsCollection.doc(conversationId).update({
        'metadata': metadata,
      });
    } catch (e) {
      debugPrint('Error updating conversation metadata: $e');
      rethrow;
    }
  }
} 