import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:see_app/services/ai_therapist_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:intl/intl.dart';

/// AI Therapist Section for the Parent Dashboard
class AITherapistSection extends StatefulWidget {
  const AITherapistSection({Key? key}) : super(key: key);

  @override
  State<AITherapistSection> createState() => _AITherapistSectionState();
}

class _AITherapistSectionState extends State<AITherapistSection> {
  final TextEditingController _topicController = TextEditingController();
  bool _isNewChat = false;
  String? _selectedConversationId;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _topicController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AITherapistService>(
      builder: (context, aiService, child) {
        return Card(
          elevation: 4,
          shadowColor: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
          ),
          margin: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  theme_utils.SeeAppTheme.primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(context),
                
                // Selected conversation or new chat interface
                if (_isNewChat)
                  _buildNewChatForm(context, aiService)
                else if (_selectedConversationId != null)
                  _buildConversationView(context, aiService, _selectedConversationId!)
                else
                  _buildConversationsList(context, aiService),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0, duration: 500.ms);
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme_utils.SeeAppTheme.primaryColor,
                  theme_utils.SeeAppTheme.calmColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.psychology_alt,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI Therapist",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Get expert advice on parenting challenges",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: theme_utils.SeeAppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedConversationId != null || _isNewChat)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _selectedConversationId = null;
                  _isNewChat = false;
                });
              },
              tooltip: 'Back to conversations',
            )
          else
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  _isNewChat = true;
                  _topicController.clear();
                });
              },
              tooltip: 'New conversation',
            ),
        ],
      ),
    );
  }

  Widget _buildNewChatForm(BuildContext context, AITherapistService aiService) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What would you like to discuss with Dr. Emma?",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme_utils.SeeAppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _topicController,
            decoration: InputDecoration(
              hintText: "E.g., My child has trouble sleeping",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
              ),
              filled: true,
              fillColor: Colors.white,
              hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
            ),
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: aiService.isLoading
                      ? null
                      : () async {
                          if (_topicController.text.trim().isEmpty) {
                            return;
                          }
                          
                          final conversation = await aiService.startNewConversation(
                            _topicController.text.trim(),
                          );
                          
                          if (conversation.isNotEmpty) {
                            setState(() {
                              _isNewChat = false;
                              _selectedConversationId = conversation['id'];
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
                    ),
                  ),
                  child: aiService.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Start Conversation'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Popular topics:",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestedTopic(context, "Emotional regulation", aiService),
              _buildSuggestedTopic(context, "Bedtime routines", aiService),
              _buildSuggestedTopic(context, "Managing tantrums", aiService),
              _buildSuggestedTopic(context, "Screen time limits", aiService),
              _buildSuggestedTopic(context, "Sibling conflicts", aiService),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedTopic(BuildContext context, String topic, AITherapistService aiService) {
    return InkWell(
      onTap: () {
        setState(() {
          _topicController.text = topic;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.3)),
        ),
        child: Text(
          topic,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : theme_utils.SeeAppTheme.primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationsList(BuildContext context, AITherapistService aiService) {
    if (aiService.conversations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                "No conversations yet",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Start a new conversation with Dr. Emma for expert advice on parenting challenges",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isNewChat = true;
                    _topicController.clear();
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('New Conversation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: aiService.conversations.length,
      itemBuilder: (context, index) {
        final conversation = aiService.conversations[aiService.conversations.length - 1 - index];
        final createdAt = DateTime.parse(conversation['createdAt']);
        final formattedDate = DateFormat('MMM d, h:mm a').format(createdAt);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
            child: Icon(
              Icons.chat,
              color: theme_utils.SeeAppTheme.primaryColor,
            ),
          ),
          title: Text(
            conversation['title'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            formattedDate,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            setState(() {
              _selectedConversationId = conversation['id'];
            });
          },
        );
      },
    );
  }

  Widget _buildConversationView(BuildContext context, AITherapistService aiService, String conversationId) {
    final conversation = aiService.conversations.firstWhere(
      (c) => c['id'] == conversationId,
      orElse: () => {},
    );

    if (conversation.isEmpty) {
      return const Center(child: Text('Conversation not found'));
    }

    final messages = conversation['messages'] as List;
    
    return Column(
      children: [
        // Topic/title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
            ),
            child: Text(
              conversation['title'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme_utils.SeeAppTheme.primaryColor,
              ),
            ),
          ),
        ),
        
        // Messages
        LimitedBox(
          maxHeight: 350,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: messages.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isUser = message['role'] == 'user';
              
              return _buildChatMessage(
                context,
                message['content'],
                isUser,
                message['timestamp'],
              );
            },
          ),
        ),
        
        // Message input
        const SizedBox(height: 8),
        _buildMessageInput(context, aiService, conversationId),
      ],
    );
  }

  Widget _buildChatMessage(
    BuildContext context, 
    String content, 
    bool isUser,
    String timestamp,
  ) {
    final messageTime = DateTime.parse(timestamp);
    final formattedTime = DateFormat('h:mm a').format(messageTime);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) 
            CircleAvatar(
              backgroundColor: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.2),
              radius: 16,
              child: Text(
                'Dr',
                style: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.bold,
                  color: theme_utils.SeeAppTheme.primaryColor,
                ),
              ),
            ),
          
          SizedBox(width: isUser ? 0 : 8),
          
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? theme_utils.SeeAppTheme.primaryColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius:
                             4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    formattedTime,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: isUser ? 8 : 0),
          
          if (isUser)
            CircleAvatar(
              backgroundColor: theme_utils.SeeAppTheme.calmColor.withOpacity(0.2),
              radius: 16,
              child: const Icon(
                Icons.person,
                size: 18,
                color: theme_utils.SeeAppTheme.calmColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(
    BuildContext context,
    AITherapistService aiService,
    String conversationId,
  ) {
    final TextEditingController messageController = TextEditingController();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              minLines: 1,
              maxLines: 4,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            backgroundColor: theme_utils.SeeAppTheme.primaryColor,
            onPressed: aiService.isLoading
                ? null
                : () async {
                    final message = messageController.text.trim();
                    if (message.isEmpty) return;
                    
                    // Clear input field early for better UX
                    messageController.clear();
                    
                    // Scroll to bottom after a short delay
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                    
                    await aiService.sendMessage(conversationId, message);
                    
                    // Scroll to bottom again after response
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  },
            child: aiService.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

/// Dialog for asking AI Therapist a quick question
class QuickAITherapistDialog extends StatefulWidget {
  const QuickAITherapistDialog({Key? key}) : super(key: key);

  @override
  State<QuickAITherapistDialog> createState() => _QuickAITherapistDialogState();
}

class _QuickAITherapistDialogState extends State<QuickAITherapistDialog> {
  final TextEditingController _questionController = TextEditingController();
  String? _response;
  bool _isLoading = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                  child: const Icon(
                    Icons.psychology_alt,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ask Dr. Emma',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Get a quick response to your parenting question',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme_utils.SeeAppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'What would you like to know?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 3,
              minLines: 2,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final question = _questionController.text.trim();
                        if (question.isEmpty) return;
                        
                        setState(() {
                          _isLoading = true;
                        });
                        
                        final aiService = Provider.of<AITherapistService>(
                          context,
                          listen: false,
                        );
                        
                        final response = await aiService.getSuggestedResponse(question);
                        
                        setState(() {
                          _response = response;
                          _isLoading = false;
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Get Answer'),
              ),
            ),
            if (_response != null) ...[
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
                      border: Border.all(
                        color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.2),
                              child: Text(
                                'Dr',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme_utils.SeeAppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Dr. Emma',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme_utils.SeeAppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(_response!),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              // Close this dialog and open a full conversation
                              Navigator.of(context).pop();
                              
                              // Start a new AI conversation (using the question as topic)
                              final aiService = Provider.of<AITherapistService>(
                                context,
                                listen: false,
                              );
                              
                              aiService.startNewConversation(_questionController.text.trim());
                              
                              // Show a notification that a conversation was started
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Conversation started in AI Therapist section'),
                                  action: SnackBarAction(
                                    label: 'View',
                                    onPressed: () {
                                      // Scroll to the AI Therapist section (would need to be implemented)
                                    },
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat, size: 16),
                            label: const Text('Continue in full conversation'),
                            style: TextButton.styleFrom(
                              foregroundColor: theme_utils.SeeAppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
