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
import 'package:see_app/models/emotion_data.dart';
import 'package:see_app/models/suggestion_feedback.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:see_app/models/connection_request.dart';

class DatabaseService extends ChangeNotifier {
  // Private constructor
  DatabaseService._() {
    _initConnectivity();
    
    // Initialize collections
    _usersCollection = _firestore.collection(_kUsersCollection);
    _childrenCollection = _firestore.collection(_kChildrenCollection);
    _articlesCollection = _firestore.collection(_kArticlesCollection);
    _therapistsCollection = _firestore.collection(_kTherapistsCollection);
    _conversationsCollection = _firestore.collection('conversations');
    _messagesCollection = _firestore.collection('messages');
    _missionsCollection = _firestore.collection('missions');
    _emotionsCollection = _firestore.collection('emotions');
    _alertsCollection = _firestore.collection('alerts');
    _notificationsCollection = _firestore.collection('notifications');
    _sessionsCollection = _firestore.collection('sessions');
    _suggestionsCollection = _firestore.collection('suggestions');
  }

  // Singleton instance
  static final DatabaseService _instance = DatabaseService._();

  // Factory constructor to return the singleton instance
  factory DatabaseService() {
    return _instance;
  }

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Auth reference
  AuthService? _auth;
  AuthService get auth {
    if (_auth == null) {
      _auth = AuthService();
    }
    return _auth!;
  }

  // Collection references
  static const String _kUsersCollection = 'users';
  static const String _kChildrenCollection = 'children';
  static const String _kArticlesCollection = 'articles';
  static const String _kTherapistsCollection = 'therapists';

  late final CollectionReference _usersCollection;
  late final CollectionReference _childrenCollection;
  late final CollectionReference _articlesCollection;
  late final CollectionReference _therapistsCollection;
  late final CollectionReference _conversationsCollection;
  late final CollectionReference _messagesCollection;
  late final CollectionReference _missionsCollection;
  late final CollectionReference _emotionsCollection;
  late final CollectionReference _alertsCollection;
  late final CollectionReference _notificationsCollection;
  late final CollectionReference _sessionsCollection;
  late final CollectionReference _suggestionsCollection;

  // Add getters for collections to allow access from other classes
  CollectionReference get usersCollection => _usersCollection;
  CollectionReference get childrenCollection => _childrenCollection;
  CollectionReference get articlesCollection => _articlesCollection;
  CollectionReference get therapistsCollection => _therapistsCollection;

  // Online status
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  Stream<bool> get onlineStatus => _connectivityStream.map((results) => !results.contains(ConnectivityResult.none));
  Stream<bool> get onlineStatusStream => _connectivityStream.map((results) => !results.contains(ConnectivityResult.none));
  final StreamController<List<ConnectivityResult>> _connectivityController = StreamController<List<ConnectivityResult>>.broadcast();
  Stream<List<ConnectivityResult>> get _connectivityStream => _connectivityController.stream;

  // Initialize connectivity monitoring
  void _initConnectivity() async {
    final Connectivity connectivity = Connectivity();
    
    // Set initial state
    List<ConnectivityResult> result = await connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);
    _connectivityController.add(result);
    
    // Listen for changes
    connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      _isOnline = !result.contains(ConnectivityResult.none);
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

  /// Update user
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(userId).update(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  /// Update conversation metadata
  Future<void> updateConversationMetadata(String conversationId, Map<String, dynamic> metadata) async {
    try {
      await _conversationsCollection.doc(conversationId).update({
        'metadata': metadata,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating conversation metadata: $e');
      rethrow;
    }
  }

  /// Get patients by therapist ID
  Future<List<Child>> getPatientsByTherapistId(String therapistId) async {
    try {
      final querySnapshot = await _childrenCollection
          .where('therapistId', isEqualTo: therapistId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Child.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting patients by therapist ID: $e');
      return [];
    }
  }

  /// Alias for getPatientsByTherapistId
  Future<List<Child>> getChildrenByTherapistId(String therapistId) async {
    return getPatientsByTherapistId(therapistId);
  }

  /// Get children for a user (parent)
  Future<List<Child>> getChildrenForUser(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) return [];
      final userData = userDoc.data() as Map<String, dynamic>;
      final childrenIds = List<String>.from(userData['childrenIds'] ?? []);
      if (childrenIds.isEmpty) return [];
      final childrenDocs = await _childrenCollection.where(FieldPath.documentId, whereIn: childrenIds).get();
      return childrenDocs.docs.map((doc) => Child.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting children for user: $e');
      return [];
    }
  }

  /// Get children by parent ID
  Future<List<Child>> getChildrenByParentId(String parentId) async {
    try {
      // Query for children with parentId field
      final querySnapshot1 = await _childrenCollection
          .where('parentId', isEqualTo: parentId)
          .get();
      
      // Query for children with parent field (for backward compatibility)
      final querySnapshot2 = await _childrenCollection
          .where('parent', isEqualTo: parentId)
          .get();
      
      // Merge results, avoiding duplicates
      final allDocs = <String, DocumentSnapshot>{};
      
      for (var doc in querySnapshot1.docs) {
        allDocs[doc.id] = doc;
      }
      
      for (var doc in querySnapshot2.docs) {
        allDocs[doc.id] = doc;
      }
      
      return allDocs.values
          .map((doc) => Child.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting children by parent ID: $e');
      return [];
    }
  }

  /// Add a new child to the database
  Future<void> addChild(Child child) async {
    try {
      await _childrenCollection.doc(child.id).set(child.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding child: $e');
      rethrow;
    }
  }

  /// Create test account
  Future<AppUser> createTestAccount({String? email, String? password, UserRole? role, String? name, String? userId}) async {
    try {
      // Default values for test accounts if not provided
      email = email ?? 'test@example.com';
      password = password ?? 'password123';
      role = role ?? UserRole.parent;
      name = name ?? 'Test User';
      
      // Create the user in Firebase Auth
      UserCredential userCredential;
      if (userId == null) {
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        userId = userCredential.user!.uid;
      }
      
      // Create the user in Firestore
      final userData = {
        'id': userId,
        'email': email,
        'name': name,
        'role': role.toString().split('.').last,
        'childrenIds': [],
        'createdAt': FieldValue.serverTimestamp(),
        'additionalInfo': {
          'onboardingCompleted': true,
        },
      };
      
      await _usersCollection.doc(userId).set(userData);
      
      // Return the created user
      return AppUser(
        id: userId,
        email: email,
        name: name,
        role: role,
        childrenIds: [],
        createdAt: DateTime.now(),
        additionalInfo: {
          'onboardingCompleted': true,
        },
      );
    } catch (e) {
      debugPrint('Error creating test account: $e');
      rethrow;
    }
  }

  /// Create initial therapist profile
  Future<void> createInitialTherapistProfile({String? userId, String? name, String? email, Map<String, dynamic>? data}) async {
    try {
      if (userId == null) {
        // Get current user if not provided
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('No authenticated user found');
        }
        userId = currentUser.uid;
      }

      data = data ?? {
        'onboardingCompleted': true,
        'specialties': [],
        'experience': '',
        'bio': '',
      };
      
      if (name != null) {
        data['name'] = name;
      }
      
      if (email != null) {
        data['email'] = email;
      }
      
      await _usersCollection.doc(userId).update({
        'additionalInfo': data,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating initial therapist profile: $e');
      rethrow;
    }
  }

  /// Get upcoming sessions by therapist ID
  Future<List<Map<String, dynamic>>> getUpcomingSessionsByTherapistId(String therapistId) async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _sessionsCollection
          .where('therapistId', isEqualTo: therapistId)
          .where('startTime', isGreaterThan: now.millisecondsSinceEpoch)
          .orderBy('startTime')
          .limit(10)
          .get();
      
      final sessions = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
      
      // If empty, return mock data for testing
      if (sessions.isEmpty) {
        return _getMockSessions(therapistId);
      }
      
      return sessions;
    } catch (e) {
      debugPrint('Error getting upcoming sessions: $e');
      // Return mock data on error for robustness
      return _getMockSessions(therapistId);
    }
  }
  
  /// Get mock sessions for testing
  List<Map<String, dynamic>> _getMockSessions(String therapistId) {
    final now = DateTime.now();
    return List.generate(3, (index) {
      final startTime = now.add(Duration(days: index + 1, hours: 9));
      return {
        'id': 'mock-session-$index',
        'therapistId': therapistId,
        'patientId': 'mock-patient-$index',
        'patientName': 'Test Patient ${index + 1}',
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': startTime.add(const Duration(hours: 1)).millisecondsSinceEpoch,
        'status': 'scheduled',
        'notes': 'Mock session for testing',
      };
    });
  }

  /// Get recent alerts by therapist ID
  Future<List<DistressAlert>> getRecentAlertsByTherapistId(String therapistId) async {
    try {
      // First, get all patients for this therapist
      final patients = await getPatientsByTherapistId(therapistId);
      
      if (patients.isEmpty) {
        return [];
      }
      
      // Get patient IDs
      final patientIds = patients.map((p) => p.id).toList();
      
      // Unfortunately, Firestore doesn't support querying for multiple values in an array
      // So we need to make multiple queries
      final alerts = <DistressAlert>[];
      
      // Query alerts for each patient
      for (final patientId in patientIds) {
        final querySnapshot = await _alertsCollection
            .where('patientId', isEqualTo: patientId)
            .where('resolved', isEqualTo: false)
            .orderBy('timestamp', descending: true)
            .limit(5)
            .get();
        
        final patientAlerts = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return DistressAlert.fromJson({
            'id': doc.id,
            ...data,
          });
        }).toList();
        
        alerts.addAll(patientAlerts);
      }
      
      // Sort combined alerts by timestamp
      alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return alerts;
    } catch (e) {
      debugPrint('Error getting recent alerts: $e');
      return [];
    }
  }

  /// Get conversations by user ID
  Future<List<Conversation>> getConversationsByUserId(String userId) async {
    try {
      final querySnapshot = await _conversationsCollection
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTimestamp', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        
        return Conversation(
          id: doc.id,
          participants: participants,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastMessageAt: (data['lastMessageTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastMessageText: data['lastMessage'] as String?,
          metadata: data['metadata'] as Map<String, dynamic>?,
          unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting conversations: $e');
      return [];
    }
  }

  /// Subscribe to conversations
  StreamSubscription<QuerySnapshot> subscribeToConversations(
    String userId,
    Function(List<Conversation>) onData,
    {Function(dynamic)? onError}
  ) {
    return _conversationsCollection
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final conversations = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final participants = List<String>.from(data['participants'] ?? []);
              
              return Conversation(
                id: doc.id,
                participants: participants,
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                lastMessageAt: (data['lastMessageTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                lastMessageText: data['lastMessage'] as String?,
                metadata: data['metadata'] as Map<String, dynamic>?,
                unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
              );
            }).toList();
            onData(conversations);
          },
          onError: onError,
        );
  }

  /// Get or create conversation
  Future<Conversation> getOrCreateConversation(
    String userId, 
    String otherUserId, 
    {String? title, Map<String, dynamic>? metadata}
  ) async {
    try {
      // Check if conversation already exists
      final querySnapshot = await _conversationsCollection
          .where('participants', arrayContains: userId)
          .get();
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        
        if (participants.contains(otherUserId)) {
          final existingConversation = Conversation(
            id: doc.id,
            participants: participants,
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            lastMessageAt: (data['lastMessageTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            lastMessageText: data['lastMessage'] as String?,
            metadata: data['metadata'] as Map<String, dynamic>?,
            unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
          );
          debugPrint('getOrCreateConversation: Found existing conversation with ID: ${existingConversation.id}');
          return existingConversation;
        }
      }
      
      // Get user details for metadata
      final currentUser = await getUser(userId);
      final otherUser = await getUser(otherUserId);
      
      if (currentUser == null || otherUser == null) {
        throw Exception('Could not find user details');
      }
      
      // Create new conversation
      final conversationData = {
        'participants': [userId, otherUserId],
        'title': title ?? 'New Conversation',
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'metadata': {
          ...metadata ?? {},
          'userNames': {
            userId: currentUser.name,
            otherUserId: otherUser.name,
          },
          'userRoles': {
            userId: currentUser.role.toString().split('.').last,
            otherUserId: otherUser.role.toString().split('.').last,
          },
        },
        'unreadCount': {
          userId: 0,
          otherUserId: 0,
        },
      };
      
      final docRef = await _conversationsCollection.add(conversationData);
      
      final newConversation = Conversation(
        id: docRef.id,
        participants: [userId, otherUserId],
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
        metadata: conversationData['metadata'] as Map<String, dynamic>,
        unreadCount: Map<String, int>.from(conversationData['unreadCount'] as Map<String, dynamic>),
      );
      debugPrint('getOrCreateConversation: Created new conversation with ID: ${newConversation.id}');
      return newConversation;
    } catch (e) {
      debugPrint('Error getting/creating conversation: $e');
      rethrow;
    }
  }

  /// Get conversation
  Future<Conversation?> getConversation(String conversationId) async {
    try {
      final docSnapshot = await _conversationsCollection.doc(conversationId).get();
      if (!docSnapshot.exists) {
        return null;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);
      
      return Conversation(
        id: docSnapshot.id,
        participants: participants,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastMessageAt: (data['lastMessageTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastMessageText: data['lastMessage'] as String?,
        metadata: data['metadata'] as Map<String, dynamic>?,
        unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      );
    } catch (e) {
      debugPrint('Error getting conversation: $e');
      return null;
    }
  }

  /// Send message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    String? receiverId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Create message
      final messageData = {
        'conversationId': conversationId,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'text': content, // For backward compatibility
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'read': false, // For backward compatibility
        'metadata': metadata ?? {},
      };
      
      // Add message to Firestore
      await _messagesCollection.add(messageData);
      
      // Get the conversation to update unread count
      final conversationDoc = await _conversationsCollection.doc(conversationId).get();
      final conversationData = conversationDoc.data() as Map<String, dynamic>;
      final unreadCount = Map<String, int>.from(conversationData['unreadCount'] ?? {});
      
      // Increment unread count for receiver
      if (receiverId != null) {
        final currentCount = unreadCount[receiverId] ?? 0;
        unreadCount[receiverId] = currentCount + 1;

        // Create notification for new message
        final senderDoc = await _usersCollection.doc(senderId).get();
        final senderData = senderDoc.data() as Map<String, dynamic>;
        final senderName = senderData['displayName'] as String? ?? 'Someone';

        await _notificationsCollection.add({
          'userId': receiverId,
          'type': 'newMessage',
          'title': 'New Message',
          'message': '$senderName sent you a message',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'data': {
            'conversationId': conversationId,
            'senderId': senderId,
          },
        });
      }
      
      // Update conversation with last message and unread count
      await _conversationsCollection.doc(conversationId).update({
        'lastMessage': content,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'unreadCount': unreadCount,
      });
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Subscribe to messages
  StreamSubscription<QuerySnapshot> subscribeToMessages(
    String conversationId,
    Function(List<Message>) onData,
    {Function(dynamic)? onError}
  ) {
    return _messagesCollection
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            final messages = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              
              return Message(
                id: doc.id,
                conversationId: data['conversationId'] as String,
                senderId: data['senderId'] as String,
                receiverId: data['receiverId'] as String? ?? '',
                content: data['content'] as String? ?? data['text'] as String? ?? '',
                type: MessageType.text, // Default to text
                timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                isRead: data['isRead'] as bool? ?? data['read'] as bool? ?? false,
                metadata: data['metadata'] as Map<String, dynamic>?,
              );
            }).toList();
            onData(messages);
          },
          onError: onError,
        );
  }

  /// Get messages for conversation
  Future<List<Message>> getMessagesForConversation(String conversationId, {int? limit}) async {
    try {
      var query = _messagesCollection
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('timestamp', descending: false);
      
      // Apply limit if provided
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        return Message(
          id: doc.id,
          conversationId: data['conversationId'] as String,
          senderId: data['senderId'] as String,
          receiverId: data['receiverId'] as String? ?? '',
          content: data['content'] as String? ?? data['text'] as String? ?? '',
          type: MessageType.text, // Default to text
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] as bool? ?? data['read'] as bool? ?? false,
          metadata: data['metadata'] as Map<String, dynamic>?,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting messages: $e');
      return [];
    }
  }

  /// Create mission
  Future<void> createMission(Mission mission) async {
    try {
      await _missionsCollection.add(mission.toJson());
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating mission: $e');
      rethrow;
    }
  }

  /// Update mission
  Future<void> updateMission(Mission mission) async {
    try {
      await _missionsCollection.doc(mission.id).update(mission.toJson());
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating mission: $e');
      rethrow;
    }
  }

  /// Get emotions for date range
  Future<List<EmotionData>> getEmotionsForDateRange(
    String childId, 
    DateTime startDate, 
    DateTime endDate, 
    {int? limit}
  ) async {
    try {
      final startTimestamp = startDate.millisecondsSinceEpoch;
      final endTimestamp = endDate.millisecondsSinceEpoch;
      
      var query = _emotionsCollection
          .where('childId', isEqualTo: childId)
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .where('timestamp', isLessThanOrEqualTo: endTimestamp)
          .orderBy('timestamp');
      
      // Apply limit if provided
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EmotionData.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      debugPrint('Error getting emotions for date range: $e');
      return [];
    }
  }

  /// For backwards compatibility - accepts limit as positional parameter
  Future<List<EmotionData>> getEmotionsForDateRange2(
    String childId, 
    DateTime startDate, 
    DateTime endDate, 
    [int? limit]
  ) {
    return getEmotionsForDateRange(childId, startDate, endDate, limit: limit);
  }

  /// Get missions by child
  Future<List<Mission>> getMissionsByChild(String childId, {int limit = 10}) async {
    try {
      final querySnapshot = await _missionsCollection
          .where('childId', isEqualTo: childId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Mission.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      debugPrint('Error getting missions by child: $e');
      return [];
    }
  }

  /// Get community posts by user
  Future<List<Map<String, dynamic>>> getCommunityPostsByUser(String userId, {int limit = 5}) async {
    try {
      final querySnapshot = await _firestore.collection('community_posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting community posts: $e');
      return [];
    }
  }

  /// Get patient stats
  Future<Map<String, dynamic>> getPatientStats(String patientId) async {
    try {
      // Get emotion count
      final emotionQuery = await _emotionsCollection
          .where('childId', isEqualTo: patientId)
          .get();
      
      // Get missions count
      final missionsQuery = await _missionsCollection
          .where('childId', isEqualTo: patientId)
          .get();
      
      // Get completed missions count
      final completedMissionsQuery = await _missionsCollection
          .where('childId', isEqualTo: patientId)
          .where('completed', isEqualTo: true)
          .get();
      
      // Get alerts count
      final alertsQuery = await _alertsCollection
          .where('patientId', isEqualTo: patientId)
          .get();
      
      return {
        'emotionCount': emotionQuery.docs.length,
        'missionsCount': missionsQuery.docs.length,
        'completedMissionsCount': completedMissionsQuery.docs.length,
        'alertsCount': alertsQuery.docs.length,
      };
    } catch (e) {
      debugPrint('Error getting patient stats: $e');
      return {
        'emotionCount': 0,
        'missionsCount': 0,
        'completedMissionsCount': 0,
        'alertsCount': 0,
      };
    }
  }

  /// Get patient metadata
  Future<Map<String, dynamic>> getPatientMetadata(String patientId) async {
    try {
      final docSnapshot = await _childrenCollection.doc(patientId).get();
      if (!docSnapshot.exists) {
        return {};
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      return data['metadata'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      debugPrint('Error getting patient metadata: $e');
      return {};
    }
  }

  /// Update patient metadata
  Future<void> updatePatientMetadata(String patientId, Map<String, dynamic> metadata) async {
    try {
      // Get current metadata
      final currentMetadata = await getPatientMetadata(patientId);
      
      // Merge with new metadata
      final updatedMetadata = {
        ...currentMetadata,
        ...metadata,
      };
      
      // Update in Firestore
      await _childrenCollection.doc(patientId).update({
        'metadata': updatedMetadata,
      });
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating patient metadata: $e');
      rethrow;
    }
  }

  /// Get therapist custom tags
  Future<List<String>> getTherapistCustomTags() async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return [];
      }
      
      final docSnapshot = await _usersCollection.doc(currentUser.uid).get();
      if (!docSnapshot.exists) {
        return [];
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      final additionalInfo = data['additionalInfo'] as Map<String, dynamic>? ?? {};
      
      final tags = additionalInfo['customTags'] as List<dynamic>? ?? [];
      return tags.map((tag) => tag.toString()).toList();
    } catch (e) {
      debugPrint('Error getting therapist custom tags: $e');
      return [];
    }
  }

  /// Get therapist custom groups
  Future<List<String>> getTherapistCustomGroups() async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return [];
      }
      
      final docSnapshot = await _usersCollection.doc(currentUser.uid).get();
      if (!docSnapshot.exists) {
        return [];
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      final additionalInfo = data['additionalInfo'] as Map<String, dynamic>? ?? {};
      
      final groups = additionalInfo['customGroups'] as List<dynamic>? ?? [];
      return groups.map((group) => group.toString()).toList();
    } catch (e) {
      debugPrint('Error getting therapist custom groups: $e');
      return [];
    }
  }

  /// Save therapist custom tag
  Future<void> saveTherapistCustomTag(String tag) async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return;
      }
      
      // Get current tags
      final currentTags = await getTherapistCustomTags();
      
      // Add new tag if not already present
      if (!currentTags.contains(tag)) {
        currentTags.add(tag);
        
        // Update in Firestore
        await _usersCollection.doc(currentUser.uid).update({
          'additionalInfo.customTags': currentTags,
        });
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error saving therapist custom tag: $e');
      rethrow;
    }
  }

  /// Save therapist custom group
  Future<void> saveTherapistCustomGroup(String group) async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return;
      }
      
      // Get current groups
      final currentGroups = await getTherapistCustomGroups();
      
      // Add new group if not already present
      if (!currentGroups.contains(group)) {
        currentGroups.add(group);
        
        // Update in Firestore
        await _usersCollection.doc(currentUser.uid).update({
          'additionalInfo.customGroups': currentGroups,
        });
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error saving therapist custom group: $e');
      rethrow;
    }
  }

  /// Get emotion data
  Future<List<EmotionData>> getEmotionData(String childId, {int limit = 20}) async {
    try {
      final querySnapshot = await _emotionsCollection
          .where('childId', isEqualTo: childId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EmotionData.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      debugPrint('Error getting emotion data: $e');
      return [];
    }
  }

  /// Get distress alerts
  Future<List<DistressAlert>> getDistressAlerts(String childId) async {
    try {
      final querySnapshot = await _alertsCollection
          .where('patientId', isEqualTo: childId)
          .where('resolved', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return DistressAlert.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      debugPrint('Error getting distress alerts: $e');
      return [];
    }
  }

  /// Resolve alert
  Future<void> resolveAlert(String alertId) async {
    try {
      await _alertsCollection.doc(alertId).update({
        'resolved': true,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error resolving alert: $e');
      rethrow;
    }
  }

  /// Subscribe to patients
  StreamSubscription<QuerySnapshot> subscribeToPatients(
    String therapistId,
    Function(List<Child>) onData,
    {Function(dynamic)? onError}
  ) {
    return _childrenCollection
        .where('therapistId', isEqualTo: therapistId)
        .snapshots()
        .listen(
          (snapshot) {
            final patients = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Child.fromFirestore(doc);
            }).toList();
            onData(patients);
          },
          onError: onError,
        );
  }

  /// Subscribe to distress alerts
  StreamSubscription<QuerySnapshot> subscribeToDistressAlerts(
    String therapistId,
    Function(List<DistressAlert>) onData,
    {Function(dynamic)? onError}
  ) {
    // First, get all patients for this therapist
    return _childrenCollection
        .where('therapistId', isEqualTo: therapistId)
        .snapshots()
        .listen(
          (snapshot) async {
            try {
              final patients = snapshot.docs.map((doc) => Child.fromFirestore(doc)).toList();
              final patientIds = patients.map((p) => p.id).toList();
              
              if (patientIds.isEmpty) {
                onData([]);
                return;
              }
              
              // Get alerts for each patient
              final alerts = <DistressAlert>[];
              
              for (final patientId in patientIds) {
                final alertSnapshot = await _alertsCollection
                    .where('patientId', isEqualTo: patientId)
                    .where('resolved', isEqualTo: false)
                    .orderBy('timestamp', descending: true)
                    .limit(5)
                    .get();
                
                final patientAlerts = alertSnapshot.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DistressAlert.fromJson({
                    'id': doc.id,
                    ...data,
                  });
                }).toList();
                
                alerts.addAll(patientAlerts);
              }
              
              // Sort combined alerts by timestamp
              alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
              
              onData(alerts);
            } catch (e) {
              if (onError != null) {
                onError(e);
              } else {
                debugPrint('Error in distress alerts subscription: $e');
              }
            }
          },
          onError: onError,
        );
  }

  /// Subscribe to notifications
  StreamSubscription<QuerySnapshot> subscribeToNotifications(
    String userId,
    Function(List<Map<String, dynamic>>) onData,
    {Function(dynamic)? onError}
  ) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final notifications = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                ...data,
              };
            }).toList();
            onData(notifications);
          },
          onError: onError,
        );
  }

  /// Get notifications for user
  Future<List<Map<String, dynamic>>> getNotificationsForUser(String userId) async {
    try {
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      
      final batch = _firestore.batch();
      
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Create child
  Future<Child> createChild({
    required String name,
    required int age,
    required String gender,
    required String parentId,
    required List<String> concerns,
    String? avatar,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      final child = Child(
        id: const Uuid().v4(),
        name: name,
        age: age,
        gender: gender,
        parentId: parentId,
        concerns: concerns,
        avatar: avatar,
        additionalInfo: additionalInfo,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('children').doc(child.id).set(child.toMap());
      return child;
    } catch (e) {
      debugPrint('Error creating child: $e');
      rethrow;
    }
  }

  /// Link child to user
  Future<void> linkChildToUser(String userId, String childId) async {
    try {
      // Update user document
      await _usersCollection.doc(userId).update({
        'childrenIds': FieldValue.arrayUnion([childId]),
      });
      
      // Get user data
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Check if user is parent or therapist
      final userRole = userData['role'];
      
      // Update child document based on user role
      if (userRole == 'parent') {
        await _childrenCollection.doc(childId).update({
          'parentId': userId,
          'parent': userId, // Added for compatibility with security rules
        });
      } else if (userRole == 'therapist') {
        await _childrenCollection.doc(childId).update({
          'therapistId': userId,
        });
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error linking child to user: $e');
      rethrow;
    }
  }

  /// Unlink child from user
  Future<void> unlinkChildFromUser(String userId, String childId) async {
    try {
      // Update user document
      await _usersCollection.doc(userId).update({
        'childrenIds': FieldValue.arrayRemove([childId]),
      });
      
      // Get user data
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Check if user is parent or therapist
      final userRole = userData['role'];
      
      // Update child document based on user role
      if (userRole == 'parent') {
        await _childrenCollection.doc(childId).update({
          'parentId': null,
          'parent': null, // Added for compatibility with security rules
        });
      } else if (userRole == 'therapist') {
        await _childrenCollection.doc(childId).update({
          'therapistId': null,
        });
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error unlinking child from user: $e');
      rethrow;
    }
  }

  /// Update child
  Future<void> updateChild(Child child) async {
    try {
      await _firestore.collection('children').doc(child.id).update(child.toMap());
    } catch (e) {
      debugPrint('Error updating child: $e');
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      final querySnapshot = await _messagesCollection
          .where('conversationId', isEqualTo: conversationId)
          .where('senderId', isNotEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      
      final batch = _firestore.batch();
      
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('last_sync_time');
      
      if (timestamp == null) {
        return null;
      }
      
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      debugPrint('Error getting last sync time: $e');
      return null;
    }
  }

  /// Test database permissions
  Future<Map<String, bool>> testDatabasePermissions() async {
    final results = <String, bool>{};
    
    try {
      // Test read permissions
      results['canReadUsers'] = await _canReadCollection('users');
      results['canReadChildren'] = await _canReadCollection('children');
      results['canReadEmotions'] = await _canReadCollection('emotions');
      results['canReadMissions'] = await _canReadCollection('missions');
      results['canReadAlerts'] = await _canReadCollection('alerts');
      results['canReadConversations'] = await _canReadCollection('conversations');
      results['canReadMessages'] = await _canReadCollection('messages');
      
      // Test write permissions
      results['canWriteUsers'] = await _canWriteCollection('users');
      results['canWriteChildren'] = await _canWriteCollection('children');
      results['canWriteEmotions'] = await _canWriteCollection('emotions');
      results['canWriteMissions'] = await _canWriteCollection('missions');
      results['canWriteAlerts'] = await _canWriteCollection('alerts');
      results['canWriteConversations'] = await _canWriteCollection('conversations');
      results['canWriteMessages'] = await _canWriteCollection('messages');
      
      return results;
    } catch (e) {
      debugPrint('Error testing database permissions: $e');
      return {'error': false};
    }
  }
  
  /// Helper to test read permissions
  Future<bool> _canReadCollection(String collectionName) async {
    try {
      await _firestore.collection(collectionName).limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Helper to test write permissions
  Future<bool> _canWriteCollection(String collectionName) async {
    try {
      // Create a test document
      final docRef = await _firestore.collection(collectionName).add({
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Delete the test document
      await docRef.delete();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Create suggestion
  Future<void> createSuggestion({
    String? patientId,
    String? childId,
    required String title,
    required String description,
    List<String>? emotions,
    List<dynamic>? targetEmotions,
    required dynamic category,
  }) async {
    try {
      // Use childId as patientId if patientId is not provided
      final finalPatientId = patientId ?? childId;
      
      if (finalPatientId == null) {
        throw Exception('Either patientId or childId must be provided');
      }
      
      // Process emotions
      List<String> finalEmotions = [];
      if (emotions != null && emotions.isNotEmpty) {
        finalEmotions = emotions;
      } else if (targetEmotions != null && targetEmotions.isNotEmpty) {
        finalEmotions = targetEmotions.map((e) => e.toString().split('.').last).toList();
      }
      
      // Convert category to string if it's an enum
      String categoryStr;
      if (category is String) {
        categoryStr = category;
      } else if (category is SuggestionCategory) {
        categoryStr = category.toString().split('.').last;
      } else {
        categoryStr = category.toString();
      }
      
      // Create suggestion data
      final suggestionData = {
        'patientId': finalPatientId,
        'title': title,
        'description': description,
        'emotions': finalEmotions,
        'category': categoryStr,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      };
      
      // Add to Firestore
      await _suggestionsCollection.add(suggestionData);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating suggestion: $e');
      rethrow;
    }
  }

  /// Submit suggestion feedback
  Future<void> submitSuggestionFeedback({
    required String suggestionId,
    String? childId,
    String? parentId,
    EffectivenessRating? rating,
    EmotionType? beforeEmotion,
    double? beforeIntensity,
    EmotionType? afterEmotion,
    double? afterIntensity,
    String? comments,
    bool? wasCompleted,
    bool? helpful,
    String? feedback
  }) async {
    try {
      helpful = helpful ?? true;
      feedback = feedback ?? comments ?? '';
      
      final feedbackData = {
        'helpful': helpful,
        'feedback': feedback,
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      // Add additional fields if provided
      if (childId != null) {
        feedbackData['childId'] = childId;
      }
      
      if (parentId != null) {
        feedbackData['parentId'] = parentId;
      }
      
      if (rating != null) {
        feedbackData['rating'] = rating.toString();
      }
      
      if (beforeEmotion != null) {
        feedbackData['beforeEmotion'] = beforeEmotion.toString();
      }
      
      if (beforeIntensity != null) {
        feedbackData['beforeIntensity'] = beforeIntensity;
      }
      
      if (afterEmotion != null) {
        feedbackData['afterEmotion'] = afterEmotion.toString();
      }
      
      if (afterIntensity != null) {
        feedbackData['afterIntensity'] = afterIntensity;
      }
      
      if (wasCompleted != null) {
        feedbackData['wasCompleted'] = wasCompleted;
      }
      
      await _suggestionsCollection.doc(suggestionId).update({
        'feedbacks': FieldValue.arrayUnion([feedbackData]),
      });
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error submitting suggestion feedback: $e');
      rethrow;
    }
  }

  /// Add therapist to favorites
  Future<void> addTherapistToFavorites(String userId, String therapistId) async {
    try {
      await _usersCollection.doc(userId).update({
        'favoriteTherapists': FieldValue.arrayUnion([therapistId]),
      });
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding therapist to favorites: $e');
      rethrow;
    }
  }

  /// Create or update user
  Future<void> createOrUpdateUser(AppUser user) async {
    try {
      // Convert AppUser to a Map
      final userData = {
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'role': user.role.toString().split('.').last,
        'childrenIds': user.childrenIds,
        'createdAt': user.createdAt != null ? Timestamp.fromDate(user.createdAt!) : FieldValue.serverTimestamp(),
        'additionalInfo': user.additionalInfo ?? {},
      };
      
      await _usersCollection.doc(user.id).set(userData, SetOptions(merge: true));
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating/updating user: $e');
      rethrow;
    }
  }

  /// Notify therapist of assignment
  Future<void> notifyTherapistOfAssignment(String therapistId, dynamic child, String parentId) async {
    try {
      // Handle case where child is a Child object
      String childId;
      String childName;
      
      if (child is String) {
        childId = child;
        // Get child data
        final childDoc = await _childrenCollection.doc(childId).get();
        final childData = childDoc.data() as Map<String, dynamic>;
        childName = childData['name'] as String;
      } else if (child is Child) {
        childId = child.id;
        childName = child.name;
      } else {
        throw Exception('Invalid child parameter: must be String ID or Child object');
      }
      
      // Get parent data
      final parentDoc = await _usersCollection.doc(parentId).get();
      final parentData = parentDoc.data() as Map<String, dynamic>;
      final parentName = parentData['name'] as String;
      
      // Create notification
      final notificationData = {
        'userId': therapistId,
        'type': 'new_patient',
        'title': 'New Patient Assigned',
        'message': '$parentName has assigned their child $childName as your patient.',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'data': {
          'childId': childId,
          'parentId': parentId,
        },
      };
      
      await _notificationsCollection.add(notificationData);
    } catch (e) {
      debugPrint('Error notifying therapist of assignment: $e');
      rethrow;
    }
  }

  /// Get calming suggestions (returns Map instead of CalmingSuggestion)
  Future<List<CalmingSuggestion>> getCalmingSuggestions(String childId) async {
    try {
      final querySnapshot = await _suggestionsCollection
          .where('patientId', isEqualTo: childId)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();
      
      final suggestions = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final suggestionData = {
          'id': doc.id,
          ...data,
        };
        
        final targetEmotionsStrings = List<String>.from(data['emotions'] ?? []);
        final targetEmotions = targetEmotionsStrings.map((e) => _parseEmotionType(e)).toList();
        
        return CalmingSuggestion(
          id: doc.id,
          childId: data['patientId'] ?? childId,
          title: data['title'] ?? 'Untitled Suggestion',
          description: data['description'] ?? 'No description provided',
          targetEmotions: targetEmotions,
          category: _parseSuggestionCategory(data['category'] ?? 'cognitive'),
          imageUrl: data['imageUrl'],
          estimatedTime: data['estimatedTimeMinutes'] != null 
              ? Duration(minutes: data['estimatedTimeMinutes']) 
              : null,
          isFavorite: data['isFavorite'] ?? false,
        );
      }).toList();
      
      return suggestions;
    } catch (e) {
      debugPrint('Error getting calming suggestions: $e');
      return [];
    }
  }
  
  /// Alias for getCalmingSuggestions for backwards compatibility
  Future<List<CalmingSuggestion>> getCalmingSuggestions2(String childId) async {
    return getCalmingSuggestions(childId);
  }
  
  /// Parse EmotionType from string
  EmotionType _parseEmotionType(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
        return EmotionType.joy;
      case 'sadness':
        return EmotionType.sadness;
      case 'anger':
        return EmotionType.anger;
      case 'fear':
        return EmotionType.fear;
      case 'calm':
        return EmotionType.calm;
      default:
        return EmotionType.calm;
    }
  }
  
  /// Parse SuggestionCategory from string
  SuggestionCategory _parseSuggestionCategory(String category) {
    switch (category.toLowerCase()) {
      case 'physical':
        return SuggestionCategory.physical;
      case 'creative':
        return SuggestionCategory.creative;
      case 'cognitive':
        return SuggestionCategory.cognitive;
      case 'sensory':
        return SuggestionCategory.sensory;
      case 'social':
        return SuggestionCategory.social;
      default:
        return SuggestionCategory.cognitive;
    }
  }

  /// Get conversations for user
  Future<List<Conversation>> getConversationsForUser(String userId) async {
    return getConversationsByUserId(userId);
  }

  /// Creates a new user in Firestore
  Future<bool> createUser({
    required String email,
    required String fullName,
    required String userType,
    String? userId,
    String? phoneNumber,
    String? profileImageUrl,
    List<String>? childrenIds,
    String? parentId,
    String? therapistId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userData = {
        'email': email,
        'fullName': fullName,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        if (childrenIds != null) 'childrenIds': childrenIds,
        if (parentId != null) 'parentId': parentId,
        if (therapistId != null) 'therapistId': therapistId,
        if (additionalData != null) ...additionalData,
      };

      // Use provided userId or generate a new one
      final userDoc = userId != null 
          ? _firestore.collection('users').doc(userId)
          : _firestore.collection('users').doc();

      await userDoc.set(userData);
      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  /// Diagnostic function to verify child creation and parentage
  Future<Map<String, dynamic>> checkChildParentRelationship(String parentId, String childId) async {
    try {
      // Get child document
      final childDoc = await _childrenCollection.doc(childId).get();
      if (!childDoc.exists) {
        return {
          'success': false,
          'message': 'Child document does not exist',
          'childId': childId,
          'parentId': parentId,
        };
      }
      
      final childData = childDoc.data() as Map<String, dynamic>;
      
      // Check parent fields
      final storedParentId = childData['parentId'];
      final storedParent = childData['parent'];
      
      // Get parent document to verify the relationship
      final parentDoc = await _usersCollection.doc(parentId).get();
      if (!parentDoc.exists) {
        return {
          'success': false,
          'message': 'Parent document does not exist',
          'childId': childId,
          'parentId': parentId,
        };
      }
      
      final parentData = parentDoc.data() as Map<String, dynamic>;
      final childrenIds = List<String>.from(parentData['childrenIds'] ?? []);
      
      return {
        'success': true,
        'childExists': true,
        'parentExists': true,
        'parentIdField': storedParentId,
        'parentField': storedParent,
        'parentIdMatches': storedParentId == parentId,
        'parentFieldMatches': storedParent == parentId,
        'childLinkedToParent': childrenIds.contains(childId),
        'childData': childData,
        'childrenIdsInParent': childrenIds,
      };
    } catch (e) {
      debugPrint('Error checking child-parent relationship: $e');
      return {
        'success': false,
        'message': e.toString(),
        'childId': childId,
        'parentId': parentId,
      };
    }
  }

  /// Link a child to a parent
  Future<void> linkChildToParent(String childId, String parentId) async {
    try {
      await _childrenCollection.doc(childId).update({
        'parentId': parentId,
      });

      await _usersCollection.doc(parentId).update({
        'childrenIds': FieldValue.arrayUnion([childId]),
      });
    } catch (e) {
      debugPrint('Error linking child to parent: $e');
      rethrow;
    }
  }

  /// Verify parent-child relationship
  Future<bool> verifyParentChildRelationship(String parentId, String childId) async {
    try {
      final childDoc = await _childrenCollection.doc(childId).get();
      final parentDoc = await _usersCollection.doc(parentId).get();

      if (!childDoc.exists || !parentDoc.exists) return false;

      final childData = childDoc.data() as Map<String, dynamic>;
      final parentData = parentDoc.data() as Map<String, dynamic>;

      final childParentId = childData['parentId'] as String?;
      final parentChildIds = List<String>.from(parentData['childrenIds'] ?? []);

      return childParentId == parentId && parentChildIds.contains(childId);
    } catch (e) {
      debugPrint('Error verifying parent-child relationship: $e');
      return false;
    }
  }

  /// Fix parent-child relationship
  Future<void> fixParentChildRelationship(String parentId, String childId) async {
    try {
      // Update child's parentId
      await _childrenCollection.doc(childId).update({
        'parentId': parentId,
      });

      // Update parent's childrenIds
      await _usersCollection.doc(parentId).update({
        'childrenIds': FieldValue.arrayUnion([childId]),
      });
    } catch (e) {
      debugPrint('Error fixing parent-child relationship: $e');
      rethrow;
    }
  }

  /// Assign a therapist to a child and create a payment record
  Future<void> assignTherapistToChild({
    required String childId,
    required String therapistId,
    required num therapistFee,
    required String parentId,
  }) async {
    try {
      // Update the child document with therapistId and therapistFee
      await _childrenCollection.doc(childId).update({
        'therapistId': therapistId,
        'therapistFee': therapistFee,
        'additionalInfo.assignedTherapistId': therapistId,
        'additionalInfo.assignmentDate': DateTime.now().toIso8601String(),
      });

      // Optionally, add the childId to the therapist's user document (childrenIds array)
      await _usersCollection.doc(therapistId).update({
        'childrenIds': FieldValue.arrayUnion([childId]),
      });

      // Create a payment record
      await createPayment(
        parentId: parentId,
        childId: childId,
        therapistId: therapistId,
        amount: therapistFee,
        status: 'pending',
      );
    } catch (e) {
      debugPrint('Error assigning therapist to child: $e');
      rethrow;
    }
  }

  /// Create a payment record for therapist assignment or session
  Future<void> createPayment({
    required String parentId,
    required String childId,
    required String therapistId,
    required num amount,
    required String status, // e.g., 'pending', 'paid', 'failed'
  }) async {
    try {
      await _firestore.collection('payments').add({
        'parentId': parentId,
        'childId': childId,
        'therapistId': therapistId,
        'amount': amount,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating payment record: $e');
      rethrow;
    }
  }

  /// Update payment status for a given parent, child, and therapist
  Future<void> updatePaymentStatus({
    required String parentId,
    required String childId,
    required String therapistId,
    required String status, // e.g., 'paid', 'pending', 'failed'
  }) async {
    try {
      final query = await _firestore.collection('payments')
        .where('parentId', isEqualTo: parentId)
        .where('childId', isEqualTo: childId)
        .where('therapistId', isEqualTo: therapistId)
        .where('status', isNotEqualTo: status) // Only update if not already set
        .limit(1)
        .get();
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        await doc.reference.update({'status': status});
      }
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      rethrow;
    }
  }

  /// Get connection requests for a given parent ID
  Future<List<ConnectionRequest>> getConnectionRequests(String parentId) async {
    try {
      final querySnapshot = await _firestore.collection('connectionRequests')
          .where('parentId', isEqualTo: parentId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ConnectionRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting connection requests: $e');
      return [];
    }
  }

  /// Get therapists by a list of their IDs
  Future<List<AppUser>> getTherapistsByIds(List<String> therapistIds) async {
    if (therapistIds.isEmpty) {
      return [];
    }
    try {
      final querySnapshot = await _usersCollection
          .where(FieldPath.documentId, whereIn: therapistIds)
          .get();
      
      return querySnapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting therapists by IDs: $e');
      return [];
    }
  }

  /// Mark a specific message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      final messageDoc = await _messagesCollection.doc(messageId).get();
      if (!messageDoc.exists) return;
      
      final messageData = messageDoc.data() as Map<String, dynamic>;
      final conversationId = messageData['conversationId'] as String;
      final receiverId = messageData['receiverId'] as String;
      
      // Mark message as read
      await _messagesCollection.doc(messageId).update({'isRead': true});
      
      // Update conversation unread count
      final conversationDoc = await _conversationsCollection.doc(conversationId).get();
      if (!conversationDoc.exists) return;
      
      final conversationData = conversationDoc.data() as Map<String, dynamic>;
      final unreadCount = Map<String, int>.from(conversationData['unreadCount'] ?? {});
      
      // Reset unread count for the receiver
      if (unreadCount.containsKey(receiverId)) {
        unreadCount[receiverId] = 0;
        await _conversationsCollection.doc(conversationId).update({
          'unreadCount': unreadCount,
        });
      }
    } catch (e) {
      debugPrint('Error marking message as read: $e');
      rethrow;
    }
  }

  /// Update the unread count for a specific user in a conversation
  Future<void> updateConversationUnreadCount(String conversationId, String userId, int count) async {
    try {
      await _conversationsCollection.doc(conversationId).update({
        'unreadCount.$userId': count,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating conversation unread count: $e');
      rethrow;
    }
  }

  /// Create distress alert
  Future<void> createDistressAlert({
    required String childId,
    required String description,
    required int severity,
  }) async {
    try {
      final alertData = {
        'childId': childId,
        'description': description,
        'severity': severity,
        'timestamp': FieldValue.serverTimestamp(),
        'resolved': false,
      };
      
      // Add alert to Firestore
      final alertRef = await _alertsCollection.add(alertData);
      
      // Get child data
      final childDoc = await _childrenCollection.doc(childId).get();
      final childData = childDoc.data() as Map<String, dynamic>;
      final therapistId = childData['therapistId'] as String?;
      final childName = childData['name'] as String;
      
      // Create notification for therapist
      if (therapistId != null) {
        await _notificationsCollection.add({
          'userId': therapistId,
          'type': 'distressAlert',
          'title': 'Distress Alert',
          'message': '$childName is experiencing distress',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'data': {
            'alertId': alertRef.id,
            'childId': childId,
            'severity': severity,
          },
        });
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating distress alert: $e');
      rethrow;
    }
  }

  /// Complete mission
  Future<void> completeMission(String missionId, String childId) async {
    try {
      // Update mission status
      await _missionsCollection.doc(missionId).update({
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      // Get child data
      final childDoc = await _childrenCollection.doc(childId).get();
      final childData = childDoc.data() as Map<String, dynamic>;
      final therapistId = childData['therapistId'] as String?;
      final childName = childData['name'] as String;
      
      // Get mission data
      final missionDoc = await _missionsCollection.doc(missionId).get();
      final missionData = missionDoc.data() as Map<String, dynamic>;
      final missionTitle = missionData['title'] as String;
      
      // Create notification for therapist
      if (therapistId != null) {
        await _notificationsCollection.add({
          'userId': therapistId,
          'type': 'missionCompleted',
          'title': 'Mission Completed',
          'message': '$childName completed the mission: $missionTitle',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'data': {
            'missionId': missionId,
            'childId': childId,
          },
        });
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing mission: $e');
      rethrow;
    }
  }

  /// Record emotion
  Future<void> recordEmotion({
    required String childId,
    required String emotion,
    required int intensity,
    String? note,
  }) async {
    try {
      final emotionData = {
        'childId': childId,
        'emotion': emotion,
        'intensity': intensity,
        'note': note,
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      // Add emotion to Firestore
      final emotionRef = await _emotionsCollection.add(emotionData);
      
      // Get child data
      final childDoc = await _childrenCollection.doc(childId).get();
      final childData = childDoc.data() as Map<String, dynamic>;
      final therapistId = childData['therapistId'] as String?;
      final childName = childData['name'] as String;
      
      // Create notification for therapist if intensity is high
      if (therapistId != null && intensity >= 7) {
        await _notificationsCollection.add({
          'userId': therapistId,
          'type': 'emotionUpdate',
          'title': 'High Intensity Emotion',
          'message': '$childName is feeling strong $emotion (intensity: $intensity)',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'data': {
            'emotionId': emotionRef.id,
            'childId': childId,
            'emotion': emotion,
            'intensity': intensity,
          },
        });
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error recording emotion: $e');
      rethrow;
    }
  }

  /// Schedule session
  Future<void> scheduleSession({
    required String therapistId,
    required String childId,
    required DateTime dateTime,
    String? notes,
  }) async {
    try {
      final sessionData = {
        'therapistId': therapistId,
        'childId': childId,
        'dateTime': Timestamp.fromDate(dateTime),
        'notes': notes,
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Add session to Firestore
      final sessionRef = await _sessionsCollection.add(sessionData);
      
      // Get child data
      final childDoc = await _childrenCollection.doc(childId).get();
      final childData = childDoc.data() as Map<String, dynamic>;
      final childName = childData['name'] as String;
      final parentId = childData['parentId'] as String?;
      
      // Create notification for parent
      if (parentId != null) {
        await _notificationsCollection.add({
          'userId': parentId,
          'type': 'sessionReminder',
          'title': 'Session Scheduled',
          'message': 'A session has been scheduled for $childName',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'data': {
            'sessionId': sessionRef.id,
            'childId': childId,
            'dateTime': dateTime.toIso8601String(),
          },
        });
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error scheduling session: $e');
      rethrow;
    }
  }

  /// Get a single child by ID
  Future<Child?> getChild(String childId) async {
    try {
      final docSnapshot = await _childrenCollection.doc(childId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return Child.fromMap(docSnapshot.id, data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting child: $e');
      rethrow;
    }
  }
} 