import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/models/mission.dart';
import 'package:see_app/models/difficulty_level.dart';
import 'package:see_app/models/message.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/screens/login_screen.dart';
import 'package:see_app/screens/therapist/components/tabs/analytics_tab.dart';
import 'package:see_app/screens/therapist/components/tabs/clients_tab.dart';
import 'package:see_app/screens/therapist/components/tabs/messages_tab.dart';
import 'package:see_app/screens/therapist/components/tabs/overview_tab.dart';
import 'package:see_app/screens/therapist/components/ui/therapist_app_bar.dart';
import 'package:see_app/screens/therapist/components/ui/therapist_bottom_nav_bar.dart';
import 'package:see_app/screens/therapist/components/ui/therapist_drawer.dart';
import 'package:see_app/screens/therapist/components/ui/therapist_fab.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/services/gemini_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:see_app/widgets/session_preparation_dashboard.dart';
import 'package:see_app/widgets/custom_mission_creator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:see_app/screens/messaging/conversations_screen.dart';
import 'package:see_app/screens/appointments/appointments_screen.dart';
import 'package:see_app/screens/messaging/message_screen.dart';

class RedesignedTherapistDashboard extends StatefulWidget {
  const RedesignedTherapistDashboard({Key? key}) : super(key: key);

  @override
  State<RedesignedTherapistDashboard> createState() => _RedesignedTherapistDashboardState();
}

class _RedesignedTherapistDashboardState extends State<RedesignedTherapistDashboard> with SingleTickerProviderStateMixin {
  // Tab controller
  late TabController _tabController;
  int _currentTabIndex = 0;
  
  // Subscriptions
  StreamSubscription? _patientSubscription;
  StreamSubscription? _alertsSubscription;
  StreamSubscription? _conversationsSubscription;
  StreamSubscription? _notificationsSubscription;
  
  // User and service references
  late AuthService _authService;
  late DatabaseService _databaseService;
  late GeminiService _geminiService;
  AppUser? _currentUser;
  
  // Data
  List<Child> _patients = [];
  List<Map<String, dynamic>> _upcomingSessions = [];
  List<dynamic> _recentAlerts = [];
  List<Conversation> _conversations = [];
  
  // State
  bool _isLoading = true;
  bool _isSessionPreparationVisible = false;
  bool _isMissionCreatorVisible = false;
  Child? _selectedPatientForPreparation;
  Map<String, dynamic>? _selectedSession;
  
  // Controller variables
  final PageController _pageController = PageController();
  
  // Current page index
  int _currentPageIndex = 0;
  
  @override
  void initState() {
    super.initState();
    
    // Get and store service references
    _authService = Provider.of<AuthService>(context, listen: false);
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    
    // Add proper initialization for GeminiService
    try {
      _geminiService = Provider.of<GeminiService>(context, listen: false);
    } catch (e) {
      debugPrint('Error initializing GeminiService: $e');
      // Create a default instance as fallback
      _geminiService = GeminiService();
    }
    
    // Set the isLoading flag to true immediately
    setState(() {
      _isLoading = true;
    });
    
    // Load user and verify role
    Future.delayed(Duration.zero, () async {
      try {
        // Add a small delay for the loading screen to properly display
        await Future.delayed(const Duration(milliseconds: 500));
        
        final user = _authService.currentUser;
        
        if (user == null) {
          // Handle no user logged in
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false, // Clear all routes
            );
          }
          return;
        }
        
        // Set current user immediately to prevent flicker
        setState(() {
          _currentUser = user;
          // Keep _isLoading true during role verification
        });
        
        // Get additional Firestore data about user role
        final firestoreData = await FirebaseFirestore.instance.collection('users').doc(user.id).get();
        
        // Check if user is a therapist using multiple criteria
        bool isTherapist = false;
        
        // Print debugging info
        debugPrint('User role check - User model role: ${user.role}');
        if (firestoreData.exists) {
          final data = firestoreData.data();
          debugPrint('User role check - Firestore role: ${data?['role']}');
          debugPrint('User role check - isTherapist flag: ${data?['isTherapist']}');
          debugPrint('User role check - additionalInfo.isTherapist: ${data?['additionalInfo']?['isTherapist']}');
        }
        
        // First try to correct the user model directly
        if (firestoreData.exists) {
          final data = firestoreData.data();
          final roleInFirestore = data?['role'];
          final isTherapistFlag = data?['isTherapist'];
          
          // Compare role in Firestore with role in user model
          if ((roleInFirestore == 'therapist' || isTherapistFlag == true) && 
              user.role != UserRole.therapist) {
            // This is a critical issue - the roles don't match
            debugPrint('CRITICAL: Role mismatch between Firestore and user model!');
            
            // Force role update in both locations
            try {
              // 1. Update Firestore document with clear therapist role
              await FirebaseFirestore.instance.collection('users').doc(user.id).set({
                'role': 'therapist',
                'roleString': 'therapist', 
                'roleValue': 'therapist',
                'roleEnum': 'therapist',
                'isTherapist': true,
                'userRole': 'therapist',
              }, SetOptions(merge: true));
              
              // 2. Refresh auth service data
              await _authService.refreshUserData();
              
              // 3. Get the refreshed user
              final refreshedUser = _authService.currentUser;
              
              // 4. Update local user reference 
              if (refreshedUser != null) {
                setState(() {
                  _currentUser = refreshedUser;
                  // Keep _isLoading true until all checks are done
                });
                
                // Check if the refresh fixed the issue
                if (refreshedUser.role == UserRole.therapist) {
                  debugPrint('Successfully fixed role mismatch via refreshUserData');
                  isTherapist = true;
                }
              }
            } catch (e) {
              debugPrint('Error trying to fix role mismatch: $e');
            }
          }
        }
        
        // Check multiple sources to determine if user is a therapist
        
        // First check the role enum
        if (user.role == UserRole.therapist) {
          isTherapist = true;
          debugPrint('User identified as therapist via UserRole enum');
        }
        // Check additionalInfo fields which might indicate a therapist
        if (!isTherapist && _currentUser?.additionalInfo != null) {
          final additionalInfo = _currentUser!.additionalInfo!;
          isTherapist = additionalInfo['isTherapist'] == true || 
                        additionalInfo['userRole'] == 'therapist' ||
                        additionalInfo['roleType'] == 'therapist' ||
                        additionalInfo['userType'] == 'therapist';
          
          if (isTherapist) {
            debugPrint('User identified as therapist via additionalInfo fields');
          }
        }
        // Also check the Firestore data directly as a last resort
        if (!isTherapist && firestoreData.exists) {
          final data = firestoreData.data();
          isTherapist = data?['role'] == 'therapist' || 
                        data?['roleString'] == 'therapist' ||
                        data?['roleValue'] == 'therapist' ||
                        data?['roleEnum'] == 'therapist' ||
                        data?['isTherapist'] == true ||
                        data?['userRole'] == 'therapist';
          
          if (isTherapist) {
            debugPrint('User identified as therapist via direct Firestore fields');
          }
        }
        
        // Extra check for onboarding-related data
        if (!isTherapist && firestoreData.exists) {
          final data = firestoreData.data();
          final bool hasSpecialty = data?['additionalInfo']?['specialty'] != null;
          final bool hasTherapistFields = data?['additionalInfo']?['clientAgePreferences'] != null ||
                                         data?['additionalInfo']?['licenseNumber'] != null;
          
          if (hasSpecialty || hasTherapistFields) {
            debugPrint('User appears to be a therapist based on professional data fields');
            isTherapist = true;
            
            // Auto-correct the role in the database
            try {
              await FirebaseFirestore.instance.collection('users').doc(user.id).update({
                'role': 'therapist',
                'isTherapist': true,
              });
              debugPrint('Auto-corrected therapist role in database');
            } catch (e) {
              debugPrint('Failed to auto-correct role: $e');
            }
          }
        }
        
        if (!isTherapist) {
          // Set loading to false before showing error
          setState(() {
            _isLoading = false;
          });
          
        // Handle role mismatch - redirect to login
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: Invalid user role. This dashboard is for therapists only.\nYour role: ${user.role}'),
          backgroundColor: Colors.red,
        ));
        _handleLogout();
        return;
        }
        
        // If we're here, role is valid, so load data
        await _loadData();
      } catch (e) {
        // Handle any errors
        debugPrint('Error verifying user role: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error verifying account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ));
    }
      }
    });
    
    // Initialize tab controller
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      // Update state when tab changes
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    super.dispose();
  }
  
  // Handle tab changes
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }
  
  // Load all necessary data
  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Get current user data
      final user = _authService.currentUser;
      if (user != null) {
        // Verify therapist registration is complete
        bool isRegistrationComplete = false;
        try {
          final userDoc = await _databaseService.getUser(user.id);
          isRegistrationComplete = userDoc?.additionalInfo?['isTherapistRegistrationComplete'] == true;
          
          if (!isRegistrationComplete && mounted) {
            // Show warning but continue loading
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Your therapist profile is not fully set up. Some features may be limited.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ));
          }
        } catch (e) {
          debugPrint('Error checking therapist registration: $e');
          // Continue loading even if this check fails
        }
        
        // Load patients
        final patients = await _databaseService.getPatientsByTherapistId(user.id);
        
        // Load upcoming sessions
        final sessions = await _databaseService.getUpcomingSessionsByTherapistId(user.id);
        
        // Load alerts
        final alerts = await _databaseService.getRecentAlertsByTherapistId(user.id);
        
        // Load conversations
        final conversations = await _databaseService.getConversationsByUserId(user.id);
        
        if (mounted) {
          setState(() {
            _currentUser = user;
            _patients = patients;
            _upcomingSessions = sessions;
            _recentAlerts = alerts;
            _conversations = conversations;
            _isLoading = false;
          });
        }
      } else {
        // No user logged in, redirect to login
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false, // Remove all previous routes
          );
        }
      }
    } catch (e) {
      // Handle errors
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }
  
  void _handleLogout() async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });
      
      // Cancel any active subscriptions
      _patientSubscription?.cancel();
      _alertsSubscription?.cancel();
      _conversationsSubscription?.cancel();
      _notificationsSubscription?.cancel();
      
      // Terminate Firebase connections
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.terminate();
      } catch (e) {
        debugPrint('Error terminating Firestore: $e');
        // Continue with logout even if there's an error
      }
      
      // Sign out from Firebase
      await _authService.signOut();
      
      // Add a small delay to let Firebase connections close
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Reset loading state even if not mounted (failsafe)
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      // Clear the ENTIRE navigation stack and go to login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      debugPrint('Error during logout: $e');
      
      if (!mounted) return;
      
      // Always ensure loading state is reset
      setState(() {
        _isLoading = false;
      });
      
      // Show error but still try to navigate to login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
      
      // Force navigation to login screen even if there was an error
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
  
  void _showSettingsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSettingsPanel(),
    );
  }
  
  Widget _buildSettingsPanel() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme_utils.SeeAppTheme.darkSecondaryBackground : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSettingsSection('Account'),
                const SizedBox(height: 8),
                _buildSettingItem(
                  icon: Icons.person,
                  title: 'Edit Profile',
                  subtitle: 'Change your personal information',
                  onTap: () => _showEditProfileDialog(),
                ),
                _buildSettingItem(
                  icon: Icons.lock,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: () => _showChangePasswordDialog(),
                ),
                _buildSettingItem(
                  icon: Icons.badge,
                  title: 'Professional Information',
                  subtitle: 'Update your credentials and specialties',
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                _buildSettingsSection('Preferences'),
                const SizedBox(height: 8),
                _buildSettingToggle(
                  title: 'Dark Mode',
                  value: isDark,
                  onChanged: (value) {
                    // This would be handled by your theme provider
                  },
                ),
                _buildSettingToggle(
                  title: 'Notification Sounds',
                  value: true,
                  onChanged: (value) {},
                ),
                _buildSettingToggle(
                  title: 'Email Notifications',
                  value: true,
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                _buildSettingsSection('Help & Support'),
                const SizedBox(height: 8),
                _buildSettingItem(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  subtitle: 'Get help using the app',
                  onTap: () {},
                ),
                _buildSettingItem(
                  icon: Icons.feedback,
                  title: 'Send Feedback',
                  subtitle: 'Help us improve the app',
                  onTap: () {},
                ),
                _buildSettingItem(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  subtitle: 'View our privacy policy',
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                _buildSettingsSection('Session'),
                const SizedBox(height: 8),
                _buildSettingItem(
                  icon: Icons.logout,
                  title: 'Log Out',
                  subtitle: 'Sign out of your account',
                  onTap: () {
                    Navigator.pop(context);
                    _handleLogout();
                  },
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'SEE App v1.2.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 300.ms);
  }
  
  Widget _buildSettingsSection(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: theme_utils.SeeAppTheme.primaryColor,
      ),
    );
  }
  
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
        child: Icon(icon, color: theme_utils.SeeAppTheme.primaryColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
    );
  }
  
  Widget _buildSettingToggle({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: theme_utils.SeeAppTheme.primaryColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
    );
  }
  
  void _showEditProfileDialog() {
    // Logic to show edit profile dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('Edit profile dialog would appear here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showChangePasswordDialog() {
    // Logic to show change password dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('Change password dialog would appear here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _prepareForSession(Map<String, dynamic> session) {
    final childId = session['patientId'] as String?;
    if (childId != null) {
      final child = _patients.firstWhere(
        (p) => p.id == childId,
        orElse: () => Child(
          id: '',
          name: 'Unknown',
          age: 0,
          gender: 'Unknown',
          parentId: '',
          concerns: [],
        ),
      );
      
      setState(() {
        _selectedPatientForPreparation = child;
        _selectedSession = session;
        _isSessionPreparationVisible = true;
      });
    }
  }
  
  void _closeSessionPreparation() {
    setState(() {
      _isSessionPreparationVisible = false;
      _selectedPatientForPreparation = null;
      _selectedSession = null;
    });
  }
  
  void _showCreateMissionPanel() {
    setState(() {
      _isMissionCreatorVisible = true;
    });
  }
  
  void _closeCreateMissionPanel() {
    setState(() {
      _isMissionCreatorVisible = false;
    });
  }
  
  void _onMissionCreated(Mission mission) {
    _closeCreateMissionPanel();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Mission created successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _openConversation(String conversationId, BuildContext context) async {
    final currentUserId = _authService.currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Current user not found.')),
      );
      return;
    }

    try {
      final conversation = await _databaseService.getConversation(conversationId);
      if (conversation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Conversation not found.')),
        );
        return;
      }

      final otherUserId = conversation.participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );

      if (otherUserId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Other participant not found.')),
        );
        return;
      }
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MessageScreen(
            conversationId: conversationId,
            otherUserId: otherUserId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening chat: ${e.toString()}')),
      );
    }
  }
  
  void _createNewMessage(BuildContext context) {
    // Logic to create new message
  }
  
  void _viewAlertDetails(dynamic alert) {
    // Logic to view alert details
  }
  
  @override
  Widget build(BuildContext context) {
    // Always check for loading state first - this ensures we show the loading indicator 
    // until the role verification and correction completes
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Therapist Dashboard'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Loading dashboard...',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Defensive: If currentUser is not set, show error
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Therapist Dashboard'),
        ),
        body: const Center(
          child: Text(
            'Error: User data is missing. Please log in again.',
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }

    // Defensive: If user role is not therapist, show error
    if (_currentUser?.role != UserRole.therapist) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Therapist Dashboard'),
        ),
        body: const Center(
          child: Text(
            'Error: Invalid user role. This dashboard is for therapists only.',
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }

    // Defensive: Catch any other errors in the build
    try {
    return Scaffold(
      appBar: TherapistAppBar(
        title: _getTabTitle(),
        currentUser: _currentUser,
        onRefresh: _loadData,
        onOpenSettings: _showSettingsPanel,
        onSearch: _currentTabIndex == 1 || _currentTabIndex == 3 ? () {} : null,
        showSearchAction: _currentTabIndex == 1 || _currentTabIndex == 3,
      ),
      drawer: TherapistDrawer(
        currentUser: _currentUser,
        onLogout: _handleLogout,
        onNavigateToClients: () {
          setState(() => _currentTabIndex = 1);
          _tabController.animateTo(1);
        },
        onNavigateToAnalytics: () {
          setState(() => _currentTabIndex = 2);
          _tabController.animateTo(2);
        },
        onNavigateToResources: () {
          // Show message for unimplemented features instead of navigating to black screen
          Navigator.pop(context); // Close drawer
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resources feature coming soon')),
          );
        },
        onNavigateToReports: () {
          // Show message for unimplemented features instead of navigating to black screen
          Navigator.pop(context); // Close drawer
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reports feature coming soon')),
          );
        },
        onNavigateToSchedule: () {
          // Show message for unimplemented features instead of navigating to black screen
          Navigator.pop(context); // Close drawer
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule feature coming soon')),
          );
        },
        onNavigateToSettings: () {
          Navigator.pop(context); // Close drawer
          _showSettingsPanel();
        },
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            physics: _isSessionPreparationVisible || _isMissionCreatorVisible
                ? const NeverScrollableScrollPhysics()
                : null,
            children: [
              // Overview Tab
              OverviewTab(
                patients: _patients,
                upcomingSessions: _upcomingSessions,
                recentAlerts: _recentAlerts,
                isLoading: _isLoading,
                onRefresh: _loadData,
                onViewPatientDetails: (patient) {},
                onPrepareForSession: _prepareForSession,
                onViewAlertDetails: _viewAlertDetails,
                onCreateRecommendation: () {},
                onCreateMission: _showCreateMissionPanel,
              ),
              
              // Clients Tab
              ClientsTab(
                patients: _patients,
                isLoading: _isLoading,
                onRefresh: _loadData,
                onViewPatientDetails: (child) {
                  _showPatientDetailsDialog(child);
                },
                onPatientsUpdated: (updatedPatients) {
                  setState(() {
                    _patients = updatedPatients;
                  });
                },
                onAddClient: () {
                  // Show add client dialog or navigate to add client page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add client functionality coming soon')),
                  );
                },
                therapistId: _currentUser?.id ?? '',
              ),
              
              // Analytics Tab
              AnalyticsTab(
                patients: _patients,
                isLoading: _isLoading,
                onRefresh: _loadData,
              ),
              
              // Messages Tab
              MessagesTab(
                conversations: _conversations,
                patients: _patients,
                isLoading: _isLoading,
                onOpenConversation: _openConversation,
                onCreateNewMessage: _createNewMessage,
              ),
            ],
          ),
          
          // Session Preparation Overlay
          if (_isSessionPreparationVisible && _selectedPatientForPreparation != null)
            Positioned.fill(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SessionPreparationDashboard(
                  patient: _selectedPatientForPreparation!,
                  databaseService: _databaseService,
                  sessionDate: DateTime.parse(_selectedSession?['time'] as String? ?? DateTime.now().toIso8601String()),
                  onClose: _closeSessionPreparation,
                ),
              ),
            ),
            
          // Mission Creator Overlay
          if (_isMissionCreatorVisible)
            Positioned.fill(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: CustomMissionCreator(
                  databaseService: _databaseService,
                  patients: _patients,
                  onMissionCreated: _onMissionCreated,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isSessionPreparationVisible || _isMissionCreatorVisible
          ? null
          : TherapistFab(
              currentTabIndex: _currentTabIndex,
              onAddClient: () {
                // Show add client dialog or navigate to add client page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add client functionality coming soon')),
                );
              },
              onCreateRecommendation: () {},
              onCreateMission: _showCreateMissionPanel,
              onSendMessage: () => _createNewMessage(context),
            ),
      bottomNavigationBar: _isSessionPreparationVisible || _isMissionCreatorVisible
          ? null
          : TherapistBottomNavBar(
              currentTabIndex: _currentTabIndex,
              onTabChanged: (index) {
                setState(() {
                  _currentTabIndex = index;
                  _tabController.animateTo(index);
                });
              },
            ),
    );
    } catch (e, stack) {
      debugPrint('Error building dashboard: $e\n$stack');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Therapist Dashboard'),
        ),
        body: Center(
          child: Text(
            'Unexpected error: ${e.toString()}',
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }
  }
  
  String _getTabTitle() {
    switch (_currentTabIndex) {
      case 0:
        return 'Therapist Dashboard';
      case 1:
        return 'Clients';
      case 2:
        return 'Analytics';
      case 3:
        return 'Messages';
      default:
        return 'Therapist Dashboard';
    }
  }
  
  /// Show detailed information about a patient in a dialog
  void _showPatientDetailsDialog(Child child) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Patient: ${child.name}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Age'),
                subtitle: Text('${child.age} years'),
                leading: const Icon(Icons.cake),
              ),
              ListTile(
                title: const Text('Gender'),
                subtitle: Text(child.gender ?? 'Not specified'),
                leading: const Icon(Icons.person),
              ),
              if (child.additionalInfo.containsKey('diagnosis'))
                ListTile(
                  title: const Text('Diagnosis'),
                  subtitle: Text(child.additionalInfo['diagnosis'] as String? ?? 'Not specified'),
                  leading: const Icon(Icons.medical_services),
                ),
              if (child.additionalInfo.containsKey('notes'))
                ListTile(
                  title: const Text('Notes'),
                  subtitle: Text(child.additionalInfo['notes'] as String? ?? 'No notes'),
                  leading: const Icon(Icons.note),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to detailed patient profile when available
            },
            child: const Text('View Full Profile'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
