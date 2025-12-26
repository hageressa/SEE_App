import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:see_app/models/user.dart';
import 'package:firebase_core/firebase_core.dart';

/// Service for handling authentication using Firebase Auth
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Current user info
  AppUser? _currentUser;
  
  // Stream subscription for auth state changes
  StreamSubscription? _authStateSubscription;
  
  // Loading state
  bool _isLoading = false;
  
  // Disposal flag
  bool _disposed = false;
  
  // Getters
  AppUser? get currentUser => _disposed ? null : _currentUser;
  bool get isLoading => _disposed ? false : _isLoading;
  bool get isAuthenticated => _disposed ? false : _currentUser != null;
  bool get isParent => _disposed ? false : _currentUser?.role == UserRole.parent;
  bool get isTherapist => _disposed ? false : _currentUser?.role == UserRole.therapist;
  bool get isAdmin => _disposed ? false : _currentUser?.role == UserRole.admin;
  bool get isOnboarded {
    // Check if disposed first
    if (_disposed) {
      debugPrint('isOnboarded check: AuthService is disposed');
      return false;
    }
    
    // First verify user exists
    if (_currentUser == null) {
      debugPrint('isOnboarded check: _currentUser is null');
      return false;
    }
    
    // Use null-safe access for additionalInfo
    final additionalInfo = _currentUser?.additionalInfo;
    if (additionalInfo == null) {
      debugPrint('isOnboarded check: additionalInfo is null for user ${_currentUser?.id}');
      return false;
    }
    
    // Check if the key exists and the value is true
    final onboardingCompleted = additionalInfo['onboardingCompleted'];
    final result = onboardingCompleted == true;
    
    debugPrint('isOnboarded check for ${_currentUser?.id}: $result (value=$onboardingCompleted)');
    return result;
  }
  
  // Setters
  set isOnboarded(bool value) {
    if (_disposed) {
      debugPrint('Warning: Attempted to set isOnboarded on disposed AuthService');
      return;
    }
    
    if (_currentUser != null) {
      final updatedInfo = Map<String, dynamic>.from(_currentUser!.additionalInfo ?? {});
      updatedInfo['onboardingCompleted'] = value;
      
      _currentUser = _currentUser!.copyWith(additionalInfo: updatedInfo);
      
      // Update Firestore
      _firestore.collection('users').doc(_currentUser!.id).update({
        'additionalInfo.onboardingCompleted': value
      });
      
      notifyListeners();
    }
  }
  
  /// Completes the onboarding process for the current user
  Future<bool> completeOnboarding() async {
    try {
      if (_currentUser == null) {
        return false;
      }
      
      // Create updated additionalInfo
      final updatedInfo = Map<String, dynamic>.from(_currentUser!.additionalInfo ?? {});
      updatedInfo['onboardingCompleted'] = true;
      
      // Update the user document in Firestore
      await _firestore.collection('users').doc(_currentUser!.id).update({
        'additionalInfo': updatedInfo,
      });
      
      // Update the local user object
      _currentUser = _currentUser!.copyWith(additionalInfo: updatedInfo);
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      return false;
    }
  }

  // Constructor that sets up auth state listener
  AuthService() {
    _authStateSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  @override
  void dispose() {
    if (_disposed) return; // Prevent double disposal
    
    _disposed = true;
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
    _currentUser = null;
    
    // Properly terminate Firestore when the service is disposed
    try {
      _firestore.terminate();
      debugPrint('Firestore terminated during AuthService disposal');
    } catch (e) {
      debugPrint('Error terminating Firestore during disposal: $e');
    }
    
    debugPrint('AuthService disposed and subscription cancelled');
    super.dispose();
  }
  
  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
  
  /// Helper method to create a basic user when error recovery is needed
  AppUser _createErrorRecoveryUser(String uid, String? email, String? displayName, String errorDescription) {
    debugPrint('Creating error recovery user for uid: $uid. Error: $errorDescription');
    return AppUser(
      id: uid,
      email: email ?? 'missing@email.com',
      name: displayName ?? 'User',
      role: UserRole.parent, // Default to parent
      childrenIds: [],
      createdAt: DateTime.now(),
      additionalInfo: {
        'onboardingCompleted': false, // Ensure onboarding is shown
        'errorRecovery': true,
        'errorDescription': errorDescription,
      },
    );
  }
  
  /// Handle authentication state changes
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }
    
    // Fetch the user document from Firestore
    try {
      debugPrint('Auth state changed for user: ${firebaseUser.uid}');
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (userDoc.exists) {
        // Safely get data from Firestore
        final data = userDoc.data() as Map<String, dynamic>?; // Use nullable map
        
        if (data == null) {
           debugPrint('Error: Firestore document exists but data is null for user ${firebaseUser.uid}');
           // Create a fallback user if data is unexpectedly null
           _currentUser = _createErrorRecoveryUser(firebaseUser.uid, firebaseUser.email, firebaseUser.displayName, 'Firestore data was null');
        } else {
          final roleString = data['role'] as String?;
          final isTherapistFlag = data['isTherapist'] as bool?;
          
          try {
            // Create AppUser using the fromFirestore method which parses the role
            _currentUser = AppUser.fromFirestore(userDoc);
          } on TypeError catch (typeError, stackTrace) { // Catch specific TypeError with stack trace
            debugPrint('TypeError parsing Firestore data in _onAuthStateChanged: $typeError');
            debugPrint('Stack Trace: $stackTrace');
            // Fallback: Create a basic AppUser from firebaseUser data if TypeError occurs
            _currentUser = AppUser(
              id: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              name: firebaseUser.displayName ?? _getDefaultNameByRole(UserRole.parent),
              role: UserRole.parent, // Default to parent role on error
              childrenIds: [],
              createdAt: DateTime.now(), // Use current time as fallback
              additionalInfo: { 
                'error_from_firestore_parsing': true, 
                'error_description': typeError.toString(),
              },
            );
          } catch (parseError) { // Catch other parsing errors
            debugPrint('Error parsing Firestore data: $parseError');
            _currentUser = _createErrorRecoveryUser(firebaseUser.uid, firebaseUser.email, firebaseUser.displayName, 'Parse error: $parseError');
          }
          
          // Ensure additionalInfo is never null (this will now run even after a TypeError if _currentUser is set)
          if (_currentUser!.additionalInfo == null) {
            _currentUser = _currentUser!.copyWith(additionalInfo: {});
            debugPrint('Fixed null additionalInfo for user ${firebaseUser.uid}');
          }
          
          // Check for role inconsistencies and fix if needed
          bool needsFirestoreUpdate = false;
          UserRole correctedRole = _currentUser?.role ?? UserRole.parent; // Default to parent
          
          if (roleString == 'therapist' && correctedRole != UserRole.therapist) {
            correctedRole = UserRole.therapist;
            needsFirestoreUpdate = true;
            debugPrint('Role inconsistency (roleString): Setting to therapist. Current: ${correctedRole}');
          } else if (isTherapistFlag == true && correctedRole != UserRole.therapist) {
            correctedRole = UserRole.therapist;
            needsFirestoreUpdate = true;
            debugPrint('Role inconsistency (isTherapistFlag): Setting to therapist. Current: ${correctedRole}');
          } else if (roleString == 'parent' && correctedRole != UserRole.parent) {
            correctedRole = UserRole.parent;
            needsFirestoreUpdate = true;
            debugPrint('Role inconsistency (roleString): Setting to parent. Current: ${correctedRole}');
          } else if (isTherapistFlag == false && correctedRole != UserRole.parent && roleString != 'therapist') {
            correctedRole = UserRole.parent;
            needsFirestoreUpdate = true;
            debugPrint('Role inconsistency (isTherapistFlag): Setting to parent. Current: ${correctedRole}');
          }
          
          // Update the local user object with the corrected role
          if (needsFirestoreUpdate) {
            _currentUser = _currentUser!.copyWith(role: correctedRole);
            
            // Update Firestore with the corrected role for consistency
            await _firestore.collection('users').doc(firebaseUser.uid).set(
              {'role': correctedRole.toString().split('.').last},
              SetOptions(merge: true),
            );
            debugPrint('Corrected user role in Firestore to: ${correctedRole}');
          }
        }
      } else {
        // If the user is authenticated with Firebase but has no Firestore document,
        // it might be a new registration that's still in progress
        debugPrint('User document not found in Firestore for authenticated user ${firebaseUser.uid}.');
        
        // Don't automatically sign out - let the registration process complete
        // Instead, create a temporary user object
        _currentUser = _createErrorRecoveryUser(firebaseUser.uid, firebaseUser.email, firebaseUser.displayName, 'User document not found - registration may be in progress');
        
        // Try to create the user document if it doesn't exist
        try {
          final newUser = AppUser(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ?? 'User',
            role: UserRole.parent, // Default to parent
            childrenIds: [],
            createdAt: DateTime.now(),
            additionalInfo: {
              'onboardingCompleted': false,
              'autoCreated': true,
            },
          );
          
          await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toFirestore());
          _currentUser = newUser;
          debugPrint('Auto-created user document for ${firebaseUser.uid}');
        } catch (e) {
          debugPrint('Failed to auto-create user document: $e');
          // Keep the recovery user object
        }
      }
    } catch (e) {
      debugPrint('Error fetching/creating user data: $e');
      // Create a local-only user object to prevent app from getting stuck
      _currentUser = _createErrorRecoveryUser(firebaseUser.uid, firebaseUser.email, firebaseUser.displayName, e.toString());
    }
    
    notifyListeners();
  }
  
  /// Sign in with email and password
  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    int retryAttempts = 3; // Allow up to 3 retry attempts
    Object? lastException;
    
    for (int attempt = 0; attempt < retryAttempts; attempt++) {
      try {
        _setLoading(true);
        
        // Log retry attempts if not the first try
        if (attempt > 0) {
          debugPrint('Retrying login (attempt ${attempt + 1}/$retryAttempts)');
        }
        
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (userCredential.user != null) {
          // User data will be loaded by the auth state listener, but let's refresh to be sure
          await refreshUserData(); // Explicitly refresh user data
          return _currentUser;
        }
      } on TypeError catch (e) { // Specific catch for TypeError
        lastException = e;
        debugPrint('Handled TypeError during login, possibly TTS related: $e');
        // If Firebase auth was successful, try to return current user and continue
        if (_auth.currentUser != null) {
          // We already successfully authenticated, just return the current user
          // and suppress this specific type error from disrupting the login flow.
          return _currentUser; 
        }
        rethrow; // If auth was not successful, rethrow the error
      } catch (e) { // General catch for other exceptions
        lastException = e;
        debugPrint('Error signing in (attempt ${attempt + 1}): $e');
        
        // Check if it's an SSL error or network-related error that might resolve with a retry
        if (e.toString().contains('SSL') || 
            e.toString().contains('network') ||
            e.toString().contains('connection') ||
            e.toString().contains('timeout')) {
          // Wait a bit before retrying (exponential backoff)
          final waitTime = Duration(milliseconds: 500 * (attempt + 1));
          debugPrint('Possible SSL/network error, waiting ${waitTime.inMilliseconds}ms before retry');
          await Future.delayed(waitTime);
          continue; // Try again
        } else {
          // For other errors, don't retry
          rethrow;
        }
      } finally {
        _setLoading(false);
      }
    }
    
    if (lastException != null) {
      debugPrint('Login error: $lastException');
      throw lastException;
    }
    return null;
  }
  
  /// Register with email, password, and other details
  Future<AppUser?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    if (_disposed) {
      debugPrint('Warning: Attempted to register on disposed AuthService');
      return null;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Ensure Firestore is properly initialized
      if (_firestore.app.name.isEmpty) {
        debugPrint('Firestore not properly initialized, reinitializing...');
        // Reinitialize Firestore if needed
        await Firebase.initializeApp();
      }
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final firebaseUser = credential.user;
      
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(name);
        
        // Create an AppUser instance
        final newUser = AppUser(
          id: firebaseUser.uid,
          email: email,
          name: name,
          role: role,
          childrenIds: [],
          createdAt: DateTime.now(),
          additionalInfo: {
            'onboardingCompleted': false,
          },
        );
        
        try {
          // Save user to Firestore with retry logic
          int retryCount = 0;
          const maxRetries = 3;
          
          while (retryCount < maxRetries) {
            try {
              await _firestore.collection('users').doc(newUser.id).set(newUser.toFirestore());
              debugPrint('User document created successfully in Firestore');
              break;
            } catch (firestoreError) {
              retryCount++;
              debugPrint('Firestore error (attempt $retryCount/$maxRetries): $firestoreError');
              
              if (firestoreError.toString().contains('terminated') || 
                  firestoreError.toString().contains('client')) {
                // Reinitialize Firestore if client was terminated
                debugPrint('Reinitializing Firestore client...');
                await _firestore.terminate();
                await Future.delayed(Duration(milliseconds: 500));
                // Firestore will be reinitialized on next use
                continue;
              }
              
              if (retryCount >= maxRetries) {
                throw firestoreError;
              }
              
              // Wait before retry
              await Future.delayed(Duration(milliseconds: 1000 * retryCount));
            }
          }
          
          _currentUser = newUser;
          notifyListeners();
          return _currentUser;
          
        } on TypeError catch (e) {
          debugPrint('Handled TypeError during registration, possibly TTS related: $e');
          // If we successfully created the user document, return the user
          // despite the TTS-related TypeError
          if (_currentUser != null) {
            return _currentUser;
          }
          rethrow;
        } catch (firestoreError) {
          debugPrint('Firestore error during registration: $firestoreError');
          // If Firestore fails, we still have a valid Firebase Auth user
          // Create a local user object and let the auth state listener handle it
          _currentUser = newUser;
          notifyListeners();
          return _currentUser;
        }
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      // Handle specific errors if needed
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    
    return null;
  }
  
  /// Update the user profile
  Future<void> updateUserProfile({
    String? name,
    String? profileImage,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      _setLoading(true);
      
      if (_currentUser == null || _auth.currentUser == null) {
        throw Exception('No authenticated user');
      }
      
      final userId = _auth.currentUser!.uid;
      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name;
      if (profileImage != null) updateData['profileImage'] = profileImage;
      if (additionalInfo != null) updateData['additionalInfo'] = additionalInfo;
      
      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updateData);
        
        // Refresh user data
        final userDoc = await _firestore.collection('users').doc(userId).get();
        _currentUser = AppUser.fromFirestore(userDoc);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Link a child to a parent or therapist
  Future<void> linkChildToUser(String childId) async {
    try {
      _setLoading(true);
      
      if (_currentUser == null || _auth.currentUser == null) {
        throw Exception('No authenticated user');
      }
      
      if (_currentUser?.role != UserRole.parent && _currentUser?.role != UserRole.therapist) {
        throw Exception('Only parents and therapists can link to children');
      }
      
      final userId = _auth.currentUser!.uid;
      final childrenIds = List<String>.from(_currentUser?.childrenIds ?? []);
      
      if (!childrenIds.contains(childId)) {
        childrenIds.add(childId);
        
        await _firestore.collection('users').doc(userId).update({
          'childrenIds': childrenIds,
        });
        
        // Refresh user data
        final userDoc = await _firestore.collection('users').doc(userId).get();
        _currentUser = AppUser.fromFirestore(userDoc);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error linking child: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Sign out the current user
  Future<void> signOut() async {
    if (_disposed) {
      debugPrint('Warning: Attempted to sign out on disposed AuthService');
      return;
    }
    
    try {
      _setLoading(true);
      
      // Clear current user before signout to prevent UI confusion
      _currentUser = null;
      notifyListeners();
      
      // Sign out from Firebase - wrap in try/catch to handle potential errors
      try {
        // Sign out from Firebase Auth first
        await _auth.signOut();
        debugPrint('Firebase Auth signOut successful');
        
        // Only terminate Firestore if we're completely shutting down the app
        // For regular sign out, just clear the current user
        // This prevents the "client terminated" error during registration
        
      } catch (e) {
        debugPrint('Firebase signOut error (continuing): $e');
        // Continue with sign out flow even if Firebase operation fails
      }
      
      // Force navigation to login screen here if needed
      // This ensures we always navigate away even if there are Firebase errors
      
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Create test accounts for demo purposes
  Future<bool> createTestAccounts() async {
    try {
      _setLoading(true);
      
      // Create parent test account
      final parentEmail = 'parent_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final parentPassword = 'Test123!';
      final parent = await registerWithEmailAndPassword(
        email: parentEmail,
        password: parentPassword,
        name: 'Test Parent',
        role: UserRole.parent,
      );
      
      debugPrint('Created test parent account: $parentEmail (password: $parentPassword)');
      
      // Create therapist test account
      final therapistEmail = 'therapist_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final therapistPassword = 'Test123!';
      final therapist = await registerWithEmailAndPassword(
        email: therapistEmail,
        password: therapistPassword,
        name: 'Test Therapist',
        role: UserRole.therapist,
      );
      
      debugPrint('Created test therapist account: $therapistEmail (password: $therapistPassword)');
      
      // Create a test child linked to the parent
      if (parent != null) {
        final childData = {
          'name': 'Test Child',
          'age': 8,
          'gender': 'Other',
          'parentId': parent.id,
          'therapistId': therapist?.id,
          'additionalInfo': {
            'favorite_color': 'Blue',
            'likes': ['Drawing', 'Reading', 'Animals'],
            'dislikes': ['Loud noises', 'Vegetables'],
          },
        };
        
        // Add child to Firestore
        final childRef = await _firestore.collection('children').add(childData);
        
        // Link child to parent
        if (parent.id.isNotEmpty) {
          await _firestore.collection('users').doc(parent.id).update({
            'childrenIds': FieldValue.arrayUnion([childRef.id]),
          });
          
          debugPrint('Created test child: ${childData['name']} and linked to parent');
        }
        
        // Link child to therapist if available
        if (therapist != null && therapist.id.isNotEmpty) {
          await _firestore.collection('users').doc(therapist.id).update({
            'childrenIds': FieldValue.arrayUnion([childRef.id]),
          });
          
          debugPrint('Linked test child to therapist');
        }
      }
      
      // Sign in as the parent so they can use the app immediately
      await signInWithEmailAndPassword(parentEmail, parentPassword);
      
      debugPrint('Test accounts created and signed in as parent');
      return true;
    } catch (e) {
      debugPrint('Error creating test accounts: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Update loading state and notify listeners
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  /// Refreshes the current user data from Firestore
  /// Useful when we need to ensure we have the most current data
  Future<AppUser?> refreshUserData() async {
    try {
      if (_auth.currentUser == null) {
        return null;
      }
      
      // Get fresh user data from Firestore
      final userDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final role = data['role'] as String?;
        
        // Create user object from Firestore data
        final user = AppUser.fromFirestore(userDoc);
        
        // Verify role is correctly set
        if (role == 'therapist' && user.role != UserRole.therapist) {
          debugPrint('Role mismatch detected during refresh: Firestore says therapist but parsed as ${user.role}');
          
          // Force update the role in Firestore
          await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
            'role': 'therapist',
          });
          
          // Return with the correct role
          _currentUser = user.copyWith(role: UserRole.therapist);
        } else {
          _currentUser = user;
        }
        
        notifyListeners();
        return _currentUser;
      }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
    }
    
    return _currentUser;
  }
  
  /// Returns a default name based on user role
  String _getDefaultNameByRole(UserRole role) {
    switch (role) {
      case UserRole.therapist:
        return 'Therapist';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.parent:
      default:
        return 'Parent User';
    }
  }
  
  /// Properly terminate Firestore when app is shutting down
  Future<void> terminateFirestore() async {
    if (_disposed) return;
    
    try {
      await _firestore.terminate();
      await _firestore.clearPersistence();
      debugPrint('Firestore properly terminated');
    } catch (e) {
      debugPrint('Error terminating Firestore: $e');
    }
  }
}