import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:see_app/models/mission.dart';
import 'package:see_app/models/mission_badge.dart';
import 'package:see_app/models/mission_category.dart';

/// Service for managing parent-child bonding missions
class MissionService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  CollectionReference get _missionsCollection => _firestore.collection('missions');
  CollectionReference get _userMissionsCollection => _firestore.collection('user_missions');
  CollectionReference get _missionStreaksCollection => _firestore.collection('mission_streaks');
  CollectionReference get _userBadgesCollection => _firestore.collection('user_badges');
  
  // Current user helper
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;
  
  // State variables
  List<Mission> _missions = [];
  Mission? _todaysMission;
  MissionStreak? _userStreak;
  List<MissionBadge> _badges = [];
  MissionBadge? _lastEarnedBadge;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<Mission> get missions => _missions;
  Mission? get todaysMission => _todaysMission;
  MissionStreak? get userStreak => _userStreak;
  List<MissionBadge> get badges => _badges;
  MissionBadge? get lastEarnedBadge => _lastEarnedBadge;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Initialize the service and load data
  MissionService() {
    fetchMissions();
    fetchBadges();
  }
  
  /// Get all available missions
  Future<void> fetchMissions() async {
    if (_currentUserId == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Check if we have any missions in the database
      final snapshot = await _missionsCollection.limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        // If no missions exist yet, create initial data
        await _createInitialMissions();
      }
      
      // Get all missions
      final missionsSnapshot = await _missionsCollection.get();
      
      // Get user's completed missions
      final userMissionsSnapshot = await _userMissionsCollection
          .where('userId', isEqualTo: _currentUserId)
          .get();
      
      // Convert to Set of mission IDs for easy lookup
      final Set<String> completedMissionIds = userMissionsSnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['missionId'] as String)
          .toSet();
      
      // Map missions and merge with user completion data
      _missions = missionsSnapshot.docs.map((doc) {
        final mission = Mission.fromFirestore(doc);
        // Update completion status from user data
        if (completedMissionIds.contains(mission.id)) {
          // Find the user mission document to get completion details
          final userMissionDocs = userMissionsSnapshot.docs.where(
            (userDoc) => (userDoc.data() as Map<String, dynamic>)['missionId'] == mission.id,
          ).toList();
          
          if (userMissionDocs.isNotEmpty) {
            final userMissionDoc = userMissionDocs.first;
            final userData = userMissionDoc.data() as Map<String, dynamic>;
            
            // Update mission with user's completion data
            return mission.copyWith(
              isCompleted: true,
              completedAt: (userData['completedAt'] as Timestamp).toDate(),
              reflection: userData['reflection'],
            );
          }
        }
        
        return mission;
      }).toList();
      
      // Sort missions by difficulty (easier ones first)
      _missions.sort((a, b) => a.difficulty.compareTo(b.difficulty));
      
      // Select today's mission
      _selectTodaysMission();
      
      // Fetch user streak data
      await _fetchUserStreak();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching missions: $e');
      _error = 'Failed to load missions: ${e.toString()}';
      
      // Fallback to mock data
      _missions = _getMockMissions();
      _selectTodaysMission();
      
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Fetch user's badges
  Future<void> fetchBadges() async {
    if (_currentUserId == null) return;
    
    try {
      // Get the predefined badges
      final predefinedBadges = PredefinedBadges.getAll();
      
      // Get the user's earned badges
      final userBadgesSnapshot = await _userBadgesCollection
          .where('userId', isEqualTo: _currentUserId)
          .get();
      
      // Create a map of badge IDs to earned status for quick lookup
      final Map<String, MissionBadge> earnedBadgesMap = {};
      
      for (final doc in userBadgesSnapshot.docs) {
        final badgeData = doc.data() as Map<String, dynamic>;
        final badgeId = badgeData['badgeId'] as String;
        
        // Create a badge object for each earned badge
        earnedBadgesMap[badgeId] = MissionBadge(
          id: badgeId,
          name: badgeData['name'] ?? '',
          description: badgeData['description'] ?? '',
          type: _parseBadgeType(badgeData['type']),
          level: badgeData['level'] ?? 1,
          isEarned: true,
          earnedAt: (badgeData['earnedAt'] as Timestamp?)?.toDate(),
          iconName: badgeData['iconName'] ?? 'emoji_events',
          color: _parseColor(badgeData['color']),
        );
      }
      
      // Update the predefined badges with earned status
      _badges = predefinedBadges.map((badge) {
        if (earnedBadgesMap.containsKey(badge.id)) {
          return earnedBadgesMap[badge.id]!;
        }
        return badge;
      }).toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching badges: $e');
    }
  }
  
  /// Complete a mission and update user streak
  Future<bool> completeMission(String missionId, {String? reflection}) async {
    if (_currentUserId == null) return false;
    
    try {
      final now = DateTime.now();
      
      // Find the mission
      final missionIndex = _missions.indexWhere((m) => m.id == missionId);
      if (missionIndex < 0) return false;
      
      // Update the mission locally
      _missions[missionIndex].complete(reflection: reflection);
      
      // Create user mission record
      await _userMissionsCollection.add({
        'userId': _currentUserId,
        'missionId': missionId,
        'completedAt': Timestamp.fromDate(now),
        'reflection': reflection,
      });
      
      // Update user streak
      await _updateUserStreak(missionId);
      
      // Check for badge unlocks
      await _checkBadgeUnlocks(missionId, reflection != null);
      
      // If the completed mission was today's mission, select a new one
      if (_todaysMission?.id == missionId) {
        _selectTodaysMission();
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error completing mission: $e');
      return false;
    }
  }
  
  /// Check if user qualifies for any badges
  Future<void> _checkBadgeUnlocks(String missionId, bool addedReflection) async {
    if (_currentUserId == null || _userStreak == null) return;
    
    _lastEarnedBadge = null;
    final newBadges = <MissionBadge>[];
    
    try {
      // Get counts for various badges
      final completedMissions = _missions.where((m) => m.isCompleted).length;
      final currentStreak = _userStreak!.currentStreak;
      final categoryMap = <MissionCategory, int>{};
      
      // Count completed missions by category
      for (var mission in _missions.where((m) => m.isCompleted)) {
        categoryMap[mission.category] = (categoryMap[mission.category] ?? 0) + 1;
      }
      
      // Check for first mission badge
      if (completedMissions == 1) {
        newBadges.add(await _unlockBadge(PredefinedBadges.firstMission));
      }
      
      // Check for milestone badges
      if (completedMissions >= 10) {
        newBadges.add(await _unlockBadge(PredefinedBadges.tenMissions));
      }
      
      if (completedMissions >= 25) {
        newBadges.add(await _unlockBadge(PredefinedBadges.twentyFiveMissions));
      }
      
      // Check for streak badges
      if (currentStreak >= 3) {
        newBadges.add(await _unlockBadge(PredefinedBadges.threeDay));
      }
      
      if (currentStreak >= 5) {
        newBadges.add(await _unlockBadge(PredefinedBadges.fiveDay));
      }
      
      if (currentStreak >= 7) {
        newBadges.add(await _unlockBadge(PredefinedBadges.sevenDay));
      }
      
      // Check for category badges
      if (categoryMap[MissionCategory.mimicry] != null && categoryMap[MissionCategory.mimicry]! >= 5) {
        newBadges.add(await _unlockBadge(PredefinedBadges.mimicryMaster));
      }
      
      if (categoryMap[MissionCategory.storytelling] != null && categoryMap[MissionCategory.storytelling]! >= 5) {
        newBadges.add(await _unlockBadge(PredefinedBadges.storyteller));
      }
      
      if (categoryMap[MissionCategory.labeling] != null && categoryMap[MissionCategory.labeling]! >= 5) {
        newBadges.add(await _unlockBadge(PredefinedBadges.emotionNamer));
      }
      
      if (categoryMap[MissionCategory.bonding] != null && categoryMap[MissionCategory.bonding]! >= 5) {
        newBadges.add(await _unlockBadge(PredefinedBadges.comfortGiver));
      }
      
      if (categoryMap[MissionCategory.routines] != null && categoryMap[MissionCategory.routines]! >= 5) {
        newBadges.add(await _unlockBadge(PredefinedBadges.routineBuilder));
      }
      
      // Check for variety badge (completed at least one mission in each category)
      final completedCategories = categoryMap.keys.length;
      if (completedCategories >= MissionCategory.values.length) {
        newBadges.add(await _unlockBadge(PredefinedBadges.allCategories));
      }
      
      // Check for reflection badges
      if (addedReflection) {
        // Count missions with reflections
        final reflectionCount = _missions.where((m) => m.isCompleted && m.reflection != null).length;
        
        if (reflectionCount == 1) {
          newBadges.add(await _unlockBadge(PredefinedBadges.thoughtfulParent));
        }
        
        if (reflectionCount >= 5) {
          newBadges.add(await _unlockBadge(PredefinedBadges.reflectivePractice));
        }
      }
      
      // Update badges in state
      if (newBadges.isNotEmpty) {
        // Remove nulls (already earned badges return null)
        final actualNewBadges = newBadges.where((b) => b != null).toList();
        
        if (actualNewBadges.isNotEmpty) {
          // If multiple badges were earned, show the highest level one
          actualNewBadges.sort((a, b) => b.level.compareTo(a.level));
          _lastEarnedBadge = actualNewBadges.first;
          
          // Update the badges list
          fetchBadges();
        }
      }
    } catch (e) {
      debugPrint('Error checking badge unlocks: $e');
    }
  }
  
  /// Unlock a badge for the current user
  Future<MissionBadge> _unlockBadge(MissionBadge badge) async {
    if (_currentUserId == null) return badge;
    
    try {
      // Check if badge is already earned
      final badgeIndex = _badges.indexWhere((b) => b.id == badge.id);
      if (badgeIndex >= 0 && _badges[badgeIndex].isEarned) {
        return badge; // Already earned
      }
      
      // Mark badge as earned
      final earnedBadge = badge.earn();
      
      // Save to database
      await _userBadgesCollection.add({
        'userId': _currentUserId,
        'badgeId': earnedBadge.id,
        'name': earnedBadge.name,
        'description': earnedBadge.description,
        'type': earnedBadge.type.toString().split('.').last,
        'level': earnedBadge.level,
        'earnedAt': Timestamp.fromDate(earnedBadge.earnedAt!),
        'iconName': earnedBadge.iconName,
        'color': earnedBadge.color.value.toRadixString(16),
      });
      
      // Update local cache
      if (badgeIndex >= 0) {
        _badges[badgeIndex] = earnedBadge;
      } else {
        _badges.add(earnedBadge);
      }
      
      return earnedBadge;
    } catch (e) {
      debugPrint('Error unlocking badge: $e');
      return badge;
    }
  }
  
  /// Helper to parse badge type from string (for compatibility with MissionBadge class)
  BadgeType _parseBadgeType(String? type) {
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
  
  /// Helper to parse color from string (for compatibility with MissionBadge class)
  Color _parseColor(String? hexColor) {
    if (hexColor == null) return Colors.blue;
    try {
      final colorValue = int.parse(hexColor, radix: 16);
      return Color(colorValue);
    } catch (e) {
      return Colors.blue;
    }
  }
  
  /// Select today's mission
  void _selectTodaysMission() {
    // Filter out completed missions
    final incompleteMissions = _missions.where((m) => !m.isCompleted).toList();
    
    if (incompleteMissions.isEmpty) {
      // If all missions are completed, select a random one
      _todaysMission = _missions.isEmpty ? null : _missions[DateTime.now().day % _missions.length];
      return;
    }
    
    // Select based on current streak to provide variety
    final streakLength = _userStreak?.currentStreak ?? 0;
    
    // Group missions by difficulty
    final easyMissions = incompleteMissions.where((m) => m.difficulty == 1).toList();
    final mediumMissions = incompleteMissions.where((m) => m.difficulty == 2).toList();
    final hardMissions = incompleteMissions.where((m) => m.difficulty == 3).toList();
    
    // Select based on streak length to gradually increase difficulty
    if (streakLength < 3 && easyMissions.isNotEmpty) {
      // For beginners, start with easy missions
      _todaysMission = easyMissions[DateTime.now().day % easyMissions.length];
    } else if (streakLength < 7 && mediumMissions.isNotEmpty) {
      // After a few days, offer medium difficulty
      _todaysMission = mediumMissions[DateTime.now().day % mediumMissions.length];
    } else if (hardMissions.isNotEmpty) {
      // For experienced users, offer challenging missions
      _todaysMission = hardMissions[DateTime.now().day % hardMissions.length];
    } else {
      // Fallback to any incomplete mission
      _todaysMission = incompleteMissions[DateTime.now().day % incompleteMissions.length];
    }
  }
  
  /// Fetch user's streak data
  Future<void> _fetchUserStreak() async {
    if (_currentUserId == null) return;
    
    try {
      final streakDoc = await _missionStreaksCollection.doc(_currentUserId).get();
      
      if (streakDoc.exists) {
        _userStreak = MissionStreak.fromFirestore(streakDoc);
      } else {
        // Create new streak record for user
        _userStreak = MissionStreak(
          userId: _currentUserId!,
          currentStreak: 0,
          longestStreak: 0,
          lastCompletedDate: DateTime.now().subtract(const Duration(days: 1)),
          completedMissionIds: [],
        );
        
        await _missionStreaksCollection.doc(_currentUserId).set(_userStreak!.toFirestore());
      }
    } catch (e) {
      debugPrint('Error fetching user streak: $e');
    }
  }
  
  /// Update user's streak data after completing a mission
  Future<void> _updateUserStreak(String missionId) async {
    if (_currentUserId == null || _userStreak == null) return;
    
    try {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final lastCompletedDate = _userStreak!.lastCompletedDate;
      final lastCompletedDay = DateTime(
        lastCompletedDate.year,
        lastCompletedDate.month,
        lastCompletedDate.day,
      );
      
      // Check if last completed mission was yesterday or today
      final bool isConsecutiveDay = 
          lastCompletedDay.isAtSameMomentAs(yesterday) || 
          lastCompletedDay.isAtSameMomentAs(DateTime(now.year, now.month, now.day));
      
      // Calculate new streak
      int newStreak;
      if (isConsecutiveDay) {
        // Only increment streak if no mission completed today yet
        if (lastCompletedDay.isAtSameMomentAs(yesterday)) {
          newStreak = _userStreak!.currentStreak + 1;
        } else {
          newStreak = _userStreak!.currentStreak; // Already completed a mission today
        }
      } else {
        // Streak broken
        newStreak = 1; // Reset streak, today counts as 1
      }
      
      // Update longest streak if applicable
      final newLongestStreak = newStreak > _userStreak!.longestStreak
          ? newStreak
          : _userStreak!.longestStreak;
      
      // Add mission to completed list
      final completedMissions = List<String>.from(_userStreak!.completedMissionIds);
      if (!completedMissions.contains(missionId)) {
        completedMissions.add(missionId);
      }
      
      // Update streak object
      _userStreak = _userStreak!.copyWith(
        currentStreak: newStreak,
        longestStreak: newLongestStreak,
        lastCompletedDate: now,
        completedMissionIds: completedMissions,
      );
      
      // Update in database
      await _missionStreaksCollection.doc(_currentUserId).set(_userStreak!.toFirestore());
    } catch (e) {
      debugPrint('Error updating user streak: $e');
    }
  }
  
  /// Get missions by category
  List<Mission> getMissionsByCategory(MissionCategory category) {
    return _missions.where((m) => m.category == category).toList();
  }
  
  /// Get missions by completion status
  List<Mission> getMissionsByCompletion(bool isCompleted) {
    return _missions.where((m) => m.isCompleted == isCompleted).toList();
  }
  
  /// Get missions by difficulty
  List<Mission> getMissionsByDifficulty(int difficulty) {
    return _missions.where((m) => m.difficulty == difficulty).toList();
  }
  
  /// Get badges by type
  List<MissionBadge> getBadgesByType(BadgeType type) {
    return _badges.where((b) => b.type == type).toList();
  }
  
  /// Get earned badges
  List<MissionBadge> getEarnedBadges() {
    return _badges.where((b) => b.isEarned).toList();
  }
  
  /// Clear the last earned badge notification
  void clearLastEarnedBadge() {
    _lastEarnedBadge = null;
    notifyListeners();
  }
  
  /// Clear any error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Create initial mission data
  Future<void> _createInitialMissions() async {
    try {
      final batch = _firestore.batch();
      
      // Create missions from our library
      final missions = _getMockMissions();
      
      for (final mission in missions) {
        final docRef = _missionsCollection.doc();
        batch.set(docRef, {
          ...mission.toFirestore(),
          'id': docRef.id, // Include ID in the document
        });
      }
      
      await batch.commit();
      debugPrint('Created ${missions.length} initial missions');
    } catch (e) {
      debugPrint('Error creating initial missions: $e');
    }
  }
  
  /// Get mock missions data
  List<Mission> _getMockMissions() {
    return [
      // Emotion Mimicry category
      Mission(
        id: 'mimicry-1',
        title: 'Mirror My Emotion',
        description: 'Ask your child to make a happy face, then mirror it. Take turns with different emotions.',
        category: MissionCategory.mimicry,
        evidenceSource: 'Izard et al., 2008',
        difficulty: 1,
        dueDate: DateTime.now().add(Duration(days: 7)),
        assignedTo: _currentUserId ?? 'system',
      ),
      Mission(
        id: 'mimicry-2',
        title: 'Silly Face Exchange',
        description: 'Take turns showing a silly face. Ask each other to guess what emotion it represents.',
        category: MissionCategory.mimicry,
        evidenceSource: 'Izard et al., 2008',
        difficulty: 1,
        dueDate: DateTime.now().add(Duration(days: 7)),
        assignedTo: _currentUserId ?? 'system',
      ),
      Mission(
        id: 'mimicry-3',
        title: 'Mirror Emotions',
        description: 'Look in the mirror together and act out "angry," "sad," and "proud." Talk about how each emotion feels in your body.',
        category: MissionCategory.mimicry,
        evidenceSource: 'Izard et al., 2008',
        difficulty: 2,
        dueDate: DateTime.now().add(Duration(days: 7)),
        assignedTo: _currentUserId ?? 'system',
      ),
      
      // Emotional Storytelling category
      Mission(
        id: 'storytelling-1',
        title: 'Share Your Proud Moment',
        description: 'Tell your child about a time you felt proud. Ask them when they felt that way.',
        category: MissionCategory.storytelling,
        evidenceSource: 'Laible & Song, 2006',
        difficulty: 1,
        dueDate: DateTime.now().add(Duration(days: 7)),
        assignedTo: _currentUserId ?? 'system',
      ),
      Mission(
        id: 'storytelling-2',
        title: 'Childhood Fears',
        description: 'Describe a situation when you were scared as a kid and what helped you feel better. Ask if they want to share their fears.',
        category: MissionCategory.storytelling,
        evidenceSource: 'Laible & Song, 2006',
        difficulty: 2,
        dueDate: DateTime.now().add(Duration(days: 7)),
        assignedTo: _currentUserId ?? 'system',
      ),
      Mission(
        id: 'storytelling-3',
        title: 'Emotion Journey Story',
        description: 'Invent a short story together where the hero feels "confused" then "relieved." Let your child choose what happens to cause these feelings.',
        category: MissionCategory.storytelling,
        evidenceSource: 'Laible & Song, 2006',
        difficulty: 3,
        dueDate: DateTime.now().add(Duration(days: 7)),
        assignedTo: _currentUserId ?? 'system',
      ),
      
      // Emotion Labeling category
      Mission(
        id: 'labeling-1',
        title: 'Happy Things Hunt',
        description: 'Point to 3 things today that made you feel happy. Ask your child to do the same.',
        category: MissionCategory.labeling,
        evidenceSource: 'Denham et al., 2003',
        difficulty: 1,
        dueDate: DateTime.now().add(Duration(days: 7)),
        assignedTo: _currentUserId ?? 'system',
      ),
      Mission(
        id: 'labeling-2',
        title: 'Story Character Feelings',
        description: 'After reading a story, ask: "How do you think the character felt when that happened?" Help them name the emotion if needed.',
        category: MissionCategory.labeling,
        evidenceSource: 'Denham et al., 2003',
        difficulty: 2,
        dueDate: DateTime.now().add(Duration(days: 7)),
        assignedTo: _currentUserId ?? 'system',
      ),
      Mission(
        id: 'labeling-3',
        title: 'Emotion Memory Match',
        description: 'Name an emotion and ask your child to find a memory that fits. Take turns with different emotions.',
        category: MissionCategory.labeling,
        evidenceSource: 'Denham et al., 2003',
        difficulty: 2,
        dueDate: DateTime.now().add(Duration(days: 7)),
        assignedTo: _currentUserId ?? 'system',
      ),
      
      // Physical Bonding category
      Mission(
        id: 'bonding-1',
        title: 'Bedtime Appreciation Hug',
        description: 'End the day with a long, warm hug and say, "I love you because…" Invite your child to share what they love about you.',
        category: MissionCategory.bonding,
        evidenceSource: 'Landry et al., 2006; Crittenden, 1992',
        difficulty: 1,
        dueDate: DateTime.now().add(Duration(days: 7)),
        assignedTo: _currentUserId ?? 'system',
      ),
      Mission(
        id: 'bonding-2',
        title: 'Hand-in-Hand Walk',
        description: 'Hold hands during a walk and talk about the day\'s feelings. Ask open questions like "What made you smile today?"',
        category: MissionCategory.bonding,
        evidenceSource: 'Landry et al., 2006; Crittenden, 1992',
        difficulty: 1,
        dueDate: DateTime.now().add(Duration(days: 7)),
        assignedTo: _currentUserId ?? 'system',
      ),
      Mission(
        id: 'bonding-3',
        title: 'Breathing Buddies',
        description: 'Practice 5-second deep breathing together while touching fingertips. Talk about how it makes your bodies feel.',
        category: MissionCategory.bonding,
        evidenceSource: 'Landry et al., 2006; Crittenden, 1992',
        difficulty: 2,
        dueDate: DateTime.now().add(Duration(days: 7)),
        assignedTo: _currentUserId ?? 'system',
      ),
      
      // Shared Routines category
      Mission(
        id: 'routines-1',
        title: 'Emotion Word of the Day',
        description: 'Let your child help pick a fun emotion word for the day and use it often. Notice when you or others feel that emotion.',
        category: MissionCategory.routines,
        evidenceSource: 'Fogg, 2009; Bowlby, 1988',
        difficulty: 2,
        dueDate: DateTime.now().add(Duration(days: 7)),
        assignedTo: _currentUserId ?? 'system',
      ),
      Mission(
        id: 'routines-2',
        title: 'Emotion of the Day Breakfast',
        description: 'Start a new ritual: "Emotion of the Day" breakfast talk. Each person shares what emotion they\'re feeling and why.',
        category: MissionCategory.routines,
        evidenceSource: 'Fogg, 2009; Bowlby, 1988',
        difficulty: 2,
        dueDate: DateTime.now().add(Duration(days: 7)),
        assignedTo: _currentUserId ?? 'system',
      ),
      Mission(
        id: 'routines-3',
        title: 'Goodbye Emotion Check-in',
        description: 'Create a simple goodbye routine with one positive emotion shared each time: "I feel ____ about seeing you later today."',
        category: MissionCategory.routines,
        evidenceSource: 'Fogg, 2009; Bowlby, 1988',
        difficulty: 3,
        dueDate: DateTime.now().add(Duration(days: 7)),
        assignedTo: _currentUserId ?? 'system',
      ),
    ];
  }
}