import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:see_app/models/child.dart';

class LocalStorageHelper {
  // Keys
  static const String onboardingCompletedKey = 'onboarding_completed_';
  static const String childDataKey = 'child_data_';
  static const String childNameKey = 'child_name_';
  static const String specialtiesKey = 'specialties_';
  
  // Save onboarding completion status
  static Future<bool> saveOnboardingCompleted(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool('$onboardingCompletedKey$userId', true);
    } catch (e) {
      debugPrint('Error saving onboarding status: $e');
      return false;
    }
  }
  
  // Save child data from onboarding
  static Future<bool> saveChildData(String userId, String? name, int? age, 
      String? gender, List<String> concerns) async {
    try {
      if (name == null) return false;
      
      final prefs = await SharedPreferences.getInstance();
      
      // Full data as JSON
      final Map<String, dynamic> childData = {
        'name': name,
        'age': age ?? 5,
        'gender': gender ?? 'Unknown',
        'concerns': concerns,
        'createdAt': DateTime.now().toIso8601String(),
        'parentId': userId,
      };
      
      // Also save name separately as fallback
      await prefs.setString('$childNameKey$userId', name);
      
      // Save the full JSON data
      final result = await prefs.setString('$childDataKey$userId', jsonEncode(childData));
      debugPrint('Saved child data to local storage: $childData');
      return result;
    } catch (e) {
      debugPrint('Error saving child data: $e');
      return false;
    }
  }
  
  // Load child from local storage
  static Future<Child?> loadLocalChild(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to get the full JSON child data first
      final String? localChildDataJson = prefs.getString('$childDataKey$userId');
      final String? legacyChildName = prefs.getString('$childNameKey$userId');
      
      // Case 1: We have full JSON data
      if (localChildDataJson != null) {
        try {
          // Parse JSON
          final Map<String, dynamic> childData = jsonDecode(localChildDataJson);
          
          // Create child object from saved data
          return Child(
            id: 'local_${DateTime.now().millisecondsSinceEpoch}',
            name: childData['name'] ?? 'Unknown',
            age: childData['age'] ?? 0,
            gender: childData['gender'] ?? 'Unknown',
            parentId: childData['parentId'] ?? '',
            concerns: List<String>.from(childData['concerns'] ?? []),
          );
        } catch (jsonError) {
          debugPrint('Error parsing saved child data: $jsonError');
          // Fall through to legacy approach if we can't parse JSON
        }
      }
      
      // Case 2: Fall back to legacy approach (just name)
      if (legacyChildName != null) {
        return Child(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          name: legacyChildName,
          age: 5,  // Default age
          gender: 'Unknown',
          parentId: userId,
          concerns: [],
        );
      }
      
      // No data found
      return null;
    } catch (e) {
      debugPrint('Error loading local child data: $e');
      return null;
    }
  }
  
  // Save therapist specialties
  static Future<bool> saveTherapistSpecialties(String userId, List<String> specialties) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setStringList('$specialtiesKey$userId', specialties);
    } catch (e) {
      debugPrint('Error saving therapist specialties: $e');
      return false;
    }
  }
  
  // Get therapist specialties
  static Future<List<String>> getTherapistSpecialties(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('$specialtiesKey$userId') ?? [];
    } catch (e) {
      debugPrint('Error getting therapist specialties: $e');
      return [];
    }
  }
}
