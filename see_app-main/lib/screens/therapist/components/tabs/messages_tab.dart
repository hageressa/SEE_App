import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/models/message.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

class MessagesTab extends StatefulWidget {
  final List<Conversation> conversations;
  final List<Child> patients;
  final bool isLoading;
  final Function(String, BuildContext) onOpenConversation;
  final Function(BuildContext) onCreateNewMessage;

  const MessagesTab({
    Key? key,
    required this.conversations,
    required this.patients,
    required this.isLoading,
    required this.onOpenConversation,
    required this.onCreateNewMessage,
  }) : super(key: key);

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildTabBar(),
        _buildSearchBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildConversationsList(filterActive: true),
              _buildConversationsList(filterActive: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark 
          ? theme_utils.SeeAppTheme.darkSecondaryBackground 
          : theme_utils.SeeAppTheme.primaryColor,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        indicatorColor: theme_utils.SeeAppTheme.accentColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'Archived'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildConversationsList({required bool filterActive}) {
    // Filter conversations based on active/archived status and search query
    final filteredConversations = widget.conversations.where((conv) {
      // First filter by active/archived
      if (filterActive != (conv.status == 'active')) {
        return false;
      }
      
      // Then by search query
      if (_searchQuery.isEmpty) {
        return true;
      }
      
      // Search by participant name or message content
      final otherParticipantId = conv.participants
          .firstWhere((p) => p != 'therapist_id', orElse: () => '');
          
      final patient = widget.patients.firstWhere(
        (p) => p.id == otherParticipantId,
        orElse: () => Child(
          id: '',
          name: 'Unknown',
          age: 0,
          gender: 'Unknown',
          parentId: '',
          concerns: [],
        ),
      );
      
      final searchLower = _searchQuery.toLowerCase();
      if (patient.name.toLowerCase().contains(searchLower)) {
        return true;
      }
      
      // Check last message content
      if (conv.lastMessage?.content.toLowerCase().contains(searchLower) ?? false) {
        return true;
      }
      
      return false;
    }).toList();

    if (filteredConversations.isEmpty) {
      return _buildEmptyState(filterActive);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = filteredConversations[index];
        return _buildConversationTile(conversation);
      },
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final otherParticipantId = conversation.participants
        .firstWhere((p) => p != 'therapist_id', orElse: () => '');
        
    // First try to get the name from metadata
    final userNames = conversation.metadata?['userNames'] as Map<String, dynamic>?;
    final otherUserName = userNames?[otherParticipantId] as String?;
    
    // If not in metadata, try to get from patients list
    String displayName;
    if (otherUserName != null) {
      displayName = otherUserName;
    } else {
      final patient = widget.patients.firstWhere(
        (p) => p.id == otherParticipantId,
        orElse: () => Child(
          id: '',
          name: 'Unknown',
          age: 0,
          gender: 'Unknown',
          parentId: '',
          concerns: [],
        ),
      );
      displayName = patient.name;
    }
    
    final lastMessageTime = conversation.lastMessage?.timestamp ?? DateTime.now();
    final formattedTime = _formatMessageTime(lastMessageTime);
    final hasUnread = conversation.unreadCount.isNotEmpty && 
                      conversation.unreadCount.values.any((count) => count > 0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: hasUnread ? 2 : 1,
      color: hasUnread 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.05) 
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => widget.onOpenConversation(conversation.id, context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0] : '?',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme_utils.SeeAppTheme.accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${conversation.unreadCount.values.reduce((a, b) => a + b)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            color: hasUnread
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.lastMessage?.content ?? 'No messages',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasUnread ? null : Colors.grey[600],
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 50.ms * (widget.conversations.indexOf(conversation) % 10));
  }

  Widget _buildEmptyState(bool isActive) {
    final message = isActive
        ? 'No active conversations'
        : 'No archived conversations';
        
    final subMessage = isActive
        ? 'Start a new conversation with a patient'
        : 'Conversations you archive will appear here';
        
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Icons.chat_bubble_outline : Icons.archive_outlined,
              size: 60,
              color: theme_utils.SeeAppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (isActive) const SizedBox(height: 24),
          if (isActive)
            ElevatedButton.icon(
              onPressed: () => widget.onCreateNewMessage(context),
              icon: const Icon(Icons.add),
              label: const Text('Start Conversation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0));
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      return DateFormat('h:mm a').format(time);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(time).inDays < 7) {
      return DateFormat('EEEE').format(time); // Day name
    } else {
      return DateFormat('MMM d').format(time); // Month and day
    }
  }
}
