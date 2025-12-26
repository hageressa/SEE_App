import 'dart:math' as math;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:see_app/models/article.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/models/emotion_data.dart' as emotion_model;
import 'package:see_app/models/message.dart';
import 'package:see_app/models/subscription_plan.dart';
import 'package:see_app/models/suggestion_feedback.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/screens/login_screen.dart';
import 'package:see_app/screens/subscription_screen.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/services/emotion_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:see_app/utils/local_storage_helper.dart';
import 'package:see_app/widgets/visual_emotion_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';

// Import components
import 'components/tabs/dashboard_tab.dart';
import 'components/tabs/home_tab.dart';
import 'components/tabs/messages_tab.dart';
import 'components/tabs/therapists_tab.dart';
import 'components/ui/parent_app_bar.dart';
import 'components/ui/parent_bottom_nav_bar.dart';
import 'components/ui/parent_drawer.dart';
import 'components/ui/parent_fab.dart';
import 'components/ui/add_child_dialog.dart';
import 'package:see_app/screens/messaging/message_screen.dart';
import 'package:see_app/screens/parent/therapist_profile_screen.dart';
import 'package:see_app/screens/parent/components/tabs/settings_tab.dart';
import 'package:see_app/widgets/subscription_banner.dart';

/// A dashboard screen for parents to monitor their children's emotional well-being
/// and interact with therapists and other resources.
class ParentDashboard extends StatefulWidget {
  /// Controls whether to show the "No children profiles found" message
  /// Set to true when navigating from onboarding to prevent the message from showing
  final bool suppressNoChildrenMessage;
  
  const ParentDashboard({
    super.key,
    this.suppressNoChildrenMessage = false,
  });

  @override
  State<ParentDashboard> createState() => ParentDashboardState();
}

/// The state class for the ParentDashboard widget.
/// Manages UI state, handles tab navigation, and loads user-specific data.
class ParentDashboardState extends State<ParentDashboard> with TickerProviderStateMixin {
  // Current article being viewed
  Article? _currentArticle;
  
  // Data sources
  late Future<List<emotion_model.EmotionData>> _emotionDataFuture = Future.value([]);
  late Future<List<emotion_model.DistressAlert>> _alertsFuture = Future.value([]);
  late Future<List<emotion_model.CalmingSuggestion>> _suggestionsFuture = Future.value([]);
  Child? _selectedChild;
  List<Child> _children = []; // Initialize with empty list to prevent LateInitializationError
  
  // UI Controllers
  late TabController _tabController;
  final TextEditingController _contextController = TextEditingController();
  
  // State variables
  String _timeRange = 'week'; // 'day', 'week', 'month'
  bool _isLoading = true;
  String? _loadError;
  int _currentTabIndex = 0;
  bool _isArticleOpen = false; // Track when an article is open
  emotion_model.EmotionType _selectedEmotion = emotion_model.EmotionType.joy;
  double _emotionIntensity = 0.5;
  
  // Subscription state
  bool _hasDevice = false; // Will be false until device is connected
  bool _showEmotionBanner = true;
  bool _showAlertsBanner = true;
  bool _showSuggestionsBanner = true;
  
  // Therapists data
  late Future<List<AppUser>> _therapistsFuture = Future.value([]);
  List<AppUser> _therapists = []; // Add this line
  bool _isLoadingTherapists = false;
  
  // Messages data
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoadingMessages = false;
  
  // Subscription listeners
  StreamSubscription? _emotionSubscription;
  StreamSubscription? _missionSubscription;
  StreamSubscription? _alertsSubscription;
  StreamSubscription? _conversationSubscription;
  StreamSubscription? _suggestionsSubscription;
  
  @override
  void initState() {
    super.initState();
    // Initialize tab controller
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Defer initial data loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDeviceConnection();
      _loadRealData();
      _loadTherapists();
      _loadMessages();
    });
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _contextController.dispose();
    super.dispose();
  }
  
  /// Checks if the SEE device is connected
  void _checkDeviceConnection() async {
    try {
      // In production, query actual device connection status
      // This would use a platform-specific method to check real device connectivity
      final bool deviceConnected = await _queryRealDeviceStatus();
      setState(() {
        _hasDevice = deviceConnected;
      });
    } catch (e) {
      debugPrint('Error checking device connection: $e');
      // Default to true for production in case of connection error
      setState(() => _hasDevice = true);
    }
  }
  
  /// Query the actual device status from the platform
  Future<bool> _queryRealDeviceStatus() async {
    // This would be implemented with platform channels to query real device
    // For now, assume connected in production
    return true;
  }

  /// Loads real conversation data from Firebase
  Future<void> _loadMessages() async {
    if (!mounted) return;
    
    setState(() => _isLoadingMessages = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user == null) {
        setState(() => _isLoadingMessages = false);
        return;
      }
      
      // Get real conversations from database
      await _loadConversationsFromFirebase();
      setState(() => _isLoadingMessages = false);
    } catch (e) {
      debugPrint('Error loading messages: $e');
      
      if (mounted) {
        setState(() => _isLoadingMessages = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading messages: ${e.toString()}'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
  
  /// Handles tab index changes
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }
  
  /// Loads all data for the dashboard
  Future<void> _loadRealData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final userId = authService.currentUser?.id;
      
      if (userId == null || userId.isEmpty) {
        throw Exception('User not logged in');
      }

      // Load children using the primary method
      final children = await databaseService.getChildrenForUser(userId);
      
      // Show no children message if needed
      if (children.isEmpty && !widget.suppressNoChildrenMessage && mounted) {
        _showNoChildrenMessage();
      }

      // Update state with loaded children
      if (mounted) {
        setState(() {
          _children = children;
          _selectedChild = children.isNotEmpty ? children.first : null;
          _isLoading = false;
        });

        // Load child-specific data if we have a selected child
        if (_selectedChild != null) {
          await _loadChildData();
        }
      }
    } catch (e) {
      _handleError('load data', e);
    }
  }

  /// Loads all data specific to the selected child
  Future<void> _loadChildData() async {
    if (_selectedChild == null || !mounted) return;

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final emotionService = Provider.of<EmotionService>(context, listen: false);
      
      // Load emotion data
      _emotionDataFuture = emotionService.getEmotionData(_selectedChild!.id);

      // Listen to real-time updates for emotion data
      _emotionSubscription?.cancel();
      _emotionSubscription = emotionService.streamEmotionData(_selectedChild!.id).listen(
        (data) {
          if (mounted) {
            setState(() {
              _emotionDataFuture = Future.value(data);
            });
          }
        },
        onError: (error) {
          _handleError('stream emotion data', error);
        },
      );
      
      // Load and stream alerts
      _alertsFuture = emotionService.getDistressAlerts(_selectedChild!.id);
      _alertsSubscription?.cancel();
      _alertsSubscription = emotionService.streamDistressAlerts(_selectedChild!.id).listen(
        (alerts) {
          if (mounted) {
            setState(() {
              _alertsFuture = Future.value(alerts);
            });
          }
        },
        onError: (error) {
          _handleError('stream distress alerts', error);
        },
      );
      
      // Load and stream calming suggestions
      _suggestionsFuture = emotionService.getCalmingSuggestions(_selectedChild!.id);
      _suggestionsSubscription?.cancel(); // Cancel previous subscription if exists
      _suggestionsSubscription = emotionService.streamCalmingSuggestions(_selectedChild!.id).listen(
        (suggestions) {
          if (mounted) {
            setState(() {
              _suggestionsFuture = Future.value(suggestions);
            });
          }
        },
        onError: (error) {
          _handleError('stream calming suggestions', error);
        },
      );

      // Load mission data (example - adapt as needed)
      // This part would typically come from a MissionService
      // _missionFuture = missionService.getMissions(_selectedChild!.id);
      
      // After all data is loaded and subscriptions are set up
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _handleError('load child data', e);
    }
  }

  /// Shows a dialog when no children are found
  void _showNoChildrenMessage() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Welcome to SEE!'),
        content: const Text(
          'To get started, let\'s add your child\'s profile. This will help us '
          'personalize the experience and provide better support for your child\'s '
          'emotional development.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addNewChild();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme_utils.SeeAppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Child'),
          ),
        ],
      ),
    );
  }
  
  /// Handles showing the recording modal for emotion entry
  void _showRecordingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRecordingModal(context),
    );
  }
  
  /// Load real conversations from Firebase using available DatabaseService methods
  Future<void> _loadConversationsFromFirebase() async {
    if (!mounted) return;
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user == null) return;
      
      // Get all conversations for the user
      final List<Conversation> userConversations = await databaseService.getConversationsForUser(user.id);
      
      if (!mounted) return;
      
      // Create conversation entries for the UI
      final List<Map<String, dynamic>> conversations = [];
      
      for (var conversation in userConversations) {
        try {
          // Find the other participant in the conversation
          final otherParticipantId = conversation.participants.firstWhere(
            (id) => id != user.id,
            orElse: () => '',
          );
          
          if (otherParticipantId.isEmpty) continue;
          
          // Get the other user's information
          final otherUser = await databaseService.getUser(otherParticipantId);
          if (otherUser == null) continue;
          
          // Get messages for this conversation
          final messages = await databaseService.getMessagesForConversation(
            conversation.id,
            limit: 20,
          );
          
          if (messages.isEmpty) continue;
          
          // Sort messages by timestamp (newest first)
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          // Get the latest message
          final latestMessage = messages.first;
          
          // Calculate unread count
          final unreadCount = messages.where(
            (m) => !m.isRead && m.receiverId == user.id
          ).length;
          
          conversations.add({
            'id': conversation.id,
            'name': otherUser.name,
            'lastMessage': latestMessage.content,
            'timestamp': latestMessage.timestamp,
            'time': _getFormattedTime(latestMessage.timestamp),
            'unread': unreadCount,
            'image': otherUser.name.split(' ').map((name) => name.isNotEmpty ? name[0] : '').take(2).join(''),
            'color': Theme.of(context).primaryColor,
            'isOnline': false, // Would be determined by real online status
            'role': otherUser.role.toString().split('.').last,
            'userId': otherUser.id,
            'messages': messages,
          });
        } catch (e) {
          debugPrint('Error loading conversation details: $e');
        }
      }
      
      // Sort conversations by latest message timestamp
      conversations.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
      
      if (mounted) {
        setState(() {
          _conversations = conversations;
        });
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading conversations: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Refreshes all data sources with real data
  Future<void> _refreshData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (_selectedChild == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
      
      final emotionService = Provider.of<EmotionService>(context, listen: false);
      
      // Fetch real data from Firebase using services
      _emotionDataFuture = emotionService.getEmotionData(_selectedChild!.id);
      _alertsFuture = emotionService.getDistressAlerts(_selectedChild!.id);
      _suggestionsFuture = emotionService.getCalmingSuggestions(_selectedChild!.id);
      
    } catch (e) {
      debugPrint('Error refreshing data: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// Changes the selected child and refreshes data
  void _changeChild(Child child) {
    if (_selectedChild?.id == child.id) return;
    
    setState(() {
      _selectedChild = child;
      _isLoading = true;
    });
    
    _refreshData();
  }
  
  /// Removes a child from the parent's account
  void _removeChild(Child child) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Child'),
        content: Text(
          'Are you sure you want to remove ${child.name} from your account? '
          'This will remove all associated data and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                // Show loading
                setState(() => _isLoading = true);
                
                // Get the necessary services
                final authService = Provider.of<AuthService>(context, listen: false);
                final databaseService = Provider.of<DatabaseService>(context, listen: false);
                final user = authService.currentUser;
                
                if (user == null) {
                  throw Exception('User not authenticated');
                }
                
                // Unlink the child from the user
                await databaseService.unlinkChildFromUser(user.id, child.id);
                
                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${child.name} was removed from your account'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                
                // Refresh data
                await _loadRealData();
              } catch (e) {
                debugPrint('Error removing child: $e');
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error removing child: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  
                  setState(() => _isLoading = false);
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
  
  /// Changes the time range for data display
  void _changeTimeRange(String range) {
    if (_timeRange == range) return;
    
    setState(() {
      _timeRange = range;
      _isLoading = true;
    });
    
    _refreshData();
  }
  
  /// Adds a new child to the user's account
  Future<void> _addNewChild() async {
    if (!mounted) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Show child creation form
      final childData = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AddChildDialog(),
      );

      if (childData == null || childData is! Map<String, dynamic>) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add child: Invalid data returned.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create the child profile
      final userId = Provider.of<AuthService>(context, listen: false).currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Ensure additionalInfo is a map
      final additionalInfo = childData['additionalInfo'];
      final additionalInfoMap = additionalInfo is Map<String, dynamic>
        ? additionalInfo
        : {'notes': additionalInfo?.toString() ?? ''};

      final child = await databaseService.createChild(
        name: childData['name'],
        age: childData['age'],
        gender: childData['gender'],
        parentId: userId,
        concerns: List<String>.from(childData['concerns'] ?? []),
        avatar: childData['avatar'],
        additionalInfo: additionalInfoMap,
      );
      
      // Link child to parent
      await databaseService.linkChildToParent(child.id, user.id);
      
      // Verify the relationship was created correctly
      final relationshipCheck = await databaseService.verifyParentChildRelationship(user.id, child.id);
      
      if (!relationshipCheck) {
        // Attempt to fix the relationship
        await databaseService.fixParentChildRelationship(user.id, child.id);
        
        // Re-verify the relationship
        await databaseService.verifyParentChildRelationship(user.id, child.id);
      }
      
      // Reload data to show the new child
      await _loadRealData();
      
      // Verify the child appears in the UI
      if (!_children.any((c) => c.id == child.id)) {
        // Force a final reload
        await _loadRealData();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${child.name} has been added successfully!'),
            backgroundColor: theme_utils.SeeAppTheme.success,
          ),
        );
      }
    } catch (e) {
      _handleError('add child', e);
    }
  }
  
  /// Loads therapist data from Firebase
  Future<void> _loadTherapists() async {
    if (!mounted) return;

    setState(() => _isLoadingTherapists = true);

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      // Fetch all therapists, not just connected ones for the main directory view
      final therapists = await databaseService.getUsersByRole(UserRole.therapist);
      
      if (mounted) {
        setState(() {
          _therapists = therapists; // Assign all therapists to the list
          _therapistsFuture = Future.value(therapists); // Update the future
          _isLoadingTherapists = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading therapists: $e');
      if (mounted) {
        setState(() {
          _isLoadingTherapists = false;
          _therapists = []; // Clear therapists on error
          _therapistsFuture = Future.value([]); // Set future to empty on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading therapists: ${e.toString()}'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
  
  /// Navigates to subscription screen
  void _navigateToSubscription({SubscriptionFeature? highlightedFeature}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubscriptionScreen(
          highlightedFeature: highlightedFeature,
        ),
      ),
    );
  }
  
  /// Builds the recording modal for emotion entry using the enhanced Visual Emotion Selector
  Widget _buildRecordingModal(BuildContext context) {
    // Use the enhanced emotion recording dialog
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  theme_utils.SeeAppTheme.spacing16,
                  theme_utils.SeeAppTheme.spacing16,
                  theme_utils.SeeAppTheme.spacing16,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Record New Emotion',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Main content with scrolling
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced visual emotion selector
                      VisualEmotionSelector(
                        selectedEmotion: _selectedEmotion,
                        onEmotionSelected: (emotion) {
                          setModalState(() {
                            _selectedEmotion = emotion;
                          });
                          HapticFeedback.mediumImpact();
                        },
                        buttonSize: MediaQuery.of(context).size.width > 600 
                            ? EmotionButtonSize.extraLarge 
                            : EmotionButtonSize.large,
                        showLabels: true,
                        animate: true,
                      ),
                      
                      const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
                      
                      // Intensity section with custom styling
                      Text(
                        'How intense is this feeling?',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: theme_utils.SeeAppTheme.spacing12),
                      
                      // Enhanced intensity slider with color matching selected emotion
                      Container(
                        padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing12),
                        decoration: BoxDecoration(
                          color: theme_utils.SeeAppTheme.getEmotionColor(
                              _convertToThemeEmotionType(_selectedEmotion)
                            ).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
                          border: Border.all(
                            color: theme_utils.SeeAppTheme.getEmotionColor(
                              _convertToThemeEmotionType(_selectedEmotion)
                            ).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  theme_utils.SeeAppTheme.getEmotionIcon(
                                    _convertToThemeEmotionType(_selectedEmotion)
                                  ),
                                  color: theme_utils.SeeAppTheme.getEmotionColor(
                                    _convertToThemeEmotionType(_selectedEmotion)
                                  ),
                                  size: 24,
                                ),
                                const SizedBox(width: theme_utils.SeeAppTheme.spacing8),
                                Text(
                                  '${(_emotionIntensity * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme_utils.SeeAppTheme.getEmotionColor(
                                      _convertToThemeEmotionType(_selectedEmotion)
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: theme_utils.SeeAppTheme.getEmotionColor(
                                  _convertToThemeEmotionType(_selectedEmotion)
                                ),
                                inactiveTrackColor: theme_utils.SeeAppTheme.getEmotionColor(
                                  _convertToThemeEmotionType(_selectedEmotion)
                                ).withOpacity(0.2),
                                thumbColor: theme_utils.SeeAppTheme.getEmotionColor(
                                  _convertToThemeEmotionType(_selectedEmotion)
                                ),
                                trackHeight: 10,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                              ),
                              child: Slider(
                                value: _emotionIntensity,
                                min: 0,
                                max: 1,
                                divisions: 10,
                                label: '${(_emotionIntensity * 100).toInt()}%',
                                onChanged: (value) {
                                  setModalState(() {
                                    _emotionIntensity = value;
                                  });
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Mild',
                                  style: TextStyle(color: theme_utils.SeeAppTheme.textSecondary),
                                ),
                                Text(
                                  'Moderate',
                                  style: TextStyle(color: theme_utils.SeeAppTheme.textSecondary),
                                ),
                                Text(
                                  'Strong',
                                  style: TextStyle(color: theme_utils.SeeAppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
                      
                      // Context section
                      Text(
                        'Context (Optional)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: theme_utils.SeeAppTheme.spacing12),
                      TextField(
                        controller: _contextController,
                        decoration: InputDecoration(
                          hintText: 'What was happening when this emotion occurred?',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
                          prefixIcon: const Icon(Icons.edit_note),
                        ),
                        maxLines: 3,
                      ),
                      
                      const SizedBox(height: theme_utils.SeeAppTheme.spacing32),
                      
                      // Save button with emotion-matching color
                      SizedBox(
                        width: double.infinity,
                        height: 56, // Larger button for easier tapping
                        child: ElevatedButton(
                          onPressed: () {
                            _saveEmotionRecord();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme_utils.SeeAppTheme.getEmotionColor(
                              _convertToThemeEmotionType(_selectedEmotion)
                            ),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
                            ),
                            elevation: 3,
                          ),
                          child: const Text(
                            'Save Emotion Record',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOutQuad);
  }
  
  /// Saves an emotion record
  void _saveEmotionRecord() {
    // In a real app, would save to database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emotion recorded successfully'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
    
    setState(() {
      // Reset for next time
      _emotionIntensity = 0.5;
      _contextController.clear();
    });
    
    // Refresh data after recording
    _refreshData();
  }
  
  /// Helper to format timestamp for display
  String _getFormattedTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (messageDate == today) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }
  
  /// Initialize mock conversations - stub method to work with existing codebase
  void _initializeMockConversations() async {
    // This method is kept as a stub to maintain code compatibility
    // But should call the real implementation
    await _loadConversationsFromFirebase();
  }
  
  /// Handle article view state changes
  void _onArticleOpened(Article article, bool isOpen) {
    setState(() {
      _currentArticle = article;
      _isArticleOpen = isOpen;
    });
  }
  
  /// Save article to favorites
  void _saveArticleToFavorites() {
    HapticFeedback.selectionClick();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Article saved to favorites'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Close article view
    setState(() {
      _isArticleOpen = false;
    });
  }
  /// Deep inspect a map for any value that matches the userId
  bool _deepInspectForMatch(Map<String, dynamic> data, String userId) {
    bool foundMatch = false;
    
    // Helper function to recursively check values
    void checkValue(dynamic value) {
      if (value == userId) {
        foundMatch = true;
        return;
      }
      
      if (value is Map<String, dynamic>) {
        for (final entry in value.entries) {
          checkValue(entry.value);
          if (foundMatch) return;
        }
      } else if (value is List) {
        for (final item in value) {
          checkValue(item);
          if (foundMatch) return;
        }
      }
    }
    
    checkValue(data);
    return foundMatch;
  }
  /// Directly save an article to favorites from the tab
  void _saveArticleToFavoritesFromTab(Article article) {
    HapticFeedback.selectionClick();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Article "${article.title}" saved to favorites'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Handles viewing all articles
  void _viewAllArticles() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Viewing all articles'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Converts emotion model type to theme emotion type
  theme_utils.EmotionType _convertToThemeEmotionType(emotion_model.EmotionType type) {
    switch (type) {
      case emotion_model.EmotionType.joy:
        return theme_utils.EmotionType.joy;
      case emotion_model.EmotionType.sadness:
        return theme_utils.EmotionType.sadness;
      case emotion_model.EmotionType.anger:
        return theme_utils.EmotionType.anger;
      case emotion_model.EmotionType.fear:
        return theme_utils.EmotionType.fear;
      case emotion_model.EmotionType.calm:
        return theme_utils.EmotionType.calm;
      default:
        return theme_utils.EmotionType.joy;
    }
  }

  /// Converts alert severity to theme alert severity
  theme_utils.AlertSeverity _convertToThemeAlertSeverity(emotion_model.AlertSeverity severity) {
    switch (severity) {
      case emotion_model.AlertSeverity.high:
        return theme_utils.AlertSeverity.high;
      case emotion_model.AlertSeverity.medium:
        return theme_utils.AlertSeverity.medium;
      case emotion_model.AlertSeverity.low:
        return theme_utils.AlertSeverity.low;
      default:
        return theme_utils.AlertSeverity.medium;
    }
  }

  // ALERT HANDLING
  void _resolveAlert(emotion_model.DistressAlert alert) {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Resolve Alert'),
          content: const Text(
            'Are you sure you want to mark this alert as resolved?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alert marked as resolved'),
                    backgroundColor: Colors.green,
                  ),
                );
                _refreshData(); // Refresh to update UI
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme_utils.SeeAppTheme.primaryColor,
              ),
              child: const Text('Resolve'),
            ),
          ],
        );
      },
    );
  }

  void _viewAlertDetails(emotion_model.DistressAlert alert) {
    // Implementation would go here
    HapticFeedback.selectionClick();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Viewing alert details'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _viewAlertHistory() {
    // Implementation would go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Viewing alert history'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // SUGGESTION HANDLING
  void _viewAllSuggestions() {
    // Implementation would go here
    HapticFeedback.selectionClick();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Viewing all suggestions'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  // Handler for rating suggestions
  void _rateSuggestion(
    emotion_model.CalmingSuggestion suggestion,
    EffectivenessRating rating,
    emotion_model.EmotionType beforeEmotion,
    double beforeIntensity,
    emotion_model.EmotionType? afterEmotion,
    double? afterIntensity,
    String? comments
  ) async {
    if (_selectedChild == null) return;
    
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user == null) return;
      
      // Submit the feedback
      await databaseService.submitSuggestionFeedback(
        suggestionId: suggestion.id,
        childId: _selectedChild!.id,
        parentId: user.id,
        rating: rating,
        beforeEmotion: beforeEmotion,
        beforeIntensity: beforeIntensity,
        afterEmotion: afterEmotion,
        afterIntensity: afterIntensity,
        comments: comments,
        wasCompleted: true, // Assuming it was completed if they're providing feedback
      );
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting suggestion feedback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting feedback: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewSuggestionDetails(emotion_model.CalmingSuggestion suggestion) {
    // Implementation would go here
    HapticFeedback.selectionClick();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Viewing suggestion details'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleFavoriteSuggestion(emotion_model.CalmingSuggestion suggestion, bool isFavorite) {
    HapticFeedback.selectionClick();
    
    // In a real app, would update in database
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite 
              ? 'Added to favorites' 
              : 'Removed from favorites',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    
    setState(() => _refreshData());
  }

  // THERAPIST HANDLING
  void _viewTherapistProfile(AppUser therapist) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TherapistProfileScreen(
          therapist: therapist,
        ),
      ),
    );
  }

  void _bookAppointment(AppUser therapist) {
    // Implementation would go here
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking appointment with ${therapist.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addTherapistToFavorites() {
    // Implementation would go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Adding therapist to favorites'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _addSpecificTherapistToFavorites(AppUser therapist) async {
    if (!mounted) return;
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to be logged in to add favorites'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      
      // In a real app, this would save to a database
      await databaseService.addTherapistToFavorites(user.id, therapist.id);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${therapist.name} to favorites'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // Navigate to favorites list
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Viewing favorites - to be implemented'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      );
      
      // Refresh therapists list to show updated favorites
      _loadTherapists();
    } catch (e) {
      debugPrint('Error adding therapist to favorites: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to favorites: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewAllTherapists() {
    // Implementation would go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Viewing all therapists'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // MESSAGING HANDLING
  void _createNewMessage(BuildContext context) {
    // Implementation would go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Creating new message'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openConversation(Map<String, dynamic> conversation) {
    final String? conversationId = conversation['id'] as String?;
    final String? otherUserId = conversation['userId'] as String?;
    final String? otherUserName = conversation['name'] as String?;

    if (conversationId == null || conversationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open chat: Conversation ID missing.')),
      );
      return;
    }

    if (otherUserId == null || otherUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open chat: Other user ID missing.')),
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
  }

  // NAVIGATION HANDLERS
  
  /// Shows notifications panel with real data
  void _showNotificationsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildNotificationsPanel(context),
    );
  }
  
  /// Builds the notifications panel with real data from Firebase
  Widget _buildNotificationsPanel(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    // Return early if no user is logged in
    if (user == null) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('Please log in to view notifications'),
      );
    }
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Mark All as Read'),
                      onPressed: () => _markAllNotificationsAsRead(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: databaseService.getNotificationsForUser(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            'We couldn\'t load your notifications: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              onPressed: () {
                                // Force refresh by popping and showing again
                                Navigator.pop(context);
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (mounted) {
                                    _showNotificationsPanel();
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyNotificationsView();
                }
                
                final notifications = snapshot.data!;
                
                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationItem(
                      context: context,
                      notification: notification,
                      onMarkAsRead: () => _markNotificationAsRead(context, notification['id']),
                      onDelete: () => _deleteNotification(context, notification['id']),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds an empty notifications view
  Widget _buildEmptyNotificationsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds a notification item
  Widget _buildNotificationItem({
    required BuildContext context,
    required Map<String, dynamic> notification,
    required VoidCallback onMarkAsRead,
    required VoidCallback onDelete,
  }) {
    final bool isRead = notification['isRead'] ?? false;
    final String type = notification['type'] ?? 'system';
    final DateTime timestamp = notification['timestamp'] ?? DateTime.now();
    
    // Determine icon and color based on notification type
    IconData icon;
    Color color;
    
    switch (type) {
      case 'alert':
        icon = Icons.warning_amber_rounded;
        color = theme_utils.SeeAppTheme.alertHigh;
        break;
      case 'suggestion':
        icon = Icons.tips_and_updates_outlined;
        color = theme_utils.SeeAppTheme.primaryColor;
        break;
      case 'message':
        icon = Icons.mail_outline;
        color = theme_utils.SeeAppTheme.secondaryColor;
        break;
      case 'subscription':
        icon = Icons.card_membership_outlined;
        color = Colors.purple;
        break;
      default:
        icon = Icons.notifications_outlined;
        color = Colors.blue;
    }
    
    return Dismissible(
      key: Key(notification['id']),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onDelete();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isRead ? Colors.transparent : theme_utils.SeeAppTheme.primaryColor.withOpacity(0.05),
          border: Border(
            left: BorderSide(
              color: isRead ? Colors.transparent : color,
              width: 4,
            ),
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(
            notification['title'] ?? 'Notification',
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notification['description'] ?? ''),
              const SizedBox(height: 4),
              Text(
                _getFormattedNotificationTime(timestamp),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          isThreeLine: true,
          trailing: isRead
              ? IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                )
              : IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  onPressed: onMarkAsRead,
                  tooltip: 'Mark as read',
                ),
          onTap: () => _handleNotificationTap(context, notification),
        ),
      ),
    );
  }
  
  /// Formats notification time for display
  String _getFormattedNotificationTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (notificationDate == today) {
      return 'Today at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (notificationDate == yesterday) {
      return 'Yesterday at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
  
  /// Handles notification tap based on type
  void _handleNotificationTap(BuildContext context, Map<String, dynamic> notification) {
    // First mark as read
    _markNotificationAsRead(context, notification['id']);
    
    // Then navigate based on type
    final String type = notification['type'] ?? 'system';
    
    switch (type) {
      case 'alert':
        // Navigate to alerts screen
        setState(() {
          _currentTabIndex = 1; // Dashboard tab
          _tabController.animateTo(1);
        });
        Navigator.pop(context); // Close notifications panel
        break;
      case 'suggestion':
        // Navigate to suggestions screen
        setState(() {
          _currentTabIndex = 1; // Dashboard tab
          _tabController.animateTo(1);
        });
        Navigator.pop(context); // Close notifications panel
        break;
      case 'message':
        // Navigate to messages tab
        setState(() {
          _currentTabIndex = 3; // Messages tab
          _tabController.animateTo(3);
        });
        Navigator.pop(context); // Close notifications panel
        break;
      case 'subscription':
        // Navigate to subscription screen
        Navigator.pop(context); // Close notifications panel
        _navigateToSubscription();
        break;
      default:
        // Just close the panel for system notifications
        Navigator.pop(context);
    }
  }
  
  /// Marks a notification as read
  void _markNotificationAsRead(BuildContext context, String notificationId) async {
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user == null) return;
      
      await databaseService.markNotificationAsRead(user.id, notificationId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification marked as read'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Marks all notifications as read
  void _markAllNotificationsAsRead(BuildContext context) async {
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user == null) return;
      
      await databaseService.markAllNotificationsAsRead(user.id);
      
      // Force rebuild of the panel
      Navigator.pop(context);
      _showNotificationsPanel();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Deletes a notification
  void _deleteNotification(BuildContext context, String notificationId) async {
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user == null) return;
      
      await databaseService.deleteNotification(user.id, notificationId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Shows settings panel
  void _showSettingsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme_utils.SeeAppTheme.textPrimary, // Dark background for better contrast
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text for dark background
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white), // White icon
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildSettingsSection(
                    title: 'Account',
                    icon: Icons.account_circle,
                    children: [
                      _buildSettingItem(
                        title: 'Edit Profile',
                        icon: Icons.edit,
                        onTap: () {
                          Navigator.pop(context);
                          _showEditProfileDialog();
                        },
                      ),
                      _buildSettingItem(
                        title: 'Change Password',
                        icon: Icons.lock,
                        onTap: () {
                          Navigator.pop(context);
                          _showChangePasswordDialog();
                        },
                      ),
                      _buildSettingItem(
                        title: 'Manage Subscription',
                        icon: Icons.card_membership,
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToSubscription();
                        },
                      ),
                    ],
                  ),
                  _buildSettingsSection(
                    title: 'Notifications',
                    icon: Icons.notifications,
                    children: [
                      _buildSettingToggle(
                        title: 'Push Notifications',
                        value: true,
                        onChanged: (value) {
                          // Would be saved to user preferences
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Push notifications ${value ? 'enabled' : 'disabled'}'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      _buildSettingToggle(
                        title: 'Email Notifications',
                        value: false,
                        onChanged: (value) {
                          // Would be saved to user preferences
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Email notifications ${value ? 'enabled' : 'disabled'}'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      _buildSettingToggle(
                        title: 'Alert Notifications',
                        value: true,
                        onChanged: (value) {
                          // Would be saved to user preferences
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Alert notifications ${value ? 'enabled' : 'disabled'}'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  _buildSettingsSection(
                    title: 'Privacy',
                    icon: Icons.privacy_tip,
                    children: [
                      _buildSettingToggle(
                        title: 'Share Data with Therapists',
                        value: true,
                        onChanged: (value) {
                          // Would be saved to user preferences
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Data sharing ${value ? 'enabled' : 'disabled'}'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        title: 'Manage Data',
                        icon: Icons.storage,
                        onTap: () {
                          Navigator.pop(context);
                          _showManageDataDialog();
                        },
                      ),
                      _buildSettingItem(
                        title: 'Privacy Policy',
                        icon: Icons.policy,
                        onTap: () {
                          Navigator.pop(context);
                          _showPrivacyPolicyDialog();
                        },
                      ),
                    ],
                  ),
                  _buildSettingsSection(
                    title: 'App',
                    icon: Icons.phone_android,
                    children: [
                      _buildSettingItem(
                        title: 'Language',
                        icon: Icons.language,
                        value: 'English',
                        onTap: () {
                          Navigator.pop(context);
                          _showLanguageDialog();
                        },
                      ),
                      _buildSettingToggle(
                        title: 'Dark Mode',
                        value: false,
                        onChanged: (value) {
                          // Would be saved to user preferences
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Dark mode ${value ? 'enabled' : 'disabled'}'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        title: 'About',
                        icon: Icons.info,
                        onTap: () {
                          Navigator.pop(context);
                          _showAboutDialog();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const Divider(color: Colors.white30),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildSettingItem({
    required String title,
    required IconData icon,
    String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white70),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            if (value != null) Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingToggle({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme_utils.SeeAppTheme.primaryColor,
            inactiveThumbColor: Colors.white60,
            inactiveTrackColor: Colors.white30,
          ),
        ],
      ),
    );
  }
  
  void _showEditProfileDialog() {
    // Get the current user from AuthService
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    
    // Use the actual user data
    nameController.text = user.name;
    emailController.text = user.email;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                // Get database service
                final databaseService = Provider.of<DatabaseService>(context, listen: false);
                
                // Create updated user
                final updatedUser = user.copyWith(
                  name: nameController.text,
                  email: emailController.text,
                );
                
                // Update user in database
                await databaseService.createOrUpdateUser(updatedUser);
                
                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                // Show error message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating profile: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme_utils.SeeAppTheme.primaryColor,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Would change the user's password
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password changed successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme_utils.SeeAppTheme.primaryColor,
            ),
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }
  
  void _showManageDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Your Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download Your Data'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your data export is being prepared'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Account Data'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteAccountConfirmation();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account Data?'),
        content: const Text(
          'This action cannot be undone. All your data, including emotion records, '
          'messages, and settings will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion request submitted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Data Collection',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'We collect information that you provide directly, such as when you create an account, '
                'record emotions, or communicate with therapists. We also collect information about your '
                'use of our services.',
              ),
              SizedBox(height: 16),
              Text(
                'Use of Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'We use the information we collect to provide, maintain, and improve our services, '
                'communicate with you, and develop new features.',
              ),
              SizedBox(height: 16),
              Text(
                'Sharing of Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'We share information with therapists only when you explicitly connect with them. '
                'We may also share information in response to legal requests or to protect rights.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Language'),
        children: [
          _buildLanguageOption('English', isSelected: true),
          _buildLanguageOption('Spanish'),
          _buildLanguageOption('French'),
          _buildLanguageOption('German'),
          _buildLanguageOption('Japanese'),
        ],
      ),
    );
  }
  
  Widget _buildLanguageOption(String language, {bool isSelected = false}) {
    return SimpleDialogOption(
      onPressed: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language changed to $language'),
            backgroundColor: Colors.green,
          ),
        );
      },
      child: Row(
        children: [
          Text(
            language,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme_utils.SeeAppTheme.primaryColor : null,
            ),
          ),
          const Spacer(),
          if (isSelected)
            Icon(
              Icons.check,
              color: theme_utils.SeeAppTheme.primaryColor,
            ),
        ],
      ),
    );
  }
  
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About SEE App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version 1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'SEE App helps parents monitor their children\'s emotional well-being '
              'and connect with qualified therapists for support and guidance.',
            ),
            const SizedBox(height: 16),
            const Text(
              ' 2023 SEE Emotional Health, Inc. All rights reserved.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildIconButton(
                  icon: Icons.mail,
                  label: 'Contact',
                  onTap: () {
                    Navigator.pop(context);
                    _launchEmailSupport();
                  },
                ),
                _buildIconButton(
                  icon: Icons.language,
                  label: 'Website',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening website'),
                      ),
                    );
                  },
                ),
                _buildIconButton(
                  icon: Icons.star,
                  label: 'Rate Us',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening app store'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, color: theme_utils.SeeAppTheme.primaryColor),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _navigateToHistory() {
    // Switch to dashboard tab and select weekly view
    setState(() {
      _currentTabIndex = 1;
      _tabController.animateTo(1);
      _timeRange = 'month'; // Show monthly data by default for history
      _refreshData();
    });
    
    // Show modal with historical data visualization
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Emotion History',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<emotion_model.EmotionData>>(
                future: _emotionDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No historical data available'));
                  }
                  
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final emotion = snapshot.data![index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            theme_utils.SeeAppTheme.getEmotionIcon(
                              _convertToThemeEmotionType(emotion.type)
                            ),
                            color: theme_utils.SeeAppTheme.getEmotionColor(
                              _convertToThemeEmotionType(emotion.type)
                            ),
                          ),
                          title: Text(emotion.type.toString().split('.').last),
                          subtitle: Text(
                            'Intensity: ${(emotion.intensity * 100).toInt()}%\n'
                            '${emotion.timestamp.toString().substring(0, 16)}'
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToReports() {
    // Generate a report summary from emotion data
    setState(() {
      _currentTabIndex = 1;
      _tabController.animateTo(1);
    });
    
    // Show report generation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Report Type:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.pie_chart),
              title: const Text('Emotion Distribution'),
              subtitle: const Text('Summary of emotions over time'),
              onTap: () {
                Navigator.pop(context);
                _showEmotionDistributionReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Progress Report'),
              subtitle: const Text('Track emotional progress'),
              onTap: () {
                Navigator.pop(context);
                _showProgressReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber),
              title: const Text('Alert Summary'),
              subtitle: const Text('Summary of distress alerts'),
              onTap: () {
                Navigator.pop(context);
                _showAlertSummaryReport();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _showEmotionDistributionReport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emotion Distribution Report',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<emotion_model.EmotionData>>(
                future: _emotionDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No data available for report'));
                  }
                  
                  return Center(
                    child: Text(
                      'Report generated successfully.\nExport options will be available in future updates.',
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showProgressReport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Report',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<emotion_model.EmotionData>>(
                future: _emotionDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No data available for report'));
                  }
                  
                  return Center(
                    child: Text(
                      'Progress report generated successfully.\nExport options will be available in future updates.',
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAlertSummaryReport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alert Summary Report',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<emotion_model.DistressAlert>>(
                future: _alertsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No alerts available for report'));
                  }
                  
                  return Center(
                    child: Text(
                      'Alert summary report generated successfully.\nExport options will be available in future updates.',
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  
  void _navigateToHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Help & Support',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildHelpSection(
                    title: 'Getting Started',
                    icon: Icons.play_circle_outline,
                    children: [
                      _buildHelpItem(
                        title: 'Dashboard Overview',
                        onTap: () {
                          Navigator.pop(context);
                          _showHelpContent('Dashboard Overview', 'The dashboard provides a central place to monitor your child\'s emotional well-being, track patterns, and receive suggestions.');
                        },
                      ),
                      _buildHelpItem(
                        title: 'Setting Up Your Profile',
                        onTap: () {
                          Navigator.pop(context);
                          _showHelpContent('Setting Up Your Profile', 'Complete your profile to get personalized recommendations and connect with therapists who specialize in your child\'s needs.');
                        },
                      ),
                      _buildHelpItem(
                        title: 'Connecting SEE Device',
                        onTap: () {
                          Navigator.pop(context);
                          _showHelpContent('Connecting SEE Device', 'The SEE device connects via Bluetooth to automatically monitor emotional patterns and provide real-time insights.');
                        },
                      ),
                    ],
                  ),
                  _buildHelpSection(
                    title: 'Using the App',
                    icon: Icons.smartphone,
                    children: [
                      _buildHelpItem(
                        title: 'Recording Emotions',
                        onTap: () {
                          Navigator.pop(context);
                          _showHelpContent('Recording Emotions', 'You can manually record emotions using the + button on the dashboard tab. Select the emotion type and intensity.');
                        },
                      ),
                      _buildHelpItem(
                        title: 'Understanding Reports',
                        onTap: () {
                          Navigator.pop(context);
                          _showHelpContent('Understanding Reports', 'Reports provide insights into emotional patterns over time, helping you identify triggers and progress.');
                        },
                      ),
                      _buildHelpItem(
                        title: 'Messaging Therapists',
                        onTap: () {
                          Navigator.pop(context);
                          _showHelpContent('Messaging Therapists', 'You can message therapists directly through the app to discuss concerns, ask questions, or schedule appointments.');
                        },
                      ),
                    ],
                  ),
                  _buildHelpSection(
                    title: 'Account & Subscription',
                    icon: Icons.account_circle_outlined,
                    children: [
                      _buildHelpItem(
                        title: 'Managing Subscription',
                        onTap: () {
                          Navigator.pop(context);
                          _showHelpContent('Managing Subscription', 'You can view and change your subscription plan at any time through the subscription screen.');
                        },
                      ),
                      _buildHelpItem(
                        title: 'Account Security',
                        onTap: () {
                          Navigator.pop(context);
                          _showHelpContent('Account Security', 'We use industry-standard encryption to protect your data. You can change your password or update account information at any time.');
                        },
                      ),
                      _buildHelpItem(
                        title: 'Privacy Settings',
                        onTap: () {
                          Navigator.pop(context);
                          _showHelpContent('Privacy Settings', 'Control what information is shared with therapists and how your data is used in the privacy settings.');
                        },
                      ),
                    ],
                  ),
                  _buildHelpSection(
                    title: 'Contact Support',
                    icon: Icons.support_agent,
                    children: [
                      _buildHelpItem(
                        title: 'Email Support',
                        onTap: () {
                          Navigator.pop(context);
                          _launchEmailSupport();
                        },
                      ),
                      _buildHelpItem(
                        title: 'FAQ',
                        onTap: () {
                          Navigator.pop(context);
                          _showFAQ();
                        },
                      ),
                      _buildHelpItem(
                        title: 'Report an Issue',
                        onTap: () {
                          Navigator.pop(context);
                          _showReportIssue();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHelpSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme_utils.SeeAppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildHelpItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
  
  void _showHelpContent(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _launchEmailSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening email client to contact support'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _showFAQ() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'How does the SEE device work?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'The SEE device uses sensors to detect physiological changes associated with emotions and sends this data to the app for analysis.',
              ),
              SizedBox(height: 16),
              Text(
                'How often should I record emotions?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'We recommend recording emotions at least once daily for best results, or whenever significant emotional events occur.',
              ),
              SizedBox(height: 16),
              Text(
                'Is my data secure?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Yes, all data is encrypted and stored securely. Only you and the therapists you explicitly connect with can access your information.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showReportIssue() {
    final issueController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report an Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please describe the issue you\'re experiencing:'),
            const SizedBox(height: 12),
            TextField(
              controller: issueController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe the issue...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Issue report submitted. Thank you!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme_utils.SeeAppTheme.primaryColor,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
  
  /// Handles user logout
  void _handleLogout() async {
    Navigator.pop(context); // Close the menu
    
    // Store dialog context for later dismissal
    final BuildContext dialogContext = context;
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Cancel any active subscriptions or listeners
      _emotionSubscription?.cancel();
      _missionSubscription?.cancel();
      _alertsSubscription?.cancel();
      _conversationSubscription?.cancel();
      _suggestionsSubscription?.cancel();
      
      // Get the AuthService instance and sign out
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      
      // Delay navigation slightly to allow Firebase to clean up resources
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Close the loading dialog before navigation
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
      
      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (route) => false, // Clear all routes from the stack
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      
      // If there's an error, close the loading dialog
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
      
      // Even if there's an error, try to navigate back to login
      if (mounted) {
        // Show error but still try to navigate away
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: ${e.toString()}'),
            backgroundColor: theme_utils.SeeAppTheme.alertHigh,
          ),
        );
        
        // Force navigation to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (route) => false,
        );
      }
    }
  }
  


  // Animation for a smoother UI transition
  void _animateIn() {
    if (_selectedChild != null) {
      _refreshData();
    }
  }

  /// Public accessor for children list
  List<Child> getChildren() {
    return _children;
  }

  /// Public method to navigate to messages
  void navigateToMessages({required String therapistId, required String childId}) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final parentId = authService.currentUser?.id;
    if (parentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to message a therapist.')),
      );
      return;
    }
    try {
      // Get or create the conversation between parent and therapist
      final conversation = await databaseService.getOrCreateConversation(parentId, therapistId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MessageScreen(
            conversationId: conversation.id,
            otherUserId: therapistId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open chat: ${e.toString()}')),
      );
    }
  }
  


  /// Test database permissions
  Future<void> _testDatabasePermissions() async {
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id ?? '';
      
      if (userId.isEmpty) {
        throw Exception('User not logged in');
      }
      
      debugPrint('Testing database permissions for user $userId');
      
      // Test database permissions
      final permissions = await databaseService.testDatabasePermissions();
      
      // Log results
      permissions.forEach((key, value) {
        debugPrint('Permission - $key: ${value ? 'YES' : 'NO'}');
      });
      
      // Show results dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Database Permissions'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Read Permissions:'),
                SizedBox(height: 8),
                _buildPermissionItem('Users', permissions['canReadUsers'] ?? false),
                _buildPermissionItem('Children', permissions['canReadChildren'] ?? false),
                _buildPermissionItem('Emotions', permissions['canReadEmotions'] ?? false),
                SizedBox(height: 16),
                Text('Write Permissions:'),
                SizedBox(height: 8),
                _buildPermissionItem('Users', permissions['canWriteUsers'] ?? false),
                _buildPermissionItem('Children', permissions['canWriteChildren'] ?? false),
                _buildPermissionItem('Emotions', permissions['canWriteEmotions'] ?? false),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error testing permissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Widget _buildPermissionItem(String name, bool hasPermission) {
    return Row(
      children: [
        Icon(
          hasPermission ? Icons.check_circle : Icons.cancel,
          color: hasPermission ? Colors.green : Colors.red,
          size: 16,
        ),
        SizedBox(width: 8),
        Text(name),
      ],
    );
  }

  @override
  Widget _buildBody() {
    return _buildMainContent();
  }

  /// Get children using all available methods
  Future<List<Child>> _getAllChildrenForParent(String parentId) async {
    if (!mounted) return [];
    
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      
      // Try primary method first
      final children = await databaseService.getChildrenByParentId(parentId);
      debugPrint('Method 1: Found ${children.length} children via getChildrenByParentId');
      
      if (children.isNotEmpty) {
        return children;
      }
      
      // Try alternative method
      final children2 = await databaseService.getChildrenForUser(parentId);
      debugPrint('Method 2: Found ${children2.length} children via getChildrenForUser');
      
      if (children2.isNotEmpty) {
        return children2;
      }
      
      // We can't use more specific methods without exposing the Firestore references
      // For debugging purposes, print a message
      debugPrint('WARNING: No children found for parent $parentId using standard methods');
      
      return [];
    } catch (e) {
      debugPrint('Error in _getAllChildrenForParent: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            ParentAppBar(
              title: _getTabTitle(),
              innerBoxIsScrolled: innerBoxIsScrolled,
              onShowNotifications: _showNotificationsPanel,
              onShowSettings: _showSettingsPanel,
              databaseService: Provider.of<DatabaseService>(context),
              userId: Provider.of<AuthService>(context).currentUser?.id,
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(), // Disable swiping
            children: [
              // Home Tab - Content, Articles, Tips
              HomeTab(
                currentArticle: _currentArticle,
                isArticleOpen: _isArticleOpen,
                onRefreshContent: _refreshData,
                onViewArticle: (article) => _onArticleOpened(article, true),
                onSaveArticleToFavorites: _saveArticleToFavoritesFromTab,
                onViewAllArticles: _viewAllArticles,
                onNavigateToHelp: _navigateToHelp,
                suppressNoChildrenMessage: Provider.of<AuthService>(context, listen: false).isTherapist,
              ).animate(key: const ValueKey('home-tab'))
                .fadeIn(duration: 300.ms),
              
              // Dashboard Tab
              DashboardTab(
                children: _children,
                selectedChild: _selectedChild,
                timeRange: _timeRange,
                isLoading: _isLoading,
                emotionDataFuture: _emotionDataFuture,
                alertsFuture: _alertsFuture,
                suggestionsFuture: _suggestionsFuture,
                hasDevice: _hasDevice,
                showEmotionBanner: _showEmotionBanner,
                showAlertsBanner: _showAlertsBanner,
                showSuggestionsBanner: _showSuggestionsBanner,
                onChangeChild: _changeChild,
                onChangeTimeRange: _changeTimeRange,
                onRefreshData: _refreshData,
                onAddNewChild: _addNewChild,
                onResolveAlert: _resolveAlert,
                onViewAlertDetails: _viewAlertDetails,
                onViewAlertHistory: _viewAlertHistory,
                onViewSuggestionDetails: _viewSuggestionDetails,
                onToggleFavoriteSuggestion: _toggleFavoriteSuggestion,
                onViewAllSuggestions: _viewAllSuggestions,
                onShowRecordingModal: _showRecordingModal,
                onNavigateToSubscription: _navigateToSubscription,
              ).animate(key: const ValueKey('dashboard-tab'))
                .fadeIn(duration: 300.ms),
              
              // Therapists Tab
              TherapistsTab(
                therapistsFuture: _therapistsFuture,
                isLoadingTherapists: _isLoadingTherapists,
                onRefreshTherapists: _loadTherapists,
                onAddTherapistToFavorites: (therapist) {}, // Placeholder
                onViewTherapistProfile: _onViewTherapistProfile,
                onBookAppointment: (therapist) {}, // Placeholder
                onViewAllTherapists: _onViewAllTherapists,
              ).animate(key: const ValueKey('therapists-tab'))
                .fadeIn(duration: 300.ms),
              
              // Messages Tab
              MessagesTab(
                conversations: _conversations,
                onOpenConversation: (conversation) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MessageScreen(
                        conversationId: conversation['id'] ?? '',
                        otherUserId: conversation['otherUserId'] ?? '',
                      ),
                    ),
                  );
                },
                onCreateNewMessage: _createNewMessage,
              ).animate(key: const ValueKey('messages-tab'))
                .fadeIn(duration: 300.ms),
            ],
          ),
        ),
      ),
      floatingActionButton: ParentFab(
        currentTabIndex: _currentTabIndex,
        isArticleOpen: _isArticleOpen,
        onSaveArticle: _saveArticleToFavorites,
        onAddChild: _addNewChild,
        onAddTherapistToFavorites: _addTherapistToFavorites,
        onCreateNewMessage: () => _createNewMessage(context),
      ),
      drawer: ParentDrawer(
        onLogout: _handleLogout,
        onNavigateToHistory: _navigateToHistory,
        onNavigateToReports: _navigateToReports,
        onNavigateToMessages: () {
          // Default to first child and first therapist if available
          final firstChild = _children.isNotEmpty ? _children.first : null;
          final firstTherapist = _therapists.isNotEmpty ? _therapists.first : null; // Changed to _therapists

          if (firstChild != null && firstTherapist != null) {
            navigateToMessages(
              therapistId: firstTherapist.id,
              childId: firstChild.id,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No children or therapists available to start a conversation.')),
            );
          }
        },
        onNavigateToHelp: _navigateToHelp,
        onNavigateToSettings: _showSettingsPanel,
      ),
      bottomNavigationBar: ParentBottomNavBar(
        currentTabIndex: _currentTabIndex,
        onTabChanged: (index) {
          setState(() {
            _currentTabIndex = index;
            _tabController.animateTo(index);
          });
        },
      ),
    );
  }
  
  /// Gets the title for the current tab
  String _getTabTitle() {
    switch (_currentTabIndex) {
      case 0:
        return "Home";
      case 1:
        return "Dashboard";
      case 2:
        return "Therapists";
      case 3:
        return "Messages";
      default:
        return "SEE App";
    }
  }
  
  /// Builds the main content for the current tab
  Widget _buildMainContent() {
    switch (_currentTabIndex) {
      case 0:
        return HomeTab(
          currentArticle: _currentArticle,
          isArticleOpen: _isArticleOpen,
          onRefreshContent: _refreshData,
          onViewArticle: (article) => _onArticleOpened(article, true),
          onSaveArticleToFavorites: _saveArticleToFavoritesFromTab,
          onViewAllArticles: _viewAllArticles,
          onNavigateToHelp: _navigateToHelp,
          suppressNoChildrenMessage: Provider.of<AuthService>(context, listen: false).isTherapist,
        );
      case 1:
        return DashboardTab(
          children: _children,
          selectedChild: _selectedChild,
          timeRange: _timeRange,
          isLoading: _isLoading,
          emotionDataFuture: _emotionDataFuture,
          alertsFuture: _alertsFuture,
          suggestionsFuture: _suggestionsFuture,
          hasDevice: _hasDevice,
          showEmotionBanner: _showEmotionBanner,
          showAlertsBanner: _showAlertsBanner,
          showSuggestionsBanner: _showSuggestionsBanner,
          onChangeChild: _changeChild,
          onChangeTimeRange: _changeTimeRange,
          onRefreshData: _refreshData,
          onAddNewChild: _addNewChild,
          onResolveAlert: _resolveAlert,
          onViewAlertDetails: _viewAlertDetails,
          onViewAlertHistory: _viewAlertHistory,
          onViewSuggestionDetails: _viewSuggestionDetails,
          onToggleFavoriteSuggestion: _toggleFavoriteSuggestion,
          onViewAllSuggestions: _viewAllSuggestions,
          onShowRecordingModal: _showRecordingModal,
          onNavigateToSubscription: _navigateToSubscription,
        );
      case 2:
        return TherapistsTab(
          therapistsFuture: _therapistsFuture,
          isLoadingTherapists: _isLoadingTherapists,
          onRefreshTherapists: _loadTherapists,
          onAddTherapistToFavorites: (therapist) {}, // Placeholder
          onViewTherapistProfile: _onViewTherapistProfile,
          onBookAppointment: (therapist) {}, // Placeholder
          onViewAllTherapists: _onViewAllTherapists,
        );
      case 3:
        return MessagesTab(
          conversations: _conversations,
          onOpenConversation: (conversation) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MessageScreen(
                  conversationId: conversation['id'] ?? '',
                  otherUserId: conversation['otherUserId'] ?? '',
                ),
              ),
            );
          },
          onCreateNewMessage: _createNewMessage,
        );
      default:
        return const Center(child: Text("Tab not found"));
    }
  }

  /// Gets a user-friendly error message based on the error type
  void _handleError(String operation, dynamic error) {
    if (!mounted) return;

    debugPrint('Error during $operation: $error');

    setState(() {
      _isLoading = false;
      _loadError = 'Failed to $operation. Please try again.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to $operation: ${error.toString()}'),
        backgroundColor: theme_utils.SeeAppTheme.error,
      ),
    );
  }

  void _onViewTherapistProfile(AppUser therapist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TherapistProfileScreen(therapist: therapist),
      ),
    );
  }

  /// Navigates to the "view all" therapists screen
  void _onViewAllTherapists() {
    // Implementation would go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Viewing all therapists'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}