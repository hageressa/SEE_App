import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:see_app/models/connection_request.dart';
import 'package:see_app/models/user.dart';

/// Service for managing connections between parents and therapists
class ConnectionService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  
  // References to Firestore collections
  final CollectionReference _connectionsCollection;
  final CollectionReference _notificationsCollection;
  
  // Connection statuses
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusDeclined = 'declined';
  
  ConnectionService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _connectionsCollection = (firestore ?? FirebaseFirestore.instance).collection('connections'),
       _notificationsCollection = (firestore ?? FirebaseFirestore.instance).collection('notifications');
  
  /// Send a connection request from parent to therapist
  Future<String> sendConnectionRequest({
    required String parentId,
    required String therapistId,
    required String childId,
    String? message,
  }) async {
    try {
      // Create a new connection document
      final connectionDoc = _connectionsCollection.doc();
      
      // Connection data
      final connectionData = {
        'parentId': parentId,
        'therapistId': therapistId,
        'childId': childId,
        'status': statusPending,
        'message': message ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Save connection to Firestore
      await connectionDoc.set(connectionData);

      // Get parent and child data for notification
      final parentDoc = await _firestore.collection('users').doc(parentId).get();
      final childDoc = await _firestore.collection('children').doc(childId).get();
      final parentData = parentDoc.data() as Map<String, dynamic>;
      final childData = childDoc.data() as Map<String, dynamic>;
      final parentName = parentData['displayName'] as String? ?? 'A parent';
      final childName = childData['name'] as String;

      // Create notification for therapist
      await _notificationsCollection.add({
        'userId': therapistId,
        'type': 'connectionRequest',
        'title': 'New Connection Request',
        'message': '$parentName wants to connect with you for their child $childName',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'data': {
          'requestId': connectionDoc.id,
          'parentId': parentId,
          'childId': childId,
        },
      });
      
      return connectionDoc.id;
    } catch (e) {
      debugPrint('Error sending connection request: $e');
      rethrow;
    }
  }
  
  /// Accept a connection request (by therapist)
  Future<void> acceptConnectionRequest(String requestId) async {
    try {
      // Get the request data
      final requestDoc = await _connectionsCollection.doc(requestId).get();
      final requestData = requestDoc.data() as Map<String, dynamic>;
      final parentId = requestData['parentId'] as String;
      final childId = requestData['childId'] as String;
      final therapistId = requestData['therapistId'] as String;

      // Update connection status
      await _connectionsCollection.doc(requestId).update({
        'status': statusAccepted,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get therapist data for notification
      final therapistDoc = await _firestore.collection('users').doc(therapistId).get();
      final therapistData = therapistDoc.data() as Map<String, dynamic>;
      final therapistName = therapistData['displayName'] as String? ?? 'The therapist';

      // Create notification for parent
      await _notificationsCollection.add({
        'userId': parentId,
        'type': 'connectionAccepted',
        'title': 'Connection Request Accepted',
        'message': '$therapistName has accepted your connection request',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'data': {
          'requestId': requestId,
          'therapistId': therapistId,
          'childId': childId,
        },
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error accepting connection request: $e');
      rethrow;
    }
  }
  
  /// Decline a connection request (by therapist)
  Future<void> declineConnectionRequest(String requestId) async {
    try {
      await _connectionsCollection.doc(requestId).update({
        'status': statusDeclined,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error declining connection request: $e');
      rethrow;
    }
  }
  
  /// Get connection requests for a therapist
  Future<List<Map<String, dynamic>>> getConnectionRequestsForTherapist(String therapistId) async {
    try {
      final querySnapshot = await _connectionsCollection
          .where('therapistId', isEqualTo: therapistId)
          .where('status', isEqualTo: statusPending)
          .orderBy('createdAt', descending: true)
          .get();
      
      return _processConnectionRequests(querySnapshot);
    } catch (e) {
      debugPrint('Error getting connection requests for therapist: $e');
      rethrow;
    }
  }
  
  /// Get connection requests for a parent
  Future<List<Map<String, dynamic>>> getConnectionRequestsForParent(String parentId) async {
    try {
      final querySnapshot = await _connectionsCollection
          .where('parentId', isEqualTo: parentId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return _processConnectionRequests(querySnapshot);
    } catch (e) {
      debugPrint('Error getting connection requests for parent: $e');
      rethrow;
    }
  }
  
  /// Get active connections for a therapist
  Future<List<Map<String, dynamic>>> getActiveConnectionsForTherapist(String therapistId) async {
    try {
      final querySnapshot = await _connectionsCollection
          .where('therapistId', isEqualTo: therapistId)
          .where('status', isEqualTo: statusAccepted)
          .orderBy('acceptedAt', descending: true)
          .get();
      
      return _processConnectionRequests(querySnapshot);
    } catch (e) {
      debugPrint('Error getting active connections for therapist: $e');
      rethrow;
    }
  }
  
  /// Get active connections for a parent
  Future<List<Map<String, dynamic>>> getActiveConnectionsForParent(String parentId) async {
    try {
      final querySnapshot = await _connectionsCollection
          .where('parentId', isEqualTo: parentId)
          .where('status', isEqualTo: statusAccepted)
          .orderBy('acceptedAt', descending: true)
          .get();
      
      return _processConnectionRequests(querySnapshot);
    } catch (e) {
      debugPrint('Error getting active connections for parent: $e');
      rethrow;
    }
  }
  
  /// Check if parent and therapist are connected for a specific child
  Future<bool> isConnected({
    required String parentId,
    required String therapistId,
    required String childId,
  }) async {
    try {
      final querySnapshot = await _connectionsCollection
          .where('parentId', isEqualTo: parentId)
          .where('therapistId', isEqualTo: therapistId)
          .where('childId', isEqualTo: childId)
          .where('status', isEqualTo: statusAccepted)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking connection status: $e');
      rethrow;
    }
  }
  
  /// Process connection request documents
  List<Map<String, dynamic>> _processConnectionRequests(QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Convert Firestore timestamps to DateTime
      final Map<String, dynamic> result = {
        'id': doc.id,
        ...data,
      };
      
      // Process timestamps
      for (final key in ['createdAt', 'updatedAt', 'acceptedAt', 'declinedAt']) {
        if (data[key] != null) {
          result[key] = (data[key] as Timestamp).toDate();
        }
      }
      
      return result;
    }).toList();
  }
  
  /// Subscribe to connection requests for a therapist
  Stream<List<Map<String, dynamic>>> streamConnectionRequestsForTherapist(String therapistId) {
    return _connectionsCollection
        .where('therapistId', isEqualTo: therapistId)
        .where('status', isEqualTo: statusPending)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => _processConnectionRequests(snapshot));
  }
  
  /// Subscribe to connection requests for a parent
  Stream<List<Map<String, dynamic>>> streamConnectionRequestsForParent(String parentId) {
    return _connectionsCollection
        .where('parentId', isEqualTo: parentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => _processConnectionRequests(snapshot));
  }

  /// Get a stream of connection requests for a specific therapist.
  Stream<List<ConnectionRequest>> getConnectionRequests(String therapistId) {
    return _connectionsCollection
        .where('therapistId', isEqualTo: therapistId)
        .where('status', isEqualTo: statusPending)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ConnectionRequest.fromFirestore(doc);
          }).toList();
        });
  }

  /// Get connection status between parent and therapist
  Future<String?> getConnectionStatus({
    required String parentId,
    required String therapistId,
  }) async {
    try {
      final querySnapshot = await _connectionsCollection
        .where('parentId', isEqualTo: parentId)
        .where('therapistId', isEqualTo: therapistId)
        .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      final connectionData = querySnapshot.docs.first.data() as Map<String, dynamic>;
      return connectionData['status'] as String;
    } catch (e) {
      debugPrint('Error getting connection status: $e');
      return null;
    }
  }
} 