import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:see_app/models/emotion_data.dart';

/// Service responsible for fetching and managing emotion data from Firestore
class EmotionService extends ChangeNotifier {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  CollectionReference get _emotionsCollection => _firestore.collection('emotions');
  CollectionReference get _alertsCollection => _firestore.collection('alerts');
  CollectionReference get _suggestionsCollection => _firestore.collection('suggestions');
  CollectionReference get _childrenCollection => _firestore.collection('children');
  
  // Current user helper
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;
  
  // Fetch emotion data for a specific child
  Future<List<EmotionData>> getEmotionData(String childId) async {
    try {
      // Query emotions for this child, ordered by timestamp
      final querySnapshot = await _emotionsCollection
          .where('childId', isEqualTo: childId)
          .orderBy('timestamp', descending: false)
          .get();
      
      // Convert query snapshot to emotion data objects
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EmotionData.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching emotion data: $e');
      return [];
    }
  }
  
  // Stream of emotions for a specific child (for real-time updates)
  Stream<List<EmotionData>> streamEmotionData(String childId) {
    return _emotionsCollection
        .where('childId', isEqualTo: childId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return EmotionData.fromJson({
              'id': doc.id,
              ...data,
            });
          }).toList();
        });
  }
  
  // Fetch recent emotion data (last 7 days) for a specific child
  Future<List<EmotionData>> getRecentEmotionData(String childId) async {
    try {
      // Calculate date 7 days ago
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final timestamp = Timestamp.fromDate(sevenDaysAgo);
      
      // Query emotions for this child from the last 7 days
      final querySnapshot = await _emotionsCollection
          .where('childId', isEqualTo: childId)
          .where('timestamp', isGreaterThanOrEqualTo: timestamp)
          .orderBy('timestamp', descending: false)
          .get();
      
      // Convert query snapshot to emotion data objects
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EmotionData.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching recent emotion data: $e');
      return [];
    }
  }
  
  // Fetch active distress alerts for a specific child
  Future<List<DistressAlert>> getDistressAlerts(String childId) async {
    try {
      // Query active alerts for this child, ordered by timestamp (most recent first)
      final querySnapshot = await _alertsCollection
          .where('childId', isEqualTo: childId)
          .where('isActive', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();
      
      // Convert query snapshot to alert objects
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return DistressAlert.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching distress alerts: $e');
      return [];
    }
  }
  
  // Stream of active alerts for a specific child (for real-time updates)
  Stream<List<DistressAlert>> streamDistressAlerts(String childId) {
    return _alertsCollection
        .where('childId', isEqualTo: childId)
        .where('isActive', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return DistressAlert.fromJson({
              'id': doc.id,
              ...data,
            });
          }).toList();
        });
  }
  
  // Fetch calming suggestions for a specific child
  Future<List<CalmingSuggestion>> getCalmingSuggestions(String childId) async {
    try {
      // Query suggestions for this child
      final querySnapshot = await _suggestionsCollection
          .where('childId', isEqualTo: childId)
          .get();
      
      // If no child-specific suggestions, get general suggestions
      if (querySnapshot.docs.isEmpty) {
        final generalSnapshot = await _suggestionsCollection
            .where('isGeneral', isEqualTo: true)
            .get();
        
        return generalSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return CalmingSuggestion.fromJson({
            'id': doc.id,
            ...data,
          });
        }).toList();
      }
      
      // Convert child-specific query snapshot to suggestion objects
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CalmingSuggestion.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching calming suggestions: $e');
      return _getFallbackSuggestions(childId);
    }
  }
  
  // Stream of calming suggestions for a specific child (for real-time updates)
  Stream<List<CalmingSuggestion>> streamCalmingSuggestions(String childId) {
    return _suggestionsCollection
        .where('childId', isEqualTo: childId)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) {
            // If no child-specific suggestions, fetch general suggestions once for this snapshot
            final generalSnapshot = await _suggestionsCollection
                .where('isGeneral', isEqualTo: true)
                .get();
            
            return generalSnapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return CalmingSuggestion.fromJson({
                'id': doc.id,
                ...data,
              });
            }).toList();
          }
          // Convert child-specific query snapshot to suggestion objects
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return CalmingSuggestion.fromJson({
              'id': doc.id,
              ...data,
            });
          }).toList();
        });
  }
  
  // Record a new emotion manually
  Future<bool> recordEmotionManually(EmotionData data) async {
    try {
      // Create a map from the emotion data
      final emotionMap = data.toJson();
      emotionMap.remove('id'); // Remove id as Firestore will generate one
      
      // Add timestamp if not present
      if (!emotionMap.containsKey('timestamp')) {
        emotionMap['timestamp'] = Timestamp.now();
      }
      
      // Add to Firestore
      final docRef = await _emotionsCollection.add(emotionMap);
      
      // Check if high intensity and create an alert if needed
      if (data.intensity > 0.7 && 
          (data.type == EmotionType.anger || 
           data.type == EmotionType.fear || 
           data.type == EmotionType.sadness)) {
        await _createDistressAlert(
          data.childId, 
          data.type, 
          data.intensity,
          data.context,
        );
      }
      
      return docRef.id.isNotEmpty;
    } catch (e) {
      debugPrint('Error recording emotion: $e');
      return false;
    }
  }
  
  // Create a distress alert based on emotion data
  Future<void> _createDistressAlert(
    String childId, 
    EmotionType emotion, 
    double intensity,
    String? context,
  ) async {
    try {
      // Determine severity based on intensity
      AlertSeverity severity;
      if (intensity > 0.9) {
        severity = AlertSeverity.high;
      } else if (intensity > 0.8) {
        severity = AlertSeverity.medium;
      } else {
        severity = AlertSeverity.low;
      }
      
      // Create alert data
      final alertData = {
        'childId': childId,
        'triggerEmotion': emotion.toString().split('.').last,
        'intensity': intensity,
        'timestamp': Timestamp.now(),
        'severity': severity.toString().split('.').last,
        'description': _getAlertDescription(emotion, context),
        'isActive': true,
      };
      
      // Add to Firestore
      await _alertsCollection.add(alertData);
    } catch (e) {
      debugPrint('Error creating distress alert: $e');
    }
  }
  
  // Resolve an alert (mark as inactive)
  Future<bool> resolveAlert(String alertId) async {
    try {
      await _alertsCollection.doc(alertId).update({
        'isActive': false,
        'resolvedTimestamp': Timestamp.now(),
        'resolvedBy': _currentUserId,
      });
      return true;
    } catch (e) {
      debugPrint('Error resolving alert: $e');
      return false;
    }
  }
  
  // Save a suggestion to favorites
  Future<bool> saveSuggestionToFavorites(String suggestionId) async {
    try {
      await _suggestionsCollection.doc(suggestionId).update({
        'isFavorite': true,
        'favoritedBy': FieldValue.arrayUnion([_currentUserId]),
      });
      return true;
    } catch (e) {
      debugPrint('Error saving suggestion to favorites: $e');
      return false;
    }
  }
  
  // Remove a suggestion from favorites
  Future<bool> removeSuggestionFromFavorites(String suggestionId) async {
    try {
      await _suggestionsCollection.doc(suggestionId).update({
        'favoritedBy': FieldValue.arrayRemove([_currentUserId]),
      });
      return true;
    } catch (e) {
      debugPrint('Error removing suggestion from favorites: $e');
      return false;
    }
  }
  
  // Create a method to populate the database with initial data
  Future<void> createInitialData() async {
    await _createSampleSuggestions();
  }
  
  // Create sample suggestions in Firestore
  Future<void> _createSampleSuggestions() async {
    try {
      // Check if suggestions already exist
      final snapshot = await _suggestionsCollection.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return; // Data already exists
      }
      
      // Create general suggestions that work for any child
      final suggestions = [
        {
          'title': 'Deep Breathing Bubbles',
          'description': 'Blow imaginary bubbles slowly with deep breaths. Inhale through your nose for 4 counts, hold for 4, and exhale for 6.',
          'targetEmotions': [
            EmotionType.anger.toString().split('.').last, 
            EmotionType.fear.toString().split('.').last
          ],
          'imageUrl': 'assets/images/suggestions/breathing.png',
          'category': SuggestionCategory.physical.toString().split('.').last,
          'estimatedTimeMinutes': 5,
          'isGeneral': true,
        },
        {
          'title': 'Sensory Water Play',
          'description': 'Fill a small container with water and provide cups, funnels, and other containers for pouring and exploring.',
          'targetEmotions': [
            EmotionType.anger.toString().split('.').last, 
            EmotionType.sadness.toString().split('.').last
          ],
          'imageUrl': 'assets/images/suggestions/water_play.png',
          'category': SuggestionCategory.sensory.toString().split('.').last,
          'estimatedTimeMinutes': 15,
          'isGeneral': true,
        },
        {
          'title': 'Emotion Drawing',
          'description': 'Draw how you feel right now using colors and shapes that match your emotions.',
          'targetEmotions': [
            EmotionType.sadness.toString().split('.').last, 
            EmotionType.fear.toString().split('.').last
          ],
          'imageUrl': 'assets/images/suggestions/drawing.png',
          'category': SuggestionCategory.creative.toString().split('.').last,
          'estimatedTimeMinutes': 10,
          'isGeneral': true,
        },
        {
          'title': 'Yoga Animal Poses',
          'description': 'Try imitating different animals with simple yoga poses: be a snake, a dog, a butterfly and a frog.',
          'targetEmotions': [
            EmotionType.anger.toString().split('.').last, 
            EmotionType.fear.toString().split('.').last
          ],
          'imageUrl': 'assets/images/suggestions/yoga.png',
          'category': SuggestionCategory.physical.toString().split('.').last,
          'estimatedTimeMinutes': 10,
          'isGeneral': true,
        },
        {
          'title': 'Calm Jar',
          'description': 'Shake a jar with glitter and water, then watch as the glitter slowly settles - just like your feelings can settle too.',
          'targetEmotions': [
            EmotionType.anger.toString().split('.').last, 
            EmotionType.fear.toString().split('.').last, 
            EmotionType.sadness.toString().split('.').last
          ],
          'imageUrl': 'assets/images/suggestions/calm_jar.png',
          'category': SuggestionCategory.sensory.toString().split('.').last,
          'estimatedTimeMinutes': 5,
          'isGeneral': true,
        },
      ];
      
      // Add each suggestion to Firestore
      for (final suggestion in suggestions) {
        await _suggestionsCollection.add(suggestion);
      }
    } catch (e) {
      debugPrint('Error creating sample suggestions: $e');
    }
  }
  
  // Helper method to get alert description
  String _getAlertDescription(EmotionType emotion, String? context) {
    final contextStr = context != null ? ' during $context' : '';
    
    switch (emotion) {
      case EmotionType.anger:
        return 'Showing signs of significant frustration$contextStr';
      case EmotionType.fear:
        return 'Exhibiting anxiety$contextStr';
      case EmotionType.sadness:
        return 'Appeared withdrawn and disengaged$contextStr';
      default:
        return 'Emotional state requires attention$contextStr';
    }
  }
  
  // Fallback suggestions in case Firestore is unavailable
  List<CalmingSuggestion> _getFallbackSuggestions(String childId) {
    return [
      CalmingSuggestion(
        id: 'local_1',
        childId: childId,
        title: 'Deep Breathing',
        description: 'Take slow, deep breaths. Inhale through your nose for 4 counts, hold for 4, and exhale for 6.',
        targetEmotions: [EmotionType.anger, EmotionType.fear],
        imageUrl: null,
        category: SuggestionCategory.physical,
        estimatedTime: const Duration(minutes: 5),
      ),
      CalmingSuggestion(
        id: 'local_2',
        childId: childId,
        title: 'Progressive Relaxation',
        description: 'Tense and then relax each muscle group in your body, starting from your toes and working up to your head.',
        targetEmotions: [EmotionType.anger, EmotionType.fear],
        imageUrl: null,
        category: SuggestionCategory.physical,
        estimatedTime: const Duration(minutes: 8),
      ),
    ];
  }
}