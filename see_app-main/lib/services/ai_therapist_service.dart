import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// AI Therapist service using Gemini API
class AITherapistService extends ChangeNotifier {
  // Use the same API key as GeminiService for consistency
  static const String _apiKey = 'AIzaSyAxAlWAEZLLxzUV2xXtmir3hPQudFs1Apo';
  // Updated URL to use the correct endpoint format
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$_apiKey';
  
  final List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> get conversations => _conversations;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;
  
  // Conversation history
  List<Map<String, String>> _history = [];
  
  // Therapist profile
  final Map<String, String> _therapistProfile = {
    'name': 'Dr. Emma',
    'expertise': 'Child development, emotional intelligence, and parenting strategies',
    'style': 'Empathetic, supportive, and practical',
    'approach': 'I combine evidence-based techniques with compassionate guidance to help parents navigate challenges and build stronger connections with their children.'
  };
  
  AITherapistService();
  
  /// Load conversation history from SharedPreferences
  Future<void> loadConversationHistory() async {
    try {
      // Try to use Firebase Auth if available
      String storageKey = 'ai_therapist_history';
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          storageKey = 'ai_therapist_history_$userId';
        }
      } catch (e) {
        debugPrint('Firebase auth not available, using default storage key: $e');
      }
      
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(storageKey);
      
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _conversations.clear();
        _conversations.addAll(
          decoded.map((item) => item as Map<String, dynamic>).toList()
        );
        
        // Load the most recent conversation into history for context
        if (_conversations.isNotEmpty) {
          final recentConvo = _conversations.last;
          final List<dynamic> messages = recentConvo['messages'];
          
          _history = messages.map<Map<String, String>>((msg) => {
            'role': msg['role'],
            'content': msg['content'],
          }).toList();
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading AI therapist history: $e');
    }
  }
  
  /// Save conversation history to SharedPreferences
  Future<void> _saveConversationHistory() async {
    try {
      // Try to use Firebase Auth if available
      String storageKey = 'ai_therapist_history';
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          storageKey = 'ai_therapist_history_$userId';
        }
      } catch (e) {
        debugPrint('Firebase auth not available, using default storage key: $e');
      }
      
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(_conversations);
      await prefs.setString(storageKey, historyJson);
    } catch (e) {
      debugPrint('Error saving AI therapist history: $e');
    }
  }
  
  /// Start a new conversation with the AI Therapist
  Future<Map<String, dynamic>> startNewConversation(String topic) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Clear history for a new conversation
      _history = [];
      
      // Get initial message from the AI
      final initialPrompt = '''
You are Dr. Emma, a child development and parenting expert AI assistant. 
Your expertise is in: ${_therapistProfile['expertise']}
Your approach: ${_therapistProfile['approach']}

Please provide a supportive, brief (2-3 sentences) response to start a conversation with a parent who wants to discuss: "$topic".
Keep your response conversational, warm, and concise. Don't offer specific advice yet, just open the conversation naturally.
''';

      final response = await _sendMessageToGemini(initialPrompt);
      
      if (response != null) {
        // Create a new conversation
        final conversation = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': topic,
          'createdAt': DateTime.now().toIso8601String(),
          'messages': [
            {
              'id': '1',
              'role': 'user',
              'content': topic,
              'timestamp': DateTime.now().toIso8601String(),
            },
            {
              'id': '2',
              'role': 'assistant',
              'content': response,
              'timestamp': DateTime.now().toIso8601String(),
            }
          ]
        };
        
        // Add to history for context in future messages
        _history = [
          {'role': 'user', 'content': topic},
          {'role': 'assistant', 'content': response},
        ];
        
        _conversations.add(conversation);
        _saveConversationHistory();
        
        _isLoading = false;
        notifyListeners();
        return conversation;
      } else {
        throw Exception('Failed to get response from AI');
      }
    } catch (e) {
      _error = 'Error starting conversation: $e';
      _isLoading = false;
      notifyListeners();
      return {};
    }
  }
  
  /// Send a message to an existing conversation
  Future<String?> sendMessage(String conversationId, String message) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Find the conversation
      final convoIndex = _conversations.indexWhere((c) => c['id'] == conversationId);
      if (convoIndex == -1) {
        throw Exception('Conversation not found');
      }
      
      // Add user message to the conversation
      final messageId = (_conversations[convoIndex]['messages'].length + 1).toString();
      final userMessage = {
        'id': messageId,
        'role': 'user',
        'content': message,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _conversations[convoIndex]['messages'].add(userMessage);
      
      // Add to context history (keep last 10 messages for context)
      _history.add({'role': 'user', 'content': message});
      if (_history.length > 10) {
        _history = _history.sublist(_history.length - 10);
      }
      
      // Prepare the prompt with conversation history
      final prompt = '''
You are Dr. Emma, a child development and parenting expert AI assistant.
Your expertise is in: ${_therapistProfile['expertise']}
Your approach: ${_therapistProfile['approach']}

This is a conversation with a parent about: "${_conversations[convoIndex]['title']}".

Please provide a helpful, supportive, and concise response to their message. Offer practical advice when appropriate.
Remember to keep responses relatively brief (3-5 sentences) unless a detailed explanation is needed.
''';

      // Construct full context
      final String fullContext = prompt + "\n\nCONVERSATION HISTORY:\n" + 
        _history.map((m) => "${m['role'] == 'user' ? 'Parent' : 'Dr. Emma'}: ${m['content']}").join("\n");
      
      // Send to Gemini
      final aiResponse = await _callGeminiWithRetries(fullContext);
      
      if (aiResponse != null) {
        // Add AI response to conversation
        final aiMessageId = (_conversations[convoIndex]['messages'].length + 1).toString();
        final assistantMessage = {
          'id': aiMessageId,
          'role': 'assistant',
          'content': aiResponse,
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        _conversations[convoIndex]['messages'].add(assistantMessage);
        
        // Add to context history
        _history.add({'role': 'assistant', 'content': aiResponse});
        if (_history.length > 10) {
          _history = _history.sublist(_history.length - 10);
        }
        
        _saveConversationHistory();
        
        _isLoading = false;
        notifyListeners();
        return aiResponse;
      } else {
        throw Exception('Failed to get response from AI');
      }
    } catch (e) {
      _error = 'Error sending message: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Delete a conversation
  void deleteConversation(String conversationId) {
    _conversations.removeWhere((c) => c['id'] == conversationId);
    _saveConversationHistory();
    notifyListeners();
  }
  
  /// Clear all conversations
  void clearAllConversations() {
    _conversations.clear();
    _saveConversationHistory();
    notifyListeners();
  }
  
  /// Call the Gemini API with automatic retries
  Future<String?> _callGeminiWithRetries(String prompt) async {
    final int maxRetries = 3;
    String? response;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('API call attempt $attempt...');
        response = await _sendMessageToGemini(prompt);
        
        if (response != null && response.isNotEmpty) {
          return response;
        }
      } catch (e) {
        debugPrint('API call attempt $attempt failed: $e');
        // Wait before retrying, increasing delay each time
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }
    
    // If still no response after retries, use fallback
    final fallbackResponse = _getFallbackResponse(prompt);
    debugPrint('Using fallback response');
    return fallbackResponse;
  }
  
  /// Get a fallback response based on the question
  String _getFallbackResponse(String question) {
    // Prepare question categories and responses
    final Map<List<String>, List<String>> responseMap = {
      ['tantrum', 'meltdown', 'upset', 'crying', 'angry']: [
        "For managing meltdowns or tantrums, try creating a calming space with minimal sensory input. Use visual supports to help your child communicate their feelings. Maintain a calm demeanor yourself, as children can pick up on your emotional state.",
        "When your child is upset, first ensure they're safe, then help them identify their emotions with simple language. 'You seem angry because...' can help them connect feelings with situations.",
      ],
      ['learn', 'teach', 'education', 'school']: [
        "Children with Down syndrome often learn best through visual aids, repetition, and breaking tasks into smaller steps. Consider using picture cards, consistent routines, and lots of positive reinforcement.",
        "For educational support, focus on your child's specific strengths. Many children with Down syndrome have good visual memory, so techniques that capitalize on this can be particularly effective.",
      ],
      ['social', 'friends', 'interaction']: [
        "To help develop social skills, arrange structured playdates with understanding peers. Role-playing social scenarios at home can also help practice appropriate responses.",
        "Social stories can be very effective for teaching social norms. These are short descriptions of social situations that explain what happens and why, preparing your child for new experiences.",
      ],
      ['sleep', 'bedtime', 'night', 'rest']: [
        "Establishing a consistent bedtime routine can significantly improve sleep patterns. Consider including calming activities like a warm bath, quiet reading, and dimmed lights.",
        "Many children with Down syndrome may have sleep apnea or other sleep disturbances. If you notice unusual breathing patterns, excessive snoring, or daytime sleepiness, consider consulting with a sleep specialist.",
      ],
      ['communication', 'speech', 'talk', 'language']: [
        "Many children with Down syndrome benefit from learning sign language alongside spoken language. This can reduce frustration while speech develops.",
        "For communication development, focus on functional words first - those that help your child express immediate needs and interests. Use clear, simple language and give plenty of time for processing responses.",
      ],
    };
    
    // Find the most relevant category
    String bestResponse = "I understand parenting can be challenging. While I can't access specific advice right now, consistent routines, positive reinforcement, and focusing on your child's unique strengths are generally helpful approaches. Consider reaching out to your child's therapist or support group for personalized guidance.";
    
    for (final entry in responseMap.entries) {
      final keywords = entry.key;
      final responses = entry.value;
      
      for (final keyword in keywords) {
        if (question.toLowerCase().contains(keyword.toLowerCase())) {
          // Return a random response from the matching category
          return responses[DateTime.now().millisecondsSinceEpoch % responses.length];
        }
      }
    }
    
    return bestResponse;
  }
  
  /// Send a message to the Gemini API
  Future<String?> _sendMessageToGemini(String prompt) async {
    try {
      debugPrint('Sending request to Gemini API: ${_baseUrl}');
      
      // Add a timeout to prevent hanging requests
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      debugPrint('Gemini API status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          
          // Check if there are any candidates in the response
          if (data['candidates'] != null && 
              data['candidates'].isNotEmpty) {
            
            // Check if content is available
            if (data['candidates'][0]['content'] != null &&
                data['candidates'][0]['content']['parts'] != null &&
                data['candidates'][0]['content']['parts'].isNotEmpty) {
              
              // Extract the text from the response
              final String text = data['candidates'][0]['content']['parts'][0]['text'];
              return text;
            } else if (data['promptFeedback'] != null && 
                      data['promptFeedback']['blockReason'] != null) {
              // Handle safety block
              debugPrint('Response blocked for safety: ${data['promptFeedback']['blockReason']}');
              return "I'm sorry, I cannot respond to that question. Please try a different topic related to child development or parenting.";
            }
          }
          
          // Generic data parsing issue
          debugPrint('No valid response data from Gemini API: ${response.body}');
          return "I'm sorry, I couldn't generate a response at this time. Please try again later.";
        } catch (e) {
          debugPrint('Error parsing Gemini API response: $e');
          return "I'm sorry, I couldn't process the response. Please try again later.";
        }
      } else if (response.statusCode == 400) {
        // Bad request
        debugPrint('Bad request: ${response.body}');
        try {
          final data = jsonDecode(response.body);
          if (data['error'] != null && data['error']['message'] != null) {
            debugPrint('Error message: ${data['error']['message']}');
          }
        } catch (e) {
          debugPrint('Could not parse error: $e');
        }
        return "Sorry, I'm currently unavailable. Please try again later.";
      } else if (response.statusCode == 401) {
        // Authentication error
        debugPrint('Authentication error: ${response.body}');
        return "I'm currently experiencing authentication issues. Please try again later.";
      } else {
        // Other API errors
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        return "Sorry, I'm currently unavailable. Please try again later.";
      }
    } catch (e) {
      debugPrint('Error calling Gemini API: $e');
      return "Network error. Please check your connection and try again.";
    }
  }
  
  /// Get a suggested response to a parenting challenge
  Future<String?> getSuggestedResponse(String challenge) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final prompt = '''
You are a parenting expert specializing in child development. A parent is facing this challenge:

"$challenge"

Provide a brief, practical response with 1-2 evidence-based strategies they could try. Keep your answer under 150 words.
''';

      final response = await _callGeminiWithRetries(prompt);
      
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _error = 'Error getting suggested response: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Test direct API connectivity - for diagnostics only
  Future<String> testDirectApiRequest(String prompt) async {
    try {
      final response = await _sendMessageToGemini("Say hello and confirm the API is working properly.");
      return response ?? "No response received";
    } catch (e) {
      return "Error: $e";
    }
  }
}

/// Represents a conversation with the AI therapist
class AITherapistConversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<AITherapistMessage> messages;
  
  AITherapistConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
  });
  
  factory AITherapistConversation.fromJson(Map<String, dynamic> json) {
    return AITherapistConversation(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      messages: (json['messages'] as List)
          .map((m) => AITherapistMessage.fromJson(m))
          .toList(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }
}

/// Represents a message in an AI therapist conversation
class AITherapistMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  
  AITherapistMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });
  
  factory AITherapistMessage.fromJson(Map<String, dynamic> json) {
    return AITherapistMessage(
      id: json['id'],
      role: json['role'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
