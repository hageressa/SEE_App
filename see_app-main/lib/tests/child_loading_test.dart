import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/screens/parent/parent_dashboard.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/services/database_service.dart';

/// A test utility class for testing the child loading fallback mechanism
/// This class provides methods to programmatically:
/// 1. Register a new parent user
/// 2. Create a child with the parent's ID in additionalInfo.parentId
/// 3. Navigate to the parent dashboard
/// 4. Verify the child appears and is linked correctly
class ChildLoadingTestUtil {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;
  final DatabaseService _databaseService;
  final BuildContext _context;

  ChildLoadingTestUtil({
    required AuthService authService,
    required DatabaseService databaseService,
    required BuildContext context,
  })  : _authService = authService,
        _databaseService = databaseService,
        _context = context;

  /// Run the complete test flow
  Future<void> runTest() async {
    try {
      // Step 1: Register a new parent user
      debugPrint('🧪 STEP 1: Registering new parent user...');
      final AppUser parent = await _registerNewParent();
      debugPrint('✅ Parent user created: ${parent.name} (${parent.id})');

      // Step 2: Create a child with parent's ID in additionalInfo
      debugPrint('🧪 STEP 2: Creating child during simulated onboarding...');
      final Child child = await _createChildDuringOnboarding(parent.id);
      debugPrint('✅ Child created: ${child.name} (${child.id})');
      
      // Verify child has parentId in additionalInfo
      debugPrint('📋 Verifying child additionalInfo...');
      final parentId = child.additionalInfo?['parentId'];
      if (parentId == parent.id) {
        debugPrint('✅ Child has correct parentId in additionalInfo: $parentId');
      } else {
        debugPrint('❌ Child has wrong parentId: $parentId (expected: ${parent.id})');
      }

      // Step 3: Check parent's childrenIds array (should be empty initially)
      debugPrint('🧪 STEP 3: Checking parent\'s childrenIds array...');
      final parentDoc = await _firestore.collection('users').doc(parent.id).get();
      final parentData = parentDoc.data();
      final childrenIds = List<String>.from(parentData?['childrenIds'] ?? []);
      
      if (childrenIds.isEmpty) {
        debugPrint('✅ Parent has empty childrenIds array as expected');
      } else {
        debugPrint('⚠️ Parent already has childrenIds: $childrenIds');
      }

      // Step 4: Navigate to parent dashboard
      debugPrint('🧪 STEP 4: Navigating to parent dashboard...');
      await _navigateToParentDashboard(parent);
      
      // Step 5: Wait for fallback mechanism to run (added delay)
      debugPrint('🧪 STEP 5: Waiting for fallback mechanism to run...');
      await Future.delayed(const Duration(seconds: 3));
      
      // Step 6: Verify parent now has child in childrenIds
      debugPrint('🧪 STEP 6: Verifying parent now has child in childrenIds...');
      final updatedParentDoc = await _firestore.collection('users').doc(parent.id).get();
      final updatedParentData = updatedParentDoc.data();
      final updatedChildrenIds = List<String>.from(updatedParentData?['childrenIds'] ?? []);
      
      if (updatedChildrenIds.contains(child.id)) {
        debugPrint('✅ TEST PASSED: Child ID ${child.id} was found in parent\'s childrenIds array!');
        debugPrint('✅ Fallback mechanism successfully linked the child to the parent');
      } else {
        debugPrint('❌ TEST FAILED: Child ID ${child.id} not found in parent\'s childrenIds');
        debugPrint('❌ Fallback mechanism did not link the child to the parent');
      }
      
    } catch (e) {
      debugPrint('❌ Test failed with error: $e');
    }
  }

  /// Register a new parent user with a random email
  Future<AppUser> _registerNewParent() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'test_parent_$timestamp@example.com';
    final password = 'Test1234!';
    final name = 'Test Parent $timestamp';

    // Create user with Firebase Auth
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final userId = userCredential.user!.uid;
    
    // Create user in Firestore
    final parent = AppUser(
      id: userId,
      email: email,
      name: name,
      role: UserRole.parent,
      childrenIds: [], // Start with empty childrenIds array
      createdAt: DateTime.now(),
    );
    
    await _databaseService.createOrUpdateUser(parent);
    
    return parent;
  }

  /// Create a child during simulated onboarding
  /// This mimics what happens in the onboarding process
  Future<Child> _createChildDuringOnboarding(String parentId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final name = 'Test Child $timestamp';
    final age = 7;
    
    // Create child with parentId in additionalInfo
    final child = await _databaseService.createChild(
      name: name,
      age: age,
      additionalInfo: {
        'gender': 'Not specified',
        'additionalInfo': 'Created during test',
        'parentId': parentId, // This is the key field for our fallback mechanism
      },
    );
    
    return child;
  }

  /// Navigate to the parent dashboard to trigger the fallback mechanism
  Future<void> _navigateToParentDashboard(AppUser parent) async {
    // Sign in with the test user's credentials to set it as current user
    // Note: We already have the user in Firebase Auth from the registration step
    final email = parent.email;
    final password = 'Test1234!'; // The password we used in _registerNewParent
    
    try {
      // Sign in to make this the current user
      await _authService.signInWithEmailAndPassword(email, password);
      debugPrint('✅ Signed in as test parent user: ${parent.email}');
    } catch (e) {
      debugPrint('❌ Error signing in as test user: $e');
    }
    
    // Navigate to parent dashboard
    Navigator.of(_context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const ParentDashboard(
          suppressNoChildrenMessage: true,
        ),
      ),
    );
  }
}

/// Example of how to use the test utility:
///
/// ```dart
/// void main() {
///   runApp(MyApp());
/// }
///
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MultiProvider(
///       providers: [
///         Provider<AuthService>(create: (_) => AuthService()),
///         Provider<DatabaseService>(create: (_) => DatabaseService()),
///       ],
///       child: MaterialApp(
///         home: TestRunner(),
///       ),
///     );
///   }
/// }
///
/// class TestRunner extends StatefulWidget {
///   @override
///   _TestRunnerState createState() => _TestRunnerState();
/// }
///
/// class _TestRunnerState extends State<TestRunner> {
///   @override
///   void initState() {
///     super.initState();
///     _runTest();
///   }
///
///   Future<void> _runTest() async {
///     final authService = Provider.of<AuthService>(context, listen: false);
///     final dbService = Provider.of<DatabaseService>(context, listen: false);
///
///     final testUtil = ChildLoadingTestUtil(
///       authService: authService,
///       databaseService: dbService,
///       context: context,
///     );
///
///     await testUtil.runTest();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: Text('Child Loading Test')),
///       body: Center(child: Text('Running child loading test...')),
///     );
///   }
/// }