/// Represents the difficulty level of a mission or activity
enum DifficultyLevel {
  easy,
  medium,
  hard
}

/// Extension methods for DifficultyLevel
extension DifficultyLevelExtension on DifficultyLevel {
  /// Get a human-readable name
  String get name {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
      default:
        return 'Unknown';
    }
  }

  /// Get a numerical value (1-3)
  int get value {
    switch (this) {
      case DifficultyLevel.easy:
        return 1;
      case DifficultyLevel.medium:
        return 2;
      case DifficultyLevel.hard:
        return 3;
      default:
        return 2;
    }
  }

  /// Convert to stars representation
  String get stars {
    final filled = '★' * value;
    final empty = '☆' * (3 - value);
    return filled + empty;
  }
}
