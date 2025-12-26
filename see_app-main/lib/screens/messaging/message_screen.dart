import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/message.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

class MessageScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  
  const MessageScreen({
    Key? key,
    required this.conversationId,
    required this.otherUserId,
  }) : super(key: key);
  
  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late DatabaseService _databaseService;
  late AuthService _authService;
  
  AppUser? _otherUser;
  AppUser? _currentUser;
  List<Message> _messages = [];
  bool _isLoading = true;
  StreamSubscription? _messagesSubscription;
  String? _childId;
  String? _childName;
  
  @override
  void initState() {
    super.initState();
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _initializeChat();
  }
  
  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current user
      _currentUser = _authService.currentUser;
      if (_currentUser == null) {
        throw Exception("User not authenticated");
      }
      
      // Get other user details
      _otherUser = await _databaseService.getUser(widget.otherUserId);
      
      // Get conversation details
      final conversation = await _databaseService.getConversation(widget.conversationId);
      
      // Check if conversation has childId in metadata
      String? childId = conversation?.metadata?['childId'] as String?;
      String? childName = conversation?.metadata?['childName'] as String?;
      
      // If no child info in conversation, try to find the connection
      if ((childId == null || childName == null) && 
         (_currentUser!.role == UserRole.parent || _otherUser?.role == UserRole.parent)) {
        
        // Get the parent ID (either current user or other user)
        final parentId = _currentUser!.role == UserRole.parent 
            ? _currentUser!.id 
            : _otherUser!.id;
            
        // Get the therapist ID (either current user or other user)
        final therapistId = _currentUser!.role == UserRole.therapist 
            ? _currentUser!.id 
            : _otherUser!.id;
        
        // Get children for the parent
        final children = await _databaseService.getChildrenByParentId(parentId);
        
        // Find child assigned to the therapist
        for (final child in children) {
          if (child.additionalInfo['assignedTherapistId'] == therapistId) {
            childId = child.id;
            childName = child.name;
            
            // Update conversation with child info for future reference
            if (conversation != null) {
              await _databaseService.updateConversationMetadata(
                widget.conversationId, 
                {'childId': childId, 'childName': childName}
              );
            }
            break;
          }
        }
      }
      
      // Store child info in state
      if (childId != null && childName != null) {
        setState(() {
          _childId = childId;
          _childName = childName;
        });
      }
      
      // Subscribe to messages
      _messagesSubscription = _databaseService.subscribeToMessages(
        widget.conversationId,
        (messages) {
          setState(() {
            _messages = messages;
            _isLoading = false;
          });
          
          // Mark messages as read when they are loaded
          if (messages.isNotEmpty && _currentUser != null) {
            _markMessagesAsRead(messages, _currentUser!.id);
          }

          // Scroll to bottom on new messages
          if (_scrollController.hasClients) {
            Future.delayed(const Duration(milliseconds: 100), () {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            });
          }
        },
        onError: (error) {
          debugPrint('Error in messages subscription: $error');
          setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      debugPrint('Error initializing chat: $e');
      setState(() => _isLoading = false);
    }
  }
  
  /// Marks messages as read for the current user
  Future<void> _markMessagesAsRead(List<Message> messages, String userId) async {
    final unreadMessages = messages.where((msg) => !msg.isRead && msg.receiverId == userId).toList();
    if (unreadMessages.isEmpty) return;

    try {
      for (final msg in unreadMessages) {
        await _databaseService.markMessageAsRead(msg.id);
      }
      // Update conversation's unread count in Firestore
      await _databaseService.updateConversationUnreadCount(
        widget.conversationId, 
        userId, 
        0
      );
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }
  
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _currentUser == null || _otherUser == null) return;
    
    _messageController.clear();
    
    try {
      await _databaseService.sendMessage(
        senderId: _currentUser!.id,
        receiverId: _otherUser!.id,
        conversationId: widget.conversationId,
        content: messageText,
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _otherUser != null
            ? Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                    child: Text(
                      _otherUser!.name.isNotEmpty
                          ? _otherUser!.name.substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _otherUser!.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Text(
                              _otherUser!.roleName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            if (_childName != null) ...[
                              Text(
                                ' • ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Re: $_childName',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.7),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showContactInfo(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyChat()
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isUserMessage = message.senderId == _currentUser?.id;
                            
                            return _buildMessageBubble(message, isUserMessage);
                          },
                        ),
                ),
                _buildMessageInput(),
              ],
            ),
    );
  }
  
  Widget _buildEmptyChat() {
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
            'No messages yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(Message message, bool isUserMessage) {
    final backgroundColor = isUserMessage
        ? theme_utils.SeeAppTheme.primaryColor
        : Colors.grey.shade200;
    
    final textColor = isUserMessage ? Colors.white : Colors.black87;
    
    final timeFormat = DateFormat.jm();
    final timeString = timeFormat.format(message.timestamp);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUserMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUserMessage && _otherUser != null) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme_utils.SeeAppTheme.secondaryColor,
              child: Text(
                _otherUser!.name.isNotEmpty
                    ? _otherUser!.name.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeString,
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUserMessage) const SizedBox(width: 8),
        ],
      ),
    );
  }
  
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () {
                // Attachment feature placeholder
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attachment feature coming soon')),
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                ),
                style: TextStyle(color: Colors.black87),
                cursorColor: Colors.black87,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              color: theme_utils.SeeAppTheme.primaryColor,
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showContactInfo() {
    if (_otherUser == null) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                child: Text(
                  _otherUser!.name.isNotEmpty
                      ? _otherUser!.name.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 28),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _otherUser!.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(_otherUser!.roleName),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.video_call),
                title: const Text('Video Consultation'),
                subtitle: const Text('Start a video call (Coming Soon)'),
                onTap: () {
                  Navigator.pop(context);
                  _initiateVideoCall();
                },
              ),
              if (_otherUser?.role == UserRole.therapist)
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Book Appointment'),
                  subtitle: const Text('Schedule a session'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToAppointmentBooking();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  
  void _initiateVideoCall() {
    // Placeholder for video call functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Consultation'),
        content: const Text(
          'Video consultation feature will be available in a future update. This placeholder is for UI demonstration purposes.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _navigateToAppointmentBooking() {
    // Navigate to appointment booking screen
    Navigator.pushNamed(
      context, 
      '/appointments/book',
      arguments: {'therapistId': _otherUser?.id},
    );
  }
} 