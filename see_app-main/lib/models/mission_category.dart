/// Represents a category of parent-child bonding mission
enum MissionCategory {
  mimicry,      // Emotion mimicry exercises
  storytelling, // Emotional storytelling activities
  labeling,     // Emotion labeling activities
  bonding,      // Physical bonding and comfort
  routines,     // Shared emotional routines
  mindfulness,  // Mindfulness and emotional awareness
  journaling,   // Emotion journaling activities
  creativity,   // Creative expression of emotions
  physical,     // Physical activities for emotional regulation
  social        // Social emotional learning activities
}

/// Extension methods for MissionCategory
extension MissionCategoryExtension on MissionCategory {
  /// Get a human-readable name
  String get name {
    switch (this) {
      case MissionCategory.mimicry:
        return 'Emotion Mimicry';
      case MissionCategory.storytelling:
        return 'Emotional Storytelling';
      case MissionCategory.labeling:
        return 'Emotion Labeling';
      case MissionCategory.bonding:
        return 'Physical Bonding';
      case MissionCategory.routines:
        return 'Shared Routines';
      case MissionCategory.mindfulness:
        return 'Mindfulness';
      case MissionCategory.journaling:
        return 'Emotion Journaling';
      case MissionCategory.creativity:
        return 'Creative Expression';
      case MissionCategory.physical:
        return 'Physical Activity';
      case MissionCategory.social:
        return 'Social Learning';
      default:
        return 'Unknown';
    }
  }
}
