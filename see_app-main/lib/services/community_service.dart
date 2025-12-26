import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:see_app/models/community_post.dart';
import 'package:see_app/models/mission.dart';
import 'package:see_app/models/mission_category.dart';

/// Service for managing community posts (Parent Feed)
class CommunityService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<CommunityPost> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Collection references
  CollectionReference get _communityCollection => 
    _firestore.collection('community_posts');
  
  CollectionReference get _userReactionsCollection =>
    _firestore.collection('user_post_reactions');
  
  /// Initialize the service (removed synchronous fetchPosts call)
  CommunityService();
  
  /// Fetch community posts from Firebase
  Future<void> fetchPosts() async {
    _isLoading = true;
    _error = null;
    // Removed notifyListeners() here to prevent setState during build on initial load
    // notifyListeners(); 
    
    try {
      // Only show approved posts that aren't flagged
      final snapshot = await _communityCollection
        .where('isApproved', isEqualTo: true)
        .where('isFlagged', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to most recent 50 posts
        .get();
      
      List<CommunityPost> loadedPosts = snapshot.docs
        .map((doc) => CommunityPost.fromFirestore(doc))
        .toList();
      
      // If we got posts, use them; otherwise provide sample data
      if (loadedPosts.isNotEmpty) {
        _posts = loadedPosts;
      } else {
        // If no posts found in Firebase, use sample data as fallback
        _posts = _getSamplePosts();
      }
      
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading community posts: ${e.toString()}');
      // On error, provide fallback sample data so users see something
      _posts = _getSamplePosts();
      _error = null; // Don't show error if we have fallback data
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Get sample posts to use as fallback when Firebase fails
  List<CommunityPost> _getSamplePosts() {
    return [
      CommunityPost(
        id: 'sample1',
        content: "My daughter smiled big when we did the mirroring expressions activity! She's getting so good at recognizing emotions.",
        missionId: 'mimicry-1',
        missionTitle: "Mirror Emotions",
        missionCategory: "mimicry",
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        reactions: {'❤️': 5, '👍': 3},
        isApproved: true,
        isFlagged: false,
      ),
      CommunityPost(
        id: 'sample2',
        content: "We tried the storytelling mission where we had to take turns adding to the story with different emotions. My son got so creative with his 'sad' part that it made me tear up!",
        missionId: 'storytelling-1',
        missionTitle: "Emotion Stories",
        missionCategory: "storytelling",
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        reactions: {'👏': 7, '🙌': 2},
        isApproved: true,
        isFlagged: false,
      ),
      CommunityPost(
        id: 'sample3',
        content: "The physical bonding mission with deep breathing was amazing! My daughter has been using it when she feels overwhelmed at school.",
        missionId: 'bonding-2',
        missionTitle: "Breathe Together",
        missionCategory: "bonding",
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        reactions: {'❤️': 8, '👍': 4, '😊': 3},
        isApproved: true,
        isFlagged: false,
      ),
    ];
  }
  
  /// Create a new community post after completing a mission
  Future<bool> createPost({
    required String content,
    Mission? mission,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Make sure user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _error = 'You must be logged in to post';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Check for inappropriate content
      if (_containsInappropriateContent(content)) {
        _error = 'Your post contains inappropriate content';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Create post data
      final postId = _communityCollection.doc().id;
      final now = DateTime.now();
      final Map<String, dynamic> postData = {
        'id': postId,
        'content': content,
        'userId': currentUser.uid, // For admin purposes only
        'createdAt': Timestamp.fromDate(now),
        'reactions': <String, int>{},
        'isApproved': true, // Auto-approve for now
        'isFlagged': false,
      };
      
      // Add mission-related fields if a mission was provided
      if (mission != null) {
        postData['missionId'] = mission.id;
        postData['missionTitle'] = mission.title;
        postData['missionCategory'] = _getCategoryString(mission.category);
      } else {
        // If no mission, set to general category
        postData['missionCategory'] = 'general';
      }
      
      // Save to Firestore
      await _communityCollection.doc(postId).set(postData);
      
      // Create and add the new post to our local list
      final newPost = CommunityPost(
        id: postId,
        content: content,
        missionId: mission?.id,
        missionTitle: mission?.title,
        missionCategory: mission != null ? _getCategoryString(mission.category) : 'general',
        createdAt: now,
        reactions: {},
        isApproved: true,
        isFlagged: false,
      );
      
      _posts.insert(0, newPost); // Add to beginning of list
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = 'Failed to create post: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Add a reaction to a post
  Future<bool> addReaction(String postId, String emoji) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;
      
      // Find the post
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex == -1) return false;
      
      // Create a reaction document ID
      final reactionId = '${currentUser.uid}_${postId}_$emoji';
      
      // Check if user already reacted with this emoji
      final reactionDoc = await _userReactionsCollection.doc(reactionId).get();
      
      if (reactionDoc.exists) {
        // User already reacted with this emoji, so we'll remove it
        await _userReactionsCollection.doc(reactionId).delete();
        
        // Update the post in Firestore
        final updatedPost = _posts[postIndex].removeReaction(emoji);
        await _communityCollection.doc(postId).update({
          'reactions': updatedPost.reactions,
        });
        
        // Update the local post
        _posts[postIndex] = updatedPost;
        notifyListeners();
      } else {
        // User hasn't reacted with this emoji yet, so add it
        await _userReactionsCollection.doc(reactionId).set({
          'userId': currentUser.uid,
          'postId': postId,
          'emoji': emoji,
          'timestamp': Timestamp.now(),
        });
        
        // Update the post in Firestore
        final updatedPost = _posts[postIndex].addReaction(emoji);
        await _communityCollection.doc(postId).update({
          'reactions': updatedPost.reactions,
        });
        
        // Update the local post
        _posts[postIndex] = updatedPost;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = 'Failed to add reaction: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  /// Flag a post as inappropriate
  Future<bool> flagPost(String postId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;
      
      // Find the post
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex == -1) return false;
      
      // Update the post in Firestore
      await _communityCollection.doc(postId).update({
        'isFlagged': true,
      });
      
      // Update the local post and remove it from the list
      _posts.removeAt(postIndex);
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = 'Failed to flag post: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  /// Get posts filtered by mission category
  List<CommunityPost> getPostsByCategory(String category) {
    return _posts.where((post) => post.missionCategory == category).toList();
  }
  
  /// Get posts related to a specific mission
  List<CommunityPost> getPostsByMission(String missionId) {
    return _posts.where((post) => post.missionId == missionId).toList();
  }
  
  /// Check if content contains inappropriate words (simple moderation)
  bool _containsInappropriateContent(String content) {
    final contentLower = content.toLowerCase();
    final inappropriateWords = [
      // Basic list of inappropriate words to filter
      // In a real app, this would be more comprehensive and possibly use a moderation API
      'badword1', 'badword2', 'badword3'
    ];
    
    return inappropriateWords.any((word) => contentLower.contains(word));
  }
  
  /// Convert MissionCategory enum to string for storage
  String _getCategoryString(MissionCategory category) {
    switch (category) {
      case MissionCategory.mimicry:
        return 'mimicry';
      case MissionCategory.storytelling:
        return 'storytelling';
      case MissionCategory.labeling:
        return 'labeling';
      case MissionCategory.bonding:
        return 'bonding';
      case MissionCategory.routines:
        return 'routines';
      default:
        return 'other';
    }
  }
  
  /// Admin function: Approve a flagged post
  Future<bool> approvePost(String postId) async {
    try {
      // This would typically check for admin permissions
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;
      
      // Update the post in Firestore
      await _communityCollection.doc(postId).update({
        'isApproved': true,
        'isFlagged': false,
      });
      
      // Refresh posts to include the approved post
      await fetchPosts();
      
      return true;
    } catch (e) {
      _error = 'Failed to approve post: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  /// Admin function: Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      // This would typically check for admin permissions
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;
      
      // Delete the post from Firestore
      await _communityCollection.doc(postId).delete();
      
      // Remove the post from the local list
      _posts.removeWhere((post) => post.id == postId);
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = 'Failed to delete post: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}