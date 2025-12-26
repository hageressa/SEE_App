import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of message content
enum MessageType {
  text,  // Simple text message
  image, // Image attachment
  file,  // Document or file attachment
}

/// Message model representing a single message between users
class Message {
  final String id;
  final String senderId;      // ID of the user who sent the message
  final String receiverId;    // ID of the user who receives the message
  final String conversationId; // ID of the conversation this message belongs to
  final String content;       // Message content (text or file URL)
  final MessageType type;     // Type of message
  final DateTime timestamp;   // When the message was sent
  final bool isRead;          // Whether the message has been read by the receiver
  final Map<String, dynamic>? metadata; // Additional information like file size, image dimensions, etc.

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.conversationId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  /// Create a Message from Firestore data
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      conversationId: data['conversationId'] ?? '',
      content: data['content'] ?? '',
      type: _parseMessageType(data['type']),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      metadata: data['metadata'],
    );
  }

  /// Convert Message to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'conversationId': conversationId,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  /// Parse MessageType from string
  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'text':
      default:
        return MessageType.text;
    }
  }

  /// Create a copy of this Message with modified properties
  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? conversationId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Conversation model representing a chat thread between two users
class Conversation {
  final String id;
  final List<String> participants; // IDs of users participating in the conversation
  final DateTime createdAt;        // When the conversation was created
  final DateTime lastMessageAt;    // When the last message was sent
  final String? lastMessageText;   // Preview of the last message
  final Map<String, int> unreadCount; // Count of unread messages per user
  final String status;            // Conversation status (active, archived, etc.)
  final Message? lastMessage;      // Last message in the conversation (optional)
  final Map<String, dynamic>? metadata; // Additional data like childId, childName, etc.

  const Conversation({
    required this.id,
    required this.participants,
    required this.createdAt,
    required this.lastMessageAt,
    this.lastMessageText,
    this.unreadCount = const {},
    this.status = 'active',
    this.lastMessage,
    this.metadata,
  });

  /// Create a Conversation from Firestore data
  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Last message handling
    Message? lastMsg;
    if (data['lastMessage'] != null) {
      try {
        lastMsg = Message(
          id: data['lastMessage']['id'] ?? '',
          senderId: data['lastMessage']['senderId'] ?? '',
          receiverId: data['lastMessage']['receiverId'] ?? '',
          conversationId: doc.id,
          content: data['lastMessage']['content'] ?? '',
          type: Message._parseMessageType(data['lastMessage']['type']),
          timestamp: (data['lastMessage']['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['lastMessage']['isRead'] ?? false,
        );
      } catch (e) {
        print('Error parsing lastMessage: $e');
      }
    }
    
    return Conversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageText: data['lastMessageText'],
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      status: data['status'] ?? 'active',
      lastMessage: lastMsg,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert Conversation to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'lastMessageText': lastMessageText,
      'unreadCount': unreadCount,
      'status': status,
      'lastMessage': lastMessage?.toFirestore(),
      'metadata': metadata,
    };
  }

  /// Create a copy of this Conversation with modified properties
  Conversation copyWith({
    String? id,
    List<String>? participants,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? lastMessageText,
    Map<String, int>? unreadCount,
    String? status,
    Message? lastMessage,
    Map<String, dynamic>? metadata,
  }) {
    return Conversation(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      unreadCount: unreadCount ?? this.unreadCount,
      status: status ?? this.status,
      lastMessage: lastMessage ?? this.lastMessage,
      metadata: metadata ?? this.metadata,
    );
  }
}