import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/message.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:see_app/screens/messaging/message_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);
  
  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Conversation> _filteredConversations = [];
  
  late DatabaseService _databaseService;
  late AuthService _authService;
  
  List<Conversation> _conversations = [];
  Map<String, AppUser> _userCache = {};
  bool _isLoading = true;
  StreamSubscription? _conversationsSubscription;
  String? _loadError;
  
  @override
  void initState() {
    super.initState();
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _loadConversations();

    _searchController.addListener(() {
      _filterConversations(_searchController.text);
    });
  }
  
  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
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
              _loadError = 'Failed to load conversations: ${error.toString()}';
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'Failed to load conversations: ${e.toString()}';
        });
      }
    }
  }
  
  void _processConversations(List<Conversation> conversations, String currentUserId) async {
    if (!mounted) return;
    
    List<Conversation> processed = [];
    Map<String, AppUser> userDetails = {};

    for (var conv in conversations) {
      try {
        // Find the other participant
        final otherParticipantId = conv.participants.firstWhere(
          (id) => id != currentUserId, 
          orElse: () => '',
        );

        if (otherParticipantId.isNotEmpty) {
          AppUser? otherUser = userDetails[otherParticipantId];
          if (otherUser == null) {
            otherUser = await _databaseService.getUser(otherParticipantId);
            if (otherUser != null) {
              userDetails[otherParticipantId] = otherUser;
            }
          }

          if (otherUser != null) {
            // Create a map to pass to the conversation tile
            processed.add(conv);
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
      // Re-filter conversations after loading
      _filterConversations(_searchController.text);
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
    
    if (otherUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot open chat: Participant data missing.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    } 
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MessageScreen(
          conversationId: conversation.id,
          otherUserId: otherUser.id,
        ),
      ),
    );
  }
  
  String _formatLastMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      return DateFormat.jm().format(time); // Today: show time
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(time).inDays < 7) {
      return DateFormat.E().format(time); // Weekday
    } else {
      return DateFormat.yMd().format(time); // Full date
    }
  }
  
  void _filterConversations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = List.from(_conversations);
      } else {
        _filteredConversations = _conversations
            .where((conversation) {
              final otherUser = _getOtherUser(conversation);
              if (otherUser == null) return false;
              
              final nameMatch = otherUser.name.toLowerCase().contains(query.toLowerCase());
              final lastMessageMatch = (conversation.lastMessageText ?? '').toLowerCase().contains(query.toLowerCase());
              return nameMatch || lastMessageMatch;
            })
            .toList();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search UI (e.g., show search bar)
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty && _searchController.text.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search conversations...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _filteredConversations.isEmpty && _searchController.text.isNotEmpty
                          ? _buildNoMatchingResultsState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _filteredConversations.length,
                              itemBuilder: (context, index) {
                                final conversation = _filteredConversations[index];
                                final otherUser = _getOtherUser(conversation);
                                
                                if (otherUser == null) {
                                  return const SizedBox.shrink();
                                }
                                
                                return _buildConversationTile(conversation, otherUser);
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewMessageDialog(),
        tooltip: 'New message',
        child: const Icon(Icons.chat),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Start a chat with a therapist or parent',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showNewMessageDialog(),
            icon: const Icon(Icons.add),
            label: const Text('New message'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: theme_utils.SeeAppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoMatchingResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No matching results',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
  
  Widget _buildConversationTile(Conversation conversation, AppUser otherUser) {
    final currentUserId = _authService.currentUser?.id;
    final hasUnread = (conversation.unreadCount[currentUserId] ?? 0) > 0;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: hasUnread
            ? theme_utils.SeeAppTheme.primaryColor
            : Colors.grey.shade300,
        child: Text(
          otherUser.name.isNotEmpty
              ? otherUser.name.substring(0, 1).toUpperCase()
              : '?',
          style: TextStyle(
            color: hasUnread ? Colors.white : Colors.black87,
          ),
        ),
      ),
      title: Text(
        otherUser.name,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        conversation.lastMessageText ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatLastMessageTime(conversation.lastMessageAt),
            style: TextStyle(
              fontSize: 12,
              color: hasUnread
                  ? theme_utils.SeeAppTheme.primaryColor
                  : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme_utils.SeeAppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                (conversation.unreadCount[currentUserId] ?? 0).toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () => _navigateToChat(conversation),
    );
  }
  
  void _showNewMessageDialog() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;
    
    // Get users based on current user's role
    List<AppUser> users = [];
    try {
      if (currentUser.role == UserRole.parent) {
        // If parent, show list of therapists assigned to any of their children
        final children = await _databaseService.getChildrenByParentId(currentUser.id);
        Set<String> therapistIds = {};
        
        // Collect all therapist IDs from children
        for (var child in children) {
          final therapistId = child.additionalInfo['assignedTherapistId'] as String?;
          if (therapistId != null && therapistId.isNotEmpty) {
            therapistIds.add(therapistId);
          }
        }
        
        // If we have assigned therapists, get their user info
        if (therapistIds.isNotEmpty) {
          users = await Future.wait(
            therapistIds.map((id) async {
              final user = await _databaseService.getUser(id);
              return user;
            }),
          ).then((users) => users.whereType<AppUser>().toList());
        } else {
          // If no assigned therapists, show all therapists
          users = await _databaseService.getUsersByRole(UserRole.therapist);
        }
      } else if (currentUser.role == UserRole.therapist) {
        // If therapist, show parents of children assigned to them
        final assignedChildren = await _databaseService.getChildrenByTherapistId(currentUser.id);
        Set<String> parentIds = {};
        
        // Collect all parent IDs from assigned children
        for (var child in assignedChildren) {
          final parentId = child.additionalInfo['parentId'] as String?;
          if (parentId != null && parentId.isNotEmpty) {
            parentIds.add(parentId);
          }
        }
        
        // If we have parents of assigned children, get their user info
        if (parentIds.isNotEmpty) {
          users = await Future.wait(
            parentIds.map((id) async {
              final user = await _databaseService.getUser(id);
              return user;
            }),
          ).then((users) => users.whereType<AppUser>().toList());
        } else {
          // If no specifically assigned parents, show all parents
          users = await _databaseService.getUsersByRole(UserRole.parent);
        }
      }
    } catch (e) {
      debugPrint('Error loading users for messaging: $e');
      // Fallback to all users of the opposite role
      try {
        if (currentUser.role == UserRole.parent) {
          users = await _databaseService.getUsersByRole(UserRole.therapist);
        } else if (currentUser.role == UserRole.therapist) {
          users = await _databaseService.getUsersByRole(UserRole.parent);
        }
      } catch (e) {
        debugPrint('Error loading fallback users: $e');
      }
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Message'),
        content: SizedBox(
          width: double.maxFinite,
          child: users.isEmpty
              ? const Text('No users available to message')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name.substring(0, 1).toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.roleName),
                      onTap: () async {
                        Navigator.pop(context);
                        
                        // Create or get existing conversation
                        try {
                          final conversation = await _databaseService.getOrCreateConversation(
                            currentUser.id,
                            user.id,
                          );
                          
                          // Navigate to chat
                          if (mounted) {
                            debugPrint('Navigating to MessageScreen with conversationId: ${conversation.id}');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MessageScreen(
                                  conversationId: conversation.id,
                                  otherUserId: user.id,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('Error starting conversation: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error starting conversation: ${e.toString()}')),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
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
} 