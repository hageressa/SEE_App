import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:see_app/models/difficulty_level.dart';
import 'package:see_app/models/emotion_data.dart';
import 'package:see_app/models/mission_category.dart';
import 'package:see_app/models/mission_badge.dart';

/// Connect & Reflect Mission model
/// 
/// Represents an activity parents can do with their children
/// to improve emotional intelligence and bonding
class Mission {
  final String id;
  final String title;
  final String description;
  final MissionCategory category;
  final String evidenceSource;
  final int difficulty; // 1-3 scale (legacy field)
  final DifficultyLevel difficultyLevel; // New enum-based difficulty
  final List<EmotionType> targetEmotions; // Emotions this mission targets
  final DateTime dueDate; // When the mission is due
  final int rewardPoints; // Points awarded for completion
  final String assignedTo; // User ID this mission is assigned to
  final MissionBadge? badge; // Badge earned for completing this mission
  bool isCompleted;
  DateTime? completedAt; // Renamed from completedAt for consistency with UI
  DateTime? completedDate; // Exactly same as completedAt, just alternate name
  String? reflection; // Optional parent reflection/journal entry
  double? progress; // Progress towards completion (0.0 to 1.0)
  
  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.evidenceSource,
    required this.difficulty,
    this.difficultyLevel = DifficultyLevel.medium,
    this.targetEmotions = const [],
    required this.dueDate,
    this.rewardPoints = 10,
    required this.assignedTo,
    this.badge,
    this.isCompleted = false,
    this.completedAt,
    this.reflection,
    this.progress,
  }) : completedDate = completedAt;

  /// Create a Mission from Firestore data
  factory Mission.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse target emotions from string list
    List<EmotionType> targetEmotions = [];
    if (data['targetEmotions'] != null) {
      final emotionList = List<String>.from(data['targetEmotions'] ?? []);
      targetEmotions = emotionList.map((e) => _parseEmotionType(e)).toList();
    }
    
    // Convert difficulty level from string or use legacy difficulty field
    DifficultyLevel difficultyLevel;
    if (data['difficultyLevel'] != null) {
      final dlString = data['difficultyLevel'].toString();
      difficultyLevel = DifficultyLevel.values.firstWhere(
        (e) => e.toString().split('.').last == dlString,
        orElse: () => DifficultyLevel.medium
      );
    } else {
      // Legacy conversion
      final legacyDifficulty = data['difficulty'] ?? 2;
      difficultyLevel = legacyDifficulty == 1 
        ? DifficultyLevel.easy 
        : (legacyDifficulty == 3 ? DifficultyLevel.hard : DifficultyLevel.medium);
    }
    
    final DateTime? completedAtDate = (data['completedAt'] as Timestamp?)?.toDate();
    
    return Mission(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: _parseMissionCategory(data['category']),
      evidenceSource: data['evidenceSource'] ?? '',
      difficulty: data['difficulty'] ?? 1,
      difficultyLevel: difficultyLevel,
      targetEmotions: targetEmotions,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(Duration(days: 7)),
      rewardPoints: data['rewardPoints'] ?? 10,
      assignedTo: data['assignedTo'] ?? '',
      badge: data['badge'] != null ? MissionBadge.fromFirestore(data['badge']) : null,
      isCompleted: data['isCompleted'] ?? false,
      completedAt: completedAtDate,
      reflection: data['reflection'],
      progress: data['progress'] as double?,
    );
  }

  /// Create a Mission from JSON data
  factory Mission.fromJson(Map<String, dynamic> json) {
    // Parse target emotions
    List<EmotionType> targetEmotions = [];
    if (json['targetEmotions'] != null) {
      final emotionList = List<String>.from(json['targetEmotions'] ?? []);
      targetEmotions = emotionList.map((e) => _parseEmotionType(e)).toList();
    }
    
    // Parse difficulty level
    DifficultyLevel difficultyLevel;
    if (json['difficultyLevel'] != null) {
      final dlString = json['difficultyLevel'].toString();
      difficultyLevel = DifficultyLevel.values.firstWhere(
        (e) => e.toString().split('.').last == dlString,
        orElse: () => DifficultyLevel.medium
      );
    } else {
      // Legacy conversion
      final legacyDifficulty = json['difficulty'] ?? 2;
      difficultyLevel = legacyDifficulty == 1 
        ? DifficultyLevel.easy 
        : (legacyDifficulty == 3 ? DifficultyLevel.hard : DifficultyLevel.medium);
    }
    
    final completedAtDate = json['completedAt'] != null 
        ? DateTime.parse(json['completedAt']) 
        : null;
        
    return Mission(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: _parseMissionCategory(json['category']),
      evidenceSource: json['evidenceSource'] ?? '',
      difficulty: json['difficulty'] ?? 1,
      difficultyLevel: difficultyLevel,
      targetEmotions: targetEmotions,
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate']) 
          : DateTime.now().add(Duration(days: 7)),
      rewardPoints: json['rewardPoints'] ?? 10,
      assignedTo: json['assignedTo'] ?? '',
      badge: json['badge'] != null ? MissionBadge.fromJson(json['badge']) : null,
      isCompleted: json['isCompleted'] ?? false,
      completedAt: completedAtDate,
      reflection: json['reflection'],
      progress: json['progress'] as double?,
    );
  }

  /// Convert Mission to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'evidenceSource': evidenceSource,
      'difficulty': difficulty,
      'difficultyLevel': difficultyLevel.toString().split('.').last,
      'targetEmotions': targetEmotions.map((e) => e.toString().split('.').last).toList(),
      'dueDate': Timestamp.fromDate(dueDate),
      'rewardPoints': rewardPoints,
      'assignedTo': assignedTo,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'reflection': reflection,
      'badge': badge?.toFirestore(),
      'progress': progress,
    };
  }

  /// Convert Mission to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'evidenceSource': evidenceSource,
      'difficulty': difficulty,
      'difficultyLevel': difficultyLevel.toString().split('.').last,
      'targetEmotions': targetEmotions.map((e) => e.toString().split('.').last).toList(),
      'dueDate': dueDate.toIso8601String(),
      'rewardPoints': rewardPoints,
      'assignedTo': assignedTo,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'reflection': reflection,
      'badge': badge?.toJson(),
      'progress': progress,
    };
  }

  /// Create a copy of this Mission with modified properties
  Mission copyWith({
    String? id,
    String? title,
    String? description,
    MissionCategory? category,
    String? evidenceSource,
    int? difficulty,
    DifficultyLevel? difficultyLevel,
    List<EmotionType>? targetEmotions,
    DateTime? dueDate,
    int? rewardPoints,
    String? assignedTo,
    MissionBadge? badge,
    bool? isCompleted,
    DateTime? completedAt,
    String? reflection,
    double? progress,
  }) {
    return Mission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      evidenceSource: evidenceSource ?? this.evidenceSource,
      difficulty: difficulty ?? this.difficulty,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      targetEmotions: targetEmotions ?? this.targetEmotions,
      dueDate: dueDate ?? this.dueDate,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      assignedTo: assignedTo ?? this.assignedTo,
      badge: badge ?? this.badge,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      reflection: reflection ?? this.reflection,
      progress: progress ?? this.progress,
    );
  }

  /// Mark this mission as completed
  void complete({String? reflection}) {
    isCompleted = true;
    completedAt = DateTime.now();
    this.reflection = reflection;
  }

  /// Parse MissionCategory from string
  static MissionCategory _parseMissionCategory(String? category) {
    switch (category) {
      case 'mimicry':
        return MissionCategory.mimicry;
      case 'storytelling':
        return MissionCategory.storytelling;
      case 'labeling':
        return MissionCategory.labeling;
      case 'bonding':
        return MissionCategory.bonding;
      case 'routines':
        return MissionCategory.routines;
      case 'mindfulness':
        return MissionCategory.mindfulness;
      case 'journaling':
        return MissionCategory.journaling;
      case 'creativity':
        return MissionCategory.creativity;
      case 'physical':
        return MissionCategory.physical;
      case 'social':
        return MissionCategory.social;
      default:
        return MissionCategory.mimicry; // Default to mimicry
    }
  }

  /// Get a human-readable category name
  String get categoryName {
    return category.name;
  }

  /// Get difficulty as a string of stars (e.g., "★★☆" for difficulty 2)
  String get difficultyStars {
    final level = difficultyLevel.value;
    final filled = '★' * level;
    final empty = '☆' * (3 - level);
    return filled + empty;
  }
  
  /// Parse EmotionType from string
  static EmotionType _parseEmotionType(String? emotion) {
    switch (emotion?.toLowerCase()) {
      case 'joy':
        return EmotionType.joy;
      case 'sadness':
        return EmotionType.sadness;
      case 'anger':
        return EmotionType.anger;
      case 'fear':
        return EmotionType.fear;
      case 'disgust':
        return EmotionType.disgust;
      case 'surprise':
        return EmotionType.surprise;
      case 'neutral':
        return EmotionType.neutral;
      default:
        return EmotionType.neutral; // Default
    }
  }
}

/// Represents a parent's streak of completed missions
class MissionStreak {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastCompletedDate;
  final List<String> completedMissionIds;

  MissionStreak({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCompletedDate,
    required this.completedMissionIds,
  });

  /// Create a MissionStreak from Firestore data
  factory MissionStreak.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MissionStreak(
      userId: doc.id,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastCompletedDate: (data['lastCompletedDate'] as Timestamp).toDate(),
      completedMissionIds: List<String>.from(data['completedMissionIds'] ?? []),
    );
  }

  /// Convert MissionStreak to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCompletedDate': Timestamp.fromDate(lastCompletedDate),
      'completedMissionIds': completedMissionIds,
    };
  }

  /// Create a copy of this MissionStreak with modified properties
  MissionStreak copyWith({
    String? userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletedDate,
    List<String>? completedMissionIds,
  }) {
    return MissionStreak(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      completedMissionIds: completedMissionIds ?? this.completedMissionIds,
    );
  }
}