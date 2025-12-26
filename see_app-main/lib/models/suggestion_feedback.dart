import 'package:see_app/models/emotion_data.dart';

/// Rating scale for suggestion effectiveness
enum EffectivenessRating {
  notEffective, // Didn't help at all
  slightlyEffective, // Helped a little
  moderatelyEffective, // Helped somewhat
  veryEffective, // Helped significantly
  extremelyEffective, // Helped tremendously
}

/// Feedback provided by parents on the effectiveness of calming suggestions
class SuggestionFeedback {
  final String id;
  final String suggestionId;
  final String childId;
  final String parentId;
  final DateTime usedAt;
  final EffectivenessRating rating;
  final EmotionType beforeEmotion; // Emotion before using suggestion
  final double beforeIntensity; // 0.0 to 1.0
  final EmotionType? afterEmotion; // Emotion after using suggestion (can be null if not recorded)
  final double? afterIntensity; // 0.0 to 1.0 (can be null if not recorded)
  final String? comments; // Optional feedback from parent
  final Duration? timeSpent; // How long the suggestion was used
  final bool wasCompleted; // Whether the suggestion was completed or abandoned

  SuggestionFeedback({
    required this.id, 
    required this.suggestionId,
    required this.childId,
    required this.parentId,
    required this.usedAt,
    required this.rating,
    required this.beforeEmotion,
    required this.beforeIntensity,
    this.afterEmotion,
    this.afterIntensity,
    this.comments,
    this.timeSpent,
    this.wasCompleted = true,
  });

  factory SuggestionFeedback.fromJson(Map<String, dynamic> json) {
    return SuggestionFeedback(
      id: json['id'],
      suggestionId: json['suggestionId'],
      childId: json['childId'],
      parentId: json['parentId'],
      usedAt: DateTime.parse(json['usedAt']),
      rating: _parseEffectivenessRating(json['rating']),
      beforeEmotion: parseEmotionType(json['beforeEmotion']),
      beforeIntensity: json['beforeIntensity'].toDouble(),
      afterEmotion: json['afterEmotion'] != null 
          ? parseEmotionType(json['afterEmotion']) 
          : null,
      afterIntensity: json['afterIntensity'] != null 
          ? json['afterIntensity'].toDouble() 
          : null,
      comments: json['comments'],
      timeSpent: json['timeSpentMinutes'] != null 
          ? Duration(minutes: json['timeSpentMinutes']) 
          : null,
      wasCompleted: json['wasCompleted'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'suggestionId': suggestionId,
      'childId': childId,
      'parentId': parentId,
      'usedAt': usedAt.toIso8601String(),
      'rating': rating.toString().split('.').last,
      'beforeEmotion': beforeEmotion.toString().split('.').last,
      'beforeIntensity': beforeIntensity,
      'afterEmotion': afterEmotion?.toString().split('.').last,
      'afterIntensity': afterIntensity,
      'comments': comments,
      'timeSpentMinutes': timeSpent?.inMinutes,
      'wasCompleted': wasCompleted,
    };
  }

  static EffectivenessRating _parseEffectivenessRating(String ratingStr) {
    switch (ratingStr) {
      case 'notEffective':
        return EffectivenessRating.notEffective;
      case 'slightlyEffective':
        return EffectivenessRating.slightlyEffective;
      case 'moderatelyEffective':
        return EffectivenessRating.moderatelyEffective;
      case 'veryEffective':
        return EffectivenessRating.veryEffective;
      case 'extremelyEffective':
        return EffectivenessRating.extremelyEffective;
      default:
        return EffectivenessRating.moderatelyEffective;
    }
  }
  
  /// Parse string representation of emotion type to enum
  static EmotionType parseEmotionType(String typeStr) {
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
      default:
        return EmotionType.calm; // Default fallback
    }
  }

  /// Helper to calculate emotion improvement percentage
  double? get improvementPercentage {
    if (afterEmotion == null || afterIntensity == null) {
      return null;
    }
    
    // For positive emotions (joy, calm), higher intensity is better
    if (afterEmotion == EmotionType.joy || afterEmotion == EmotionType.calm) {
      if (beforeEmotion == EmotionType.joy || beforeEmotion == EmotionType.calm) {
        // Both before and after are positive emotions
        return ((afterIntensity! - beforeIntensity) / beforeIntensity) * 100;
      } else {
        // Before was negative, after is positive - significant improvement
        return 100.0; 
      }
    } 
    // For negative emotions (sadness, anger, fear), lower intensity is better
    else {
      if (beforeEmotion == EmotionType.joy || beforeEmotion == EmotionType.calm) {
        // Before was positive, after is negative - worsening
        return -100.0;
      } else {
        // Both before and after are negative emotions, reduction is improvement
        return ((beforeIntensity - afterIntensity!) / beforeIntensity) * 100;
      }
    }
  }

  /// Helper to get a verbal description of the effectiveness
  String get effectivenessDescription {
    switch (rating) {
      case EffectivenessRating.notEffective:
        return 'Not effective';
      case EffectivenessRating.slightlyEffective:
        return 'Slightly effective';
      case EffectivenessRating.moderatelyEffective:
        return 'Moderately effective';
      case EffectivenessRating.veryEffective:
        return 'Very effective';
      case EffectivenessRating.extremelyEffective:
        return 'Extremely effective';
    }
  }
}

/// Aggregated metrics about a suggestion's effectiveness
class SuggestionEffectivenessMetrics {
  final String suggestionId;
  final int totalUsageCount;
  final Map<EmotionType, int> usageByEmotion;
  final double averageRating; // 0.0 to 4.0 (based on EffectivenessRating enum index)
  final double averageImprovementPercentage;
  final Map<EmotionType, double> averageImprovementByEmotion;
  final Duration? averageTimeSpent;
  final double completionRate; // 0.0 to 1.0

  SuggestionEffectivenessMetrics({
    required this.suggestionId,
    required this.totalUsageCount,
    required this.usageByEmotion,
    required this.averageRating,
    required this.averageImprovementPercentage,
    required this.averageImprovementByEmotion,
    this.averageTimeSpent,
    required this.completionRate,
  });

  /// Calculate effectiveness metrics from a list of feedback entries
  factory SuggestionEffectivenessMetrics.fromFeedbackList(
    String suggestionId, 
    List<SuggestionFeedback> feedbackList
  ) {
    if (feedbackList.isEmpty) {
      return SuggestionEffectivenessMetrics(
        suggestionId: suggestionId,
        totalUsageCount: 0,
        usageByEmotion: {},
        averageRating: 0.0,
        averageImprovementPercentage: 0.0,
        averageImprovementByEmotion: {},
        averageTimeSpent: null,
        completionRate: 0.0,
      );
    }

    // Total usage count
    final totalUsageCount = feedbackList.length;
    
    // Count usage by emotion type
    final usageByEmotion = <EmotionType, int>{};
    for (final feedback in feedbackList) {
      usageByEmotion[feedback.beforeEmotion] = 
          (usageByEmotion[feedback.beforeEmotion] ?? 0) + 1;
    }
    
    // Calculate average rating
    double ratingSum = 0.0;
    for (final feedback in feedbackList) {
      ratingSum += feedback.rating.index;
    }
    final averageRating = ratingSum / totalUsageCount;
    
    // Calculate improvement percentage across all feedback
    final improvementFeedback = feedbackList
        .where((f) => f.improvementPercentage != null)
        .toList();
    
    double improvementSum = 0.0;
    for (final feedback in improvementFeedback) {
      improvementSum += feedback.improvementPercentage!;
    }
    final averageImprovementPercentage = improvementFeedback.isNotEmpty
        ? improvementSum / improvementFeedback.length
        : 0.0;
    
    // Calculate improvement by emotion type
    final improvementByEmotion = <EmotionType, List<double>>{};
    for (final feedback in improvementFeedback) {
      if (!improvementByEmotion.containsKey(feedback.beforeEmotion)) {
        improvementByEmotion[feedback.beforeEmotion] = [];
      }
      improvementByEmotion[feedback.beforeEmotion]!.add(feedback.improvementPercentage!);
    }
    
    final averageImprovementByEmotion = <EmotionType, double>{};
    for (final entry in improvementByEmotion.entries) {
      final sum = entry.value.reduce((a, b) => a + b);
      averageImprovementByEmotion[entry.key] = sum / entry.value.length;
    }
    
    // Calculate average time spent
    final timeSpentFeedback = feedbackList
        .where((f) => f.timeSpent != null)
        .toList();
    
    Duration? averageTimeSpent;
    if (timeSpentFeedback.isNotEmpty) {
      int totalMinutes = 0;
      for (final feedback in timeSpentFeedback) {
        totalMinutes += feedback.timeSpent!.inMinutes;
      }
      averageTimeSpent = Duration(
        minutes: (totalMinutes / timeSpentFeedback.length).round(),
      );
    }
    
    // Calculate completion rate
    final completedCount = feedbackList
        .where((f) => f.wasCompleted)
        .length;
    final completionRate = completedCount / totalUsageCount;
    
    return SuggestionEffectivenessMetrics(
      suggestionId: suggestionId,
      totalUsageCount: totalUsageCount,
      usageByEmotion: usageByEmotion,
      averageRating: averageRating,
      averageImprovementPercentage: averageImprovementPercentage,
      averageImprovementByEmotion: averageImprovementByEmotion,
      averageTimeSpent: averageTimeSpent,
      completionRate: completionRate,
    );
  }
}