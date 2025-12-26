enum EmotionType {
  joy,
  sadness,
  anger,
  fear,
  calm,
  disgust,
  surprise,
  neutral,
}

class EmotionData {
  final String id;
  final String childId;
  final EmotionType type;
  final double intensity; // 0.0 to 1.0
  final DateTime timestamp;
  final String? context; // Activity or situation when recorded
  final String? note; // Additional notes about the emotion
  final Map<String, dynamic>? metadata;

  EmotionData({
    required this.id,
    required this.childId,
    required this.type,
    required this.intensity,
    required this.timestamp,
    this.context,
    this.note,
    this.metadata,
  });

  factory EmotionData.fromJson(Map<String, dynamic> json) {
    return EmotionData(
      id: json['id'],
      childId: json['childId'],
      type: _parseEmotionType(json['type']),
      intensity: json['intensity'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      context: json['context'],
      note: json['note'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'type': type.toString().split('.').last,
      'intensity': intensity,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'note': note,
      'metadata': metadata,
    };
  }

  static EmotionType _parseEmotionType(String typeStr) {
    switch (typeStr) {
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
      case 'disgust':
        return EmotionType.disgust;
      case 'surprise':
        return EmotionType.surprise;
      case 'neutral':
        return EmotionType.neutral;
      default:
        return EmotionType.neutral; // Default fallback
    }
  }

  // Helper to get color associated with emotion type
  static String getEmotionName(EmotionType type) {
    switch (type) {
      case EmotionType.joy:
        return 'Joy';
      case EmotionType.sadness:
        return 'Sadness';
      case EmotionType.anger:
        return 'Anger';
      case EmotionType.fear:
        return 'Fear';
      case EmotionType.calm:
        return 'Calm';
      case EmotionType.disgust:
        return 'Disgust';
      case EmotionType.surprise:
        return 'Surprise';
      case EmotionType.neutral:
        return 'Neutral';
    }
  }
}

// Distress Alert model for parent notifications
class DistressAlert {
  final String id;
  final String childId;
  final EmotionType triggerEmotion;
  final double intensity;
  final DateTime timestamp;
  final AlertSeverity severity;
  final String? description;
  final bool isActive;

  DistressAlert({
    required this.id,
    required this.childId,
    required this.triggerEmotion,
    required this.intensity,
    required this.timestamp,
    required this.severity,
    this.description,
    this.isActive = true,
  });

  factory DistressAlert.fromJson(Map<String, dynamic> json) {
    return DistressAlert(
      id: json['id'],
      childId: json['childId'],
      triggerEmotion: EmotionData._parseEmotionType(json['triggerEmotion']),
      intensity: json['intensity'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      severity: _parseAlertSeverity(json['severity']),
      description: json['description'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'triggerEmotion': triggerEmotion.toString().split('.').last,
      'intensity': intensity,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity.toString().split('.').last,
      'description': description,
      'isActive': isActive,
    };
  }

  static AlertSeverity _parseAlertSeverity(String severityStr) {
    switch (severityStr) {
      case 'high':
        return AlertSeverity.high;
      case 'medium':
        return AlertSeverity.medium;
      case 'low':
        return AlertSeverity.low;
      default:
        return AlertSeverity.medium;
    }
  }
}

enum AlertSeverity {
  high,
  medium,
  low,
}

// Calming suggestion model to help parents respond
class CalmingSuggestion {
  final String id;
  final String childId;
  final String title;
  final String description;
  final List<EmotionType> targetEmotions;
  final String? imageUrl;
  final SuggestionCategory category;
  final Duration? estimatedTime;
  final bool isFavorite;

  CalmingSuggestion({
    required this.id,
    required this.childId,
    required this.title,
    required this.description,
    required this.targetEmotions,
    this.imageUrl,
    required this.category,
    this.estimatedTime,
    this.isFavorite = false,
  });

  factory CalmingSuggestion.fromJson(Map<String, dynamic> json) {
    return CalmingSuggestion(
      id: json['id'],
      childId: json['childId'],
      title: json['title'],
      description: json['description'],
      targetEmotions: (json['targetEmotions'] as List)
          .map((e) => EmotionData._parseEmotionType(e))
          .toList(),
      imageUrl: json['imageUrl'],
      category: _parseSuggestionCategory(json['category']),
      estimatedTime: json['estimatedTimeMinutes'] != null
          ? Duration(minutes: json['estimatedTimeMinutes'])
          : null,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'title': title,
      'description': description,
      'targetEmotions': targetEmotions
          .map((e) => e.toString().split('.').last)
          .toList(),
      'imageUrl': imageUrl,
      'category': category.toString().split('.').last,
      'estimatedTimeMinutes': estimatedTime?.inMinutes,
      'isFavorite': isFavorite,
    };
  }

  static SuggestionCategory _parseSuggestionCategory(String categoryStr) {
    switch (categoryStr) {
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
}

enum SuggestionCategory {
  physical,  // Movement-based activities
  creative,  // Art, music, crafts
  cognitive, // Puzzles, games, learning
  sensory,   // Textures, sounds, smells
  social,    // Interaction with others
}