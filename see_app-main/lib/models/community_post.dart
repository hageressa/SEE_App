import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Represents a post on the Community Wall where parents can share mission experiences anonymously
class CommunityPost {
  final String id;
  final String content;
  final String? missionId;
  final String? missionTitle;
  final String? missionCategory;
  final DateTime createdAt;
  final Map<String, int> reactions;
  final bool isApproved;
  final bool isFlagged;

  // Added for compatibility with session preparation dashboard
  String get title => missionTitle ?? 'Community Post';
  DateTime get timestamp => createdAt;

  CommunityPost({
    required this.id,
    required this.content,
    this.missionId,
    this.missionTitle,
    this.missionCategory,
    required this.createdAt,
    required this.reactions,
    this.isApproved = true,
    this.isFlagged = false,
  });

  /// Factory constructor to create a CommunityPost from a Firebase document
  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CommunityPost(
      id: doc.id,
      content: data['content'] ?? '',
      missionId: data['missionId'],
      missionTitle: data['missionTitle'],
      missionCategory: data['missionCategory'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reactions: Map<String, int>.from(data['reactions'] ?? {}),
      isApproved: data['isApproved'] ?? true,
      isFlagged: data['isFlagged'] ?? false,
    );
  }

  /// Convert this CommunityPost to a Map for Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      if (missionId != null) 'missionId': missionId,
      if (missionTitle != null) 'missionTitle': missionTitle,
      if (missionCategory != null) 'missionCategory': missionCategory,
      'createdAt': Timestamp.fromDate(createdAt),
      'reactions': reactions,
      'isApproved': isApproved,
      'isFlagged': isFlagged,
    };
  }

  /// Create a copy of this CommunityPost with the provided changes
  CommunityPost copyWith({
    String? id,
    String? content,
    String? missionId,
    String? missionTitle,
    String? missionCategory,
    DateTime? createdAt,
    Map<String, int>? reactions,
    bool? isApproved,
    bool? isFlagged,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      content: content ?? this.content,
      missionId: missionId ?? this.missionId,
      missionTitle: missionTitle ?? this.missionTitle,
      missionCategory: missionCategory ?? this.missionCategory,
      createdAt: createdAt ?? this.createdAt,
      reactions: reactions ?? this.reactions,
      isApproved: isApproved ?? this.isApproved,
      isFlagged: isFlagged ?? this.isFlagged,
    );
  }

  /// Add or update a reaction to this post
  CommunityPost addReaction(String emoji) {
    final updatedReactions = Map<String, int>.from(reactions);
    updatedReactions[emoji] = (updatedReactions[emoji] ?? 0) + 1;
    
    return copyWith(reactions: updatedReactions);
  }

  /// Remove a reaction from this post
  CommunityPost removeReaction(String emoji) {
    final updatedReactions = Map<String, int>.from(reactions);
    if (updatedReactions.containsKey(emoji) && updatedReactions[emoji]! > 0) {
      updatedReactions[emoji] = updatedReactions[emoji]! - 1;
      if (updatedReactions[emoji] == 0) {
        updatedReactions.remove(emoji);
      }
    }
    
    return copyWith(reactions: updatedReactions);
  }

  /// Flag this post for moderation
  CommunityPost flag() {
    return copyWith(isFlagged: true);
  }

  /// Get the color associated with the mission category
  Color getCategoryColor() {
    switch (missionCategory) {
      case 'mimicry':
        return Colors.orange;
      case 'storytelling':
        return Colors.blue;
      case 'labeling':
        return Colors.green;
      case 'bonding':
        return Colors.red;
      case 'routines':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Get the icon associated with the mission category
  IconData getCategoryIcon() {
    switch (missionCategory) {
      case 'mimicry':
        return Icons.face;
      case 'storytelling':
        return Icons.book;
      case 'labeling':
        return Icons.label;
      case 'bonding':
        return Icons.favorite;
      case 'routines':
        return Icons.calendar_today;
      default:
        return Icons.article;
    }
  }
  
  /// Get a formatted string of the time since this post was created
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} week${difference.inDays >= 14 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
  
  /// Get list of available reaction emojis
  static List<String> getAvailableReactions() {
    return ['❤️', '👍', '👏', '😊', '🥰', '🙌', '💯', '🔥'];
  }
}