import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/models/message.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/screens/messaging/message_screen.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:see_app/screens/parent/parent_dashboard.dart';

/// Messages tab for chat conversations with therapists
class MessagesTab extends StatefulWidget {
  final List<Map<String, dynamic>> conversations;
  final Function(Map<String, dynamic>) onOpenConversation;
  final Function(BuildContext) onCreateNewMessage;

  const MessagesTab({
    super.key,
    required this.conversations,
    required this.onOpenConversation,
    required this.onCreateNewMessage,
  });

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredConversations = [];
  bool _isLoading = false;
  List<Child> _children = [];
  Map<String, AppUser> _therapists = {};
  late DatabaseService _databaseService;
  late AuthService _authService;
  List<Conversation> _conversations = [];
  Map<String, AppUser> _userCache = {};
  StreamSubscription? _conversationsSubscription;
  
  @override
  void initState() {
    super.initState();
    _filteredConversations = List.from(widget.conversations);
    _searchController.addListener(() {
      _filterConversations(_searchController.text);
    });
    _loadTherapistsAndChildren();
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _loadConversations();
  }
  
  @override
  void didUpdateWidget(MessagesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.conversations != oldWidget.conversations) {
      _filterConversations(_searchController.text);
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _conversationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTherapistsAndChildren() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Load children
      final children = await databaseService.getChildrenByParentId(currentUser.id);
      
      // Load therapists for each child
      Map<String, AppUser> therapists = {};
      for (var child in children) {
        final therapistId = child.additionalInfo['assignedTherapistId'] as String?;
        if (therapistId != null && !therapists.containsKey(therapistId)) {
          final therapist = await databaseService.getUser(therapistId);
          if (therapist != null) {
            therapists[therapistId] = therapist;
          }
        }
      }

      if (mounted) {
        setState(() {
          _children = children;
          _therapists = therapists;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading therapists and children: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _filterConversations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = List.from(widget.conversations);
      } else {
        _filteredConversations = widget.conversations
            .where((conversation) => 
                conversation['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
                conversation['lastMessage'].toString().toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }

      _conversationsSubscription = _databaseService.subscribeToConversations(
        currentUser.id,
        (conversations) {
          _processConversations(conversations, currentUser.id);
        },
        onError: (error) {
          debugPrint('Error in conversations subscription: $error');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _processConversations(List<Conversation> conversations, String currentUserId) async {
    if (!mounted) return;

    List<Conversation> processed = [];
    Map<String, AppUser> userDetails = Map.from(_userCache);

    for (var conv in conversations) {
      try {
        // Find the other participant
        final otherParticipantId = conv.participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );

        if (otherParticipantId.isNotEmpty) {
          // First try to get the name from metadata
          final userNames = conv.metadata?['userNames'] as Map<String, dynamic>?;
          final userRoles = conv.metadata?['userRoles'] as Map<String, dynamic>?;
          final otherUserName = userNames?[otherParticipantId] as String?;
          final otherUserRole = userRoles?[otherParticipantId] as String?;
          
          if (otherUserName != null) {
            // If we have the name in metadata, create a user object
            userDetails[otherParticipantId] = AppUser(
              id: otherParticipantId,
              name: otherUserName,
              email: '', // We don't need email for display
              role: _parseRole(otherUserRole), // Parse role from metadata or default to parent
              createdAt: DateTime.now(), // Use current time since this is just for display
            );
            processed.add(conv);
          } else {
            // Fallback to fetching user details if not in metadata
            AppUser? otherUser = userDetails[otherParticipantId];
            if (otherUser == null) {
              otherUser = await _databaseService.getUser(otherParticipantId);
              if (otherUser != null) {
                userDetails[otherParticipantId] = otherUser;
                
                // Update conversation metadata with user names if missing
                if (conv.metadata == null || conv.metadata!['userNames'] == null) {
                  final currentUser = await _databaseService.getUser(currentUserId);
                  if (currentUser != null) {
                    await _databaseService.updateConversationMetadata(conv.id, {
                      ...conv.metadata ?? {},
                      'userNames': {
                        currentUserId: currentUser.name,
                        otherParticipantId: otherUser.name,
                      },
                      'userRoles': {
                        currentUserId: currentUser.role.toString().split('.').last,
                        otherParticipantId: otherUser.role.toString().split('.').last,
                      },
                    });
                  }
                }
              }
            }

            if (otherUser != null) {
              processed.add(conv);
            }
          }
        }
      } catch (e) {
        debugPrint('Error processing conversation ${conv.id}: $e');
      }
    }

    if (mounted) {
      setState(() {
        _conversations = processed;
        _userCache = userDetails;
        _isLoading = false;
      });
    }
  }

  // Helper method to parse role from string
  UserRole _parseRole(String? roleStr) {
    switch (roleStr?.toLowerCase()) {
      case 'therapist':
        return UserRole.therapist;
      case 'admin':
        return UserRole.admin;
      case 'parent':
      default:
        return UserRole.parent;
    }
  }

  AppUser? _getOtherUser(Conversation conversation) {
    final currentUserId = _authService.currentUser?.id;
    if (currentUserId == null) return null;

    final otherParticipantId = conversation.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherParticipantId.isEmpty) return null;

    return _userCache[otherParticipantId];
  }

  void _navigateToChat(Conversation conversation) {
    final otherUser = _getOtherUser(conversation);
    if (otherUser == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MessageScreen(
          conversationId: conversation.id,
          otherUserId: otherUser.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: theme_utils.SeeAppTheme.spacing16,
              vertical: theme_utils.SeeAppTheme.spacing8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey.shade600),
                const SizedBox(width: theme_utils.SeeAppTheme.spacing8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search conversations...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Children and their therapists
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _children.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: theme_utils.SeeAppTheme.spacing16),
                      itemCount: _children.length,
                      itemBuilder: (context, index) {
                        final child = _children[index];
                        final therapistId = child.additionalInfo['assignedTherapistId'] as String?;
                        final therapist = therapistId != null ? _therapists[therapistId] : null;
                        
                        return _buildChildTherapistCard(child, therapist);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
          Text(
            'No therapists assigned yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
          Text(
            'Add a therapist to start messaging',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to therapists tab using the parent widget's callback
              widget.onCreateNewMessage(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Find a Therapist'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme_utils.SeeAppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: theme_utils.SeeAppTheme.spacing24,
                vertical: theme_utils.SeeAppTheme.spacing12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildTherapistCard(Child child, AppUser? therapist) {
    return Card(
      margin: const EdgeInsets.only(bottom: theme_utils.SeeAppTheme.spacing16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Child info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    child.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: theme_utils.SeeAppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: theme_utils.SeeAppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${child.age} years old',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (therapist != null) ...[
              const Divider(height: 32),
              // Therapist info
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.1),
                    child: Text(
                      therapist.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: theme_utils.SeeAppTheme.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: theme_utils.SeeAppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          therapist.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          therapist.additionalInfo?['specialty'] ?? 'Therapist',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final databaseService = Provider.of<DatabaseService>(context, listen: false);
                      final authService = Provider.of<AuthService>(context, listen: false);
                      final currentUser = authService.currentUser;

                      if (currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please log in to message therapists')),
                        );
                        return;
                      }

                      try {
                        final conversation = await databaseService.getOrCreateConversation(
                          currentUser.id,
                          therapist.id,
                          metadata: {
                            'childId': child.id,
                            'childName': child.name,
                          },
                        );

                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MessageScreen(
                                conversationId: conversation.id,
                                otherUserId: therapist.id,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error opening chat: ${e.toString()}')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: theme_utils.SeeAppTheme.spacing16,
                        vertical: theme_utils.SeeAppTheme.spacing8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    // Navigate to therapists tab using the parent widget's callback
                    widget.onCreateNewMessage(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Assign a Therapist'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme_utils.SeeAppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final currentUserId = _authService.currentUser?.id;
    if (currentUserId == null) return const SizedBox.shrink();

    final otherParticipantId = conversation.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherParticipantId.isEmpty) return const SizedBox.shrink();

    // First try to get the name from metadata
    final userNames = conversation.metadata?['userNames'] as Map<String, dynamic>?;
    String otherUserName = userNames?[otherParticipantId] as String? ?? '';
    
    // If not in metadata, try to get from user cache
    if (otherUserName.isEmpty) {
      final otherUser = _userCache[otherParticipantId];
      otherUserName = otherUser?.name ?? 'Unknown';
    }

    final hasUnread = (conversation.unreadCount[currentUserId] ?? 0) > 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme_utils.SeeAppTheme.primaryColor,
        child: Text(
          otherUserName.isNotEmpty
              ? otherUserName.substring(0, 1).toUpperCase()
              : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        otherUserName,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conversation.metadata?['childName'] != null)
            Text(
              'Re: ${conversation.metadata!['childName']}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          Text(
            conversation.lastMessageText ?? 'No messages yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      trailing: hasUnread
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme_utils.SeeAppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                (conversation.unreadCount[currentUserId] ?? 0).toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: () => _navigateToChat(conversation),
    );
  }
}