import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:see_app/models/mission.dart';
import 'package:see_app/utils/theme.dart';

/// Types of achievement badges for Connect & Reflect Missions
enum BadgeType {
  streak,     // Streaks of consecutive days
  category,   // Completed missions in a specific category
  milestone,  // Number of total missions completed
  variety,    // Completed different types of missions
  reflection  // Added reflections to missions
}

/// Represents a mission achievement badge
class MissionBadge {
  final String id;
  final String name;
  final String description;
  final BadgeType type;
  final int level; // 1-3 (bronze, silver, gold)
  final bool isEarned;
  final DateTime? earnedAt;
  final String iconName;
  final Color color;
  
  MissionBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.level,
    this.isEarned = false,
    this.earnedAt,
    required this.iconName,
    required this.color,
  });

  /// Create a MissionBadge from Firestore data
  factory MissionBadge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MissionBadge(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: _parseBadgeType(data['type']),
      level: data['level'] ?? 1,
      isEarned: data['isEarned'] ?? false,
      earnedAt: (data['earnedAt'] as Timestamp?)?.toDate(),
      iconName: data['iconName'] ?? 'emoji_events',
      color: _parseColor(data['color']),
    );
  }

  /// Convert MissionBadge to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'level': level,
      'isEarned': isEarned,
      'earnedAt': earnedAt != null ? Timestamp.fromDate(earnedAt!) : null,
      'iconName': iconName,
      'color': color.value.toRadixString(16),
    };
  }

  /// Create a copy of this MissionBadge with modified properties
  MissionBadge copyWith({
    String? id,
    String? name,
    String? description,
    BadgeType? type,
    int? level,
    bool? isEarned,
    DateTime? earnedAt,
    String? iconName,
    Color? color,
  }) {
    return MissionBadge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      level: level ?? this.level,
      isEarned: isEarned ?? this.isEarned,
      earnedAt: earnedAt ?? this.earnedAt,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
    );
  }

  /// Mark badge as earned
  MissionBadge earn() {
    return copyWith(
      isEarned: true,
      earnedAt: DateTime.now(),
    );
  }

  /// Parse BadgeType from string
  static BadgeType _parseBadgeType(String? type) {
    switch (type) {
      case 'streak':
        return BadgeType.streak;
      case 'category':
        return BadgeType.category;
      case 'milestone':
        return BadgeType.milestone;
      case 'variety':
        return BadgeType.variety;
      case 'reflection':
        return BadgeType.reflection;
      default:
        return BadgeType.milestone;
    }
  }

  /// Parse Color from hex string
  static Color _parseColor(String? hexColor) {
    if (hexColor == null) return SeeAppTheme.primaryColor;
    try {
      final colorValue = int.parse(hexColor, radix: 16);
      return Color(colorValue);
    } catch (e) {
      return SeeAppTheme.primaryColor;
    }
  }

  /// Get medal icon based on level
  IconData get medalIcon {
    switch (level) {
      case 1:
        return Icons.workspace_premium; // Bronze
      case 2:
        return Icons.emoji_events; // Silver
      case 3:
        return Icons.military_tech; // Gold
      default:
        return Icons.emoji_events;
    }
  }

  /// Get badge-specific icon
  IconData get badgeIcon {
    // Try to use the iconName as an IconData if possible
    switch (iconName) {
      case 'emoji_events':
        return Icons.emoji_events;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'celebration':
        return Icons.celebration;
      case 'psychology':
        return Icons.psychology;
      case 'diversity_3':
        return Icons.diversity_3;
      case 'format_quote':
        return Icons.format_quote;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'favorite':
        return Icons.favorite;
      case 'face':
        return Icons.face;
      case 'book':
        return Icons.book;
      case 'label':
        return Icons.label;
      default:
        // Fallback to type-based icons
        switch (type) {
          case BadgeType.streak:
            return Icons.local_fire_department;
          case BadgeType.category:
            return Icons.category;
          case BadgeType.milestone:
            return Icons.emoji_events;
          case BadgeType.variety:
            return Icons.diversity_3;
          case BadgeType.reflection:
            return Icons.format_quote;
        }
    }
  }

  /// Get level name
  String get levelName {
    switch (level) {
      case 1:
        return 'Bronze';
      case 2:
        return 'Silver';
      case 3:
        return 'Gold';
      default:
        return '';
    }
  }

  /// Create a MissionBadge from JSON data
  factory MissionBadge.fromJson(Map<String, dynamic> json) {
    return MissionBadge(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: _parseBadgeType(json['type']),
      level: json['level'] ?? 1,
      isEarned: json['isEarned'] ?? false,
      earnedAt: json['earnedAt'] != null ? DateTime.parse(json['earnedAt']) : null,
      iconName: json['iconName'] ?? 'emoji_events',
      color: _parseColor(json['color']),
    );
  }

  /// Convert MissionBadge to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'level': level,
      'isEarned': isEarned,
      'earnedAt': earnedAt?.toIso8601String(),
      'iconName': iconName,
      'color': color.value.toRadixString(16),
    };
  }
}

/// Collection of predefined badges for Connect & Reflect Missions
class PredefinedBadges {
  // Streak badges
  static MissionBadge threeDay = MissionBadge(
    id: 'streak_3day',
    name: '3-Day Consistency',
    description: 'Completed missions 3 days in a row',
    type: BadgeType.streak,
    level: 1,
    iconName: 'local_fire_department',
    color: SeeAppTheme.joyColor,
  );
  
  static MissionBadge fiveDay = MissionBadge(
    id: 'streak_5day',
    name: '5-Day Consistency',
    description: 'Completed missions 5 days in a row',
    type: BadgeType.streak,
    level: 2,
    iconName: 'local_fire_department',
    color: SeeAppTheme.joyColor,
  );
  
  static MissionBadge sevenDay = MissionBadge(
    id: 'streak_7day',
    name: 'Week of Growth',
    description: 'Completed missions every day for a week',
    type: BadgeType.streak,
    level: 3,
    iconName: 'local_fire_department',
    color: SeeAppTheme.joyColor,
  );
  
  // Category badges
  static MissionBadge allCategories = MissionBadge(
    id: 'category_all',
    name: 'Emotion Explorer',
    description: 'Tried missions from all categories',
    type: BadgeType.variety,
    level: 2,
    iconName: 'diversity_3',
    color: SeeAppTheme.secondaryColor,
  );
  
  static MissionBadge mimicryMaster = MissionBadge(
    id: 'category_mimicry',
    name: 'Mimicry Master',
    description: 'Completed 5 emotion mimicry missions',
    type: BadgeType.category,
    level: 2,
    iconName: 'face',
    color: SeeAppTheme.joyColor,
  );
  
  static MissionBadge storyteller = MissionBadge(
    id: 'category_storytelling',
    name: 'Emotional Storyteller',
    description: 'Completed 5 storytelling missions',
    type: BadgeType.category,
    level: 2,
    iconName: 'book',
    color: SeeAppTheme.primaryColor,
  );
  
  static MissionBadge emotionNamer = MissionBadge(
    id: 'category_labeling',
    name: 'Emotion Namer',
    description: 'Completed 5 emotion labeling missions',
    type: BadgeType.category,
    level: 2,
    iconName: 'label',
    color: SeeAppTheme.secondaryColor,
  );
  
  static MissionBadge comfortGiver = MissionBadge(
    id: 'category_bonding',
    name: 'Comfort Giver',
    description: 'Completed 5 physical bonding missions',
    type: BadgeType.category,
    level: 2,
    iconName: 'favorite',
    color: SeeAppTheme.calmColor,
  );
  
  static MissionBadge routineBuilder = MissionBadge(
    id: 'category_routines',
    name: 'Routine Builder',
    description: 'Completed 5 shared routines missions',
    type: BadgeType.category,
    level: 2,
    iconName: 'calendar_today',
    color: Colors.purple,
  );
  
  // Reflection badges
  static MissionBadge thoughtfulParent = MissionBadge(
    id: 'reflection_first',
    name: 'Thoughtful Parent',
    description: 'Added your first reflection',
    type: BadgeType.reflection,
    level: 1,
    iconName: 'format_quote',
    color: SeeAppTheme.accentColor,
  );
  
  static MissionBadge reflectivePractice = MissionBadge(
    id: 'reflection_five',
    name: 'Reflective Practice',
    description: 'Added 5 mission reflections',
    type: BadgeType.reflection,
    level: 2,
    iconName: 'format_quote',
    color: SeeAppTheme.accentColor,
  );
  
  // Milestone badges
  static MissionBadge firstMission = MissionBadge(
    id: 'milestone_first',
    name: 'First Step',
    description: 'Completed your first mission',
    type: BadgeType.milestone,
    level: 1,
    iconName: 'emoji_events',
    color: SeeAppTheme.primaryColor,
  );
  
  static MissionBadge tenMissions = MissionBadge(
    id: 'milestone_ten',
    name: 'Dedicated Parent',
    description: 'Completed 10 missions',
    type: BadgeType.milestone,
    level: 2,
    iconName: 'emoji_events',
    color: SeeAppTheme.primaryColor,
  );
  
  static MissionBadge twentyFiveMissions = MissionBadge(
    id: 'milestone_twentyfive',
    name: 'Emotional Growth Champion',
    description: 'Completed 25 missions',
    type: BadgeType.milestone,
    level: 3,
    iconName: 'emoji_events',
    color: SeeAppTheme.primaryColor,
  );
  
  /// Get all predefined badges
  static List<MissionBadge> getAll() {
    return [
      firstMission,
      tenMissions,
      twentyFiveMissions,
      threeDay,
      fiveDay,
      sevenDay,
      allCategories,
      mimicryMaster,
      storyteller,
      emotionNamer,
      comfortGiver,
      routineBuilder,
      thoughtfulParent,
      reflectivePractice,
    ];
  }
}