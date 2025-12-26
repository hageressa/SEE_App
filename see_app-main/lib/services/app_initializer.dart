import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/services/database_service.dart';

/// Service for initializing the app with test data on first run
class AppInitializer {
  static const String _firstRunKey = 'first_run_completed';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _databaseService;
  
  AppInitializer(this._databaseService);
  
  /// Check if this is the first run of the app
  Future<bool> isFirstRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_firstRunKey) ?? false);
    } catch (e) {
      debugPrint('Error checking first run: $e');
      return false; // Default to false if there's an error
    }
  }
  
  /// Mark the first run as completed
  Future<void> _markFirstRunCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstRunKey, true);
    } catch (e) {
      debugPrint('Error marking first run as completed: $e');
    }
  }
  
  /// Initialize the app with default data on first run
  Future<void> initializeAppIfNeeded() async {
    // Skip initialization for production builds
    if (kReleaseMode) {
      debugPrint('Production mode detected, skipping test data initialization');
      await _markFirstRunCompleted();
      return;
    }
    
    // Check if this is the first run
    if (!await isFirstRun()) {
      debugPrint('Not first run, skipping initialization');
      return;
    }
    
    debugPrint('First run detected, initializing app with default data');
    await _createDefaultData();
    await _markFirstRunCompleted();
  }
  
  /// Create default data for the app
  Future<void> _createDefaultData() async {
    try {
      // Check if any users already exist in Firestore
      final usersSnapshot = await _firestore.collection('users').limit(1).get();
      if (usersSnapshot.docs.isNotEmpty) {
        debugPrint('Users already exist in Firestore, skipping initialization');
        return;
      }
      
      // Check if any Firebase Auth users exist
      try {
        // Try to sign in with a test account to see if it exists
        await _auth.signInWithEmailAndPassword(
          email: 'parent@example.com',
          password: 'password123',
        );
        // If successful, user exists, so sign out and skip initialization
        await _auth.signOut();
        debugPrint('Firebase Auth users already exist, skipping initialization');
        return;
      } catch (e) {
        // User doesn't exist, continue with initialization
        debugPrint('No existing Firebase Auth users found, creating test accounts');
      }
      
      // Create a test parent account
      final parentCred = await _auth.createUserWithEmailAndPassword(
        email: 'parent@example.com',
        password: 'password123',
      );
      
      // Create a test therapist account
      final therapistCred = await _auth.createUserWithEmailAndPassword(
        email: 'therapist@example.com',
        password: 'password123',
      );
      
      // Create a second parent account for testing
      final parent2Cred = await _auth.createUserWithEmailAndPassword(
        email: 'parent2@example.com',
        password: 'password123',
      );
      
      // Create a second therapist account for testing
      final therapist2Cred = await _auth.createUserWithEmailAndPassword(
        email: 'therapist2@example.com',
        password: 'password123',
      );
      
      // Create complete test accounts with associated data
      if (parentCred.user != null) {
        await _databaseService.createTestAccount(
          userId: parentCred.user!.uid,
          email: 'parent@example.com',
          name: 'John Parent',
          role: UserRole.parent,
        );
      }
      
      if (therapistCred.user != null) {
        await _databaseService.createTestAccount(
          userId: therapistCred.user!.uid,
          email: 'therapist@example.com',
          name: 'Dr. Sarah Therapist',
          role: UserRole.therapist,
        );
      }
      
      if (parent2Cred.user != null) {
        await _databaseService.createTestAccount(
          userId: parent2Cred.user!.uid,
          email: 'parent2@example.com',
          name: 'Mary Parent',
          role: UserRole.parent,
        );
      }
      
      if (therapist2Cred.user != null) {
        await _databaseService.createTestAccount(
          userId: therapist2Cred.user!.uid,
          email: 'therapist2@example.com',
          name: 'Dr. David Therapist',
          role: UserRole.therapist,
        );
      }
      
      // Sign out after creating accounts
      await _auth.signOut();
      
      debugPrint('Default accounts created successfully');
    } catch (e) {
      debugPrint('Error creating default data: $e');
    }
  }
}