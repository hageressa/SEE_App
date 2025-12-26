import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:see_app/models/gemini_insight.dart';
import 'package:http/http.dart' as http;

/// Service for handling Gemini AI-powered content generation and retrieval
class GeminiService extends ChangeNotifier {
  // Gemini API key should be provided securely via environment variable or config file
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  
  // Gemini model to use (updated to latest available models)
  static const String _modelName = 'gemini-1.5-flash';
  
  // Gemini model with vision capabilities for images
  static const String _visionModelName = 'gemini-1.5-flash-vision';
  
  // Gemini client instances
  late final GenerativeModel _textModel;
  late final GenerativeModel _visionModel;
  List<GeminiInsight> _insights = [];
  bool _isLoading = false;
  String? _error;

  /// Get the current list of insights
  List<GeminiInsight> get insights => _insights;
  
  /// Check if insights are currently loading
  bool get isLoading => _isLoading;
  
  /// Get any current error message
  String? get error => _error;

  /// Initialize the service with Gemini API models
  GeminiService() {
    _initGeminiModels();
    // Load insights when service is created
    fetchInsights();
  }
  
  /// Initialize Gemini models
  void _initGeminiModels() {
    try {
      debugPrint('Initializing Gemini models with API key: ${_apiKey.substring(0, 5)}...');
      
      // Initialize text-only model with enhanced configuration
      _textModel = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,  // Balanced between creative and focused
          topK: 40,
          topP: 0.95,
          candidateCount: 1,
          maxOutputTokens: 8192,  // Allow for longer responses for detailed research content
        ),
      );
      
      // Initialize model with vision capabilities
      _visionModel = GenerativeModel(
        model: _visionModelName,
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          candidateCount: 1,
          maxOutputTokens: 4096,
        ),
      );
      
      debugPrint('Gemini models initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Gemini models: $e');
      _error = 'Failed to initialize AI services: ${e.toString()}';
    }
  }

  /// Fetch insights from Gemini AI using real API
  Future<void> fetchInsights() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First try to get insights from real Gemini API
      final List<GeminiInsight> apiInsights = await _generateInsightsFromAPI();
      
      // If we got insights from the API, use them
      if (apiInsights.isNotEmpty) {
        _insights = apiInsights;
      } else {
        // Fallback to mock data if API fails to provide insights
        debugPrint('Using fallback mock data since API returned no insights');
        _insights = _getMockInsights();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching insights: $e');
      _error = 'Failed to load insights: ${e.toString()}';
      
      // Fallback to mock data in case of error
      _insights = _getMockInsights();
      _isLoading = false;
      notifyListeners();
    }
  }
  /// Generate insights by calling the Gemini API
  Future<List<GeminiInsight>> _generateInsightsFromAPI() async {
    try {
      debugPrint('Starting to generate insights from Gemini API...');
      List<GeminiInsight> generatedInsights = [];
      
      // Create prompt for research insights with explicit formatting instructions
      final prompt = '''
You are an expert on Down syndrome and emotional development research. Create 3 concise research insights based on recent scientific studies about Down syndrome and emotional development.

Format each insight using exactly this structure:

===INSIGHT START===
TITLE: [Write a clear title that summarizes the key finding]

SUMMARY: [2-3 conversational sentences explaining the research finding in parent-friendly language]

CONTENT:
[5-7 paragraphs with detailed information about the research, its implications, and practical applications for parents]

SOURCE: [Journal name and year]
===INSIGHT END===

Please create 3 different insights following this exact format, with topics related to:
- Emotional recognition patterns in children with Down syndrome
- How structured routines impact emotional regulation
- Effective therapy approaches
- Communication strategies and emotional expression
- Social-emotional development milestones
      ''';
      
      debugPrint('Sending request to Gemini API...');
      final content = [Content.text(prompt)];
      
      // Get response from Gemini API with retry mechanism
      int attempts = 0;
      const maxAttempts = 3;
      GenerateContentResponse? response;
      
      while (response == null && attempts < maxAttempts) {
        try {
          attempts++;
          debugPrint('API call attempt $attempts...');
          response = await _textModel.generateContent(content);
          debugPrint('Successfully received Gemini API response');
        } catch (apiError) {
          debugPrint('API call attempt $attempts failed: $apiError');
          if (attempts == maxAttempts) {
            // Try direct HTTP request as fallback on last attempt
            final directResult = await _tryDirectGeminiAPIRequest(prompt);
            if (directResult.isNotEmpty) {
              generatedInsights = _parseGeminiResponse(directResult);
              if (generatedInsights.isNotEmpty) {
                return generatedInsights;
              }
            }
          }
          if (attempts < maxAttempts) {
            final backoffSeconds = attempts * 2;
            await Future.delayed(Duration(seconds: backoffSeconds));
          }
        }
      }
      
      // Process the response text
      if (response != null && response.text != null && response.text!.isNotEmpty) {
        debugPrint('Received response text length: ${response.text!.length}');
        
        // Log a snippet of the response for debugging
        final previewLength = min(200, response.text!.length);
        debugPrint('Response preview: ${response.text!.substring(0, previewLength)}...');
        
        // Parse the response to extract insights
        generatedInsights = _parseGeminiResponse(response.text!);
        debugPrint('Successfully extracted ${generatedInsights.length} insights');
      } else {
        debugPrint('Error: Failed to get valid response from Gemini API');
      }
      
      return generatedInsights;
    } catch (e) {
      debugPrint('Error generating insights from API: $e');
      return [];
    }
  }
  
  /// Try a direct HTTP request to the Gemini API as a fallback
  Future<String> _tryDirectGeminiAPIRequest(String prompt) async {
    try {
      debugPrint('Trying direct HTTP request to Gemini API...');
      final url = 'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$_apiKey';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
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
            'maxOutputTokens': 8192,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('Direct API request successful, status: ${response.statusCode}');
        
        if (jsonResponse['candidates'] != null && 
            jsonResponse['candidates'].isNotEmpty && 
            jsonResponse['candidates'][0]['content'] != null &&
            jsonResponse['candidates'][0]['content']['parts'] != null &&
            jsonResponse['candidates'][0]['content']['parts'].isNotEmpty) {
          
          final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          debugPrint('Got text response from direct API call: ${text.substring(0, min(100, text.length))}...');
          return text;
        }
      } else {
        debugPrint('Direct API request failed, status: ${response.statusCode}, response: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in direct API request: $e');
    }
    return '';
  }
  
  /// Helper method to get minimum of two integers
  int min(int a, int b) => a < b ? a : b;
  
  /// Parse the response from Gemini to extract multiple insights
  List<GeminiInsight> _parseGeminiResponse(String responseText) {
    try {
      debugPrint('Parsing Gemini API response...');
      List<GeminiInsight> insights = [];
      
      // First try to extract insights using our custom markers
      final markerPattern = RegExp(r'===INSIGHT START===(.*?)===INSIGHT END===', dotAll: true);
      final markerMatches = markerPattern.allMatches(responseText).toList();
      
      if (markerMatches.isNotEmpty) {
        debugPrint('Found ${markerMatches.length} structured insights with markers');
        
        for (int i = 0; i < markerMatches.length; i++) {
          final section = markerMatches[i].group(1)?.trim() ?? '';
          if (section.isEmpty) continue;
          
          // Extract title using the TITLE marker
          final titlePattern = RegExp(r'TITLE:\s*([^\n]+)', caseSensitive: false);
          final titleMatch = titlePattern.firstMatch(section);
          final title = titleMatch?.group(1)?.trim() ?? 'Research Insight';
          
          // Extract summary using the SUMMARY marker
          final summaryPattern = RegExp(r'SUMMARY:\s*([^\n]+(?:\n[^\n]+)*?)(?=\s*CONTENT:|\s*SOURCE:|\s*$)', dotAll: true, caseSensitive: false);
          final summaryMatch = summaryPattern.firstMatch(section);
          final summary = summaryMatch?.group(1)?.trim() ?? 'Recent research has revealed important findings about emotional development in children with Down syndrome.';
          
          // Extract content using the CONTENT marker (between CONTENT: and SOURCE:)
          final contentPattern = RegExp(r'CONTENT:\s*(.*?)(?=\s*SOURCE:|\s*$)', dotAll: true, caseSensitive: false);
          final contentMatch = contentPattern.firstMatch(section);
          String fullContent = contentMatch?.group(1)?.trim() ?? '';
          
          // Extract source using the SOURCE marker
          final sourcePattern = RegExp(r'SOURCE:\s*([^\n]+)', caseSensitive: false);
          final sourceMatch = sourcePattern.firstMatch(section);
          final source = sourceMatch?.group(1)?.trim() ?? 'Journal of Developmental Psychology, 2025';
          
          // If content is empty, use the whole section except for the markers
          if (fullContent.isEmpty) {
            fullContent = section
                .replaceAll(titlePattern, '')
                .replaceAll(summaryPattern, '')
                .replaceAll(sourcePattern, '')
                .trim();
            
            // If it's still empty after cleaning, provide a default message
            if (fullContent.isEmpty) {
              fullContent = '''
Recent research has provided valuable insights about emotional development in children with Down syndrome related to ${title.toLowerCase()}.

While specific details of this study are being processed, the summary highlights key findings that can help parents understand and support their child's emotional development.

For more detailed information, please consult with professionals specializing in Down syndrome or check back for updated research content.
''';
            }
          }
          
          debugPrint('Processed insight $i: Title: "${title.substring(0, min(30, title.length))}...", Content length: ${fullContent.length}');
          
          // Create insight with extracted data
          insights.add(GeminiInsight(
            id: 'insight-${i + 1}',
            title: title,
            summary: summary,
            fullContent: fullContent,
            source: source,
            publishDate: DateTime.now().subtract(Duration(days: i * 5)),
            imageUrl: _getRelevantImageUrl(title, i),
          ));
        }
      } else {
        // Fall back to the old pattern matching approach
        debugPrint('No structured insights found with markers, trying traditional parsing');
        final insightSections = _splitIntoInsightSections(responseText);
        
        for (int i = 0; i < insightSections.length; i++) {
          final section = insightSections[i];
          
          // Extract title (first line that looks like a title)
          final titleMatch = RegExp(r'^(.+?)[\n\r]').firstMatch(section);
          final title = titleMatch?.group(1)?.trim() ?? 'Research Insight';
          
          // Extract summary (first paragraph after title)
          final summaryMatch = RegExp(r'\n(.+?(?:\.|!|\?)(?:\s|$).+?(?:\.|!|\?)(?:\s|$))').firstMatch(section);
          final summary = summaryMatch?.group(1)?.trim() ?? 'Recent research has revealed important findings about emotional development in children with Down syndrome.';
          
          // Extract source (looking for pattern like "Source:" or text with journal names)
          final sourceMatch = RegExp(r'(?:Source|Journal|Reference)[:\s]+([\w\s,]+\d{4})').firstMatch(section);
          final source = sourceMatch?.group(1)?.trim() ?? 'Journal of Developmental Psychology, 2025';
          
          // Extract full content - everything except the title
          String fullContent = section;
          if (titleMatch != null) {
            fullContent = fullContent.substring(titleMatch.end).trim();
          }
          
          debugPrint('Processed traditional insight $i: Title length: ${title.length}, Content length: ${fullContent.length}');
          
          // Create insight
          insights.add(GeminiInsight(
            id: 'insight-${i + 1}',
            title: title,
            summary: summary,
            fullContent: fullContent,
            source: source,
            publishDate: DateTime.now().subtract(Duration(days: i * 5)),
            imageUrl: _getRelevantImageUrl(title, i),
          ));
        }
      }
      
      // Add debug message to help troubleshoot content issues
      if (insights.isNotEmpty) {
        final sampleInsight = insights.first;
        debugPrint('Sample insight title: ${sampleInsight.title}');
        debugPrint('Sample insight summary: ${sampleInsight.summary}');
        const maxContentPreview = 100;
        final contentPreview = sampleInsight.fullContent.length > maxContentPreview 
            ? sampleInsight.fullContent.substring(0, maxContentPreview) + "..." 
            : sampleInsight.fullContent;
        debugPrint('Sample insight content preview: $contentPreview');
      }
      
      return insights;
    } catch (e) {
      debugPrint('Error parsing Gemini response: $e');
      return [];
    }
  }
  
  /// Split the response text into separate insight sections
  List<String> _splitIntoInsightSections(String responseText) {
    try {
      debugPrint('Splitting response into insight sections...');
      
      // First look for our custom structured format markers
      final markerPattern = RegExp(r'===INSIGHT START===(.*?)===INSIGHT END===', dotAll: true);
      final markerMatches = markerPattern.allMatches(responseText).toList();
      
      if (markerMatches.isNotEmpty) {
        debugPrint('Found ${markerMatches.length} sections with insight markers');
        return markerMatches
            .map((match) => match.group(1)?.trim() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
      
      // Common patterns that might separate insights
      final patterns = [
        RegExp(r'Insight \d+:'),
        RegExp(r'\n\s*\d+\.\s+'),
        RegExp(r'\n\s*#\s*\d+\s*'),
      ];
      
      for (final pattern in patterns) {
        // Check if this pattern appears to separate insights
        final matches = pattern.allMatches(responseText).toList();
        if (matches.length >= 2) { // Need at least 2 matches to split properly
          debugPrint('Found ${matches.length} sections using pattern: ${pattern.pattern}');
          List<String> sections = [];
          
          // Add each section
          for (int i = 0; i < matches.length; i++) {
            final start = matches[i].start;
            final end = (i < matches.length - 1) ? matches[i + 1].start : responseText.length;
            sections.add(responseText.substring(start, end).trim());
          }
          
          return sections;
        }
      }
      
      // Look for sections that appear to be separated by titles (all caps or sentence case at start of line)
      final titlePattern = RegExp(r'\n([A-Z][^a-z\n]{0,3}[A-Z][^\n]*(?::|$))', multiLine: true);
      final titleMatches = titlePattern.allMatches('\n' + responseText).toList();
      if (titleMatches.length >= 2) {
        debugPrint('Found ${titleMatches.length} sections using title pattern');
        List<String> sections = [];
        
        for (int i = 0; i < titleMatches.length; i++) {
          final start = titleMatches[i].start;
          final end = (i < titleMatches.length - 1) ? titleMatches[i + 1].start : responseText.length + 1;
          final section = responseText.substring(start, end).trim();
          if (section.isNotEmpty) {
            sections.add(section);
          }
        }
        
        if (sections.isNotEmpty) {
          return sections;
        }
      }
      
      // If no pattern worked well, try to split by double newlines which often separate sections
      final sections = responseText.split(RegExp(r'\n\s*\n'));
      if (sections.length >= 3) { // If we got at least 3 sections, this might work
        debugPrint('Found ${sections.length} sections using double newlines');
        return sections.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
      
      // If all else fails, just return the whole text as one insight
      debugPrint('Could not split into multiple sections, returning entire text');
      return [responseText];
    } catch (e) {
      debugPrint('Error splitting response into sections: $e');
      return [responseText];
    }
  }
  
  /// Get a relevant image URL based on the insight topic
  String? _getRelevantImageUrl(String title, int index) {
    // If it's about emotional recognition
    if (title.toLowerCase().contains('emotion') || title.toLowerCase().contains('recognition')) {
      return 'https://images.unsplash.com/photo-1516627145497-ae6968895b24';
    }
    // If it's about routines or structure
    else if (title.toLowerCase().contains('routine') || title.toLowerCase().contains('structure')) {
      return 'https://images.unsplash.com/photo-1594608661623-aa0bd3a69a98';
    }
    // If it's about therapy or interventions
    else if (title.toLowerCase().contains('therapy') || title.toLowerCase().contains('intervention')) {
      return 'https://images.unsplash.com/photo-1513883049090-d0b7439799bf';
    }
    // If it's about social interactions
    else if (title.toLowerCase().contains('social') || title.toLowerCase().contains('interaction')) {
      return 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9';
    }
    // Default image URLs based on index to ensure variety
    final defaultUrls = [
      'https://images.unsplash.com/photo-1516627145497-ae6968895b24',
      'https://images.unsplash.com/photo-1594608661623-aa0bd3a69a98',
      'https://images.unsplash.com/photo-1513883049090-d0b7439799bf',
      'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9',
      'https://images.unsplash.com/photo-1605522561233-768ad7a8fab6',
    ];
    
    return defaultUrls[index % defaultUrls.length];
  }
  
  /// Generate insights with image input
  Future<GeminiInsight?> generateInsightWithImage(File imageFile, String topic) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Read image data
      final imageBytes = await imageFile.readAsBytes();
      final mime = _getMimeType(imageFile.path);
      
      // Create prompt for analyzing the image in context of Down syndrome
      final prompt = '''
Analyze this image related to children with Down syndrome and $topic. Provide insights about:
1. What the image shows related to emotional development or support
2. How this relates to current research on Down syndrome
3. Practical applications for parents and caregivers
''';
      
      // Create data for vision model
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/$mime', imageBytes),
        ]),
      ];
      
      // Get response from Gemini Vision API
      final response = await _visionModel.generateContent(content);
      
      if (response.text != null) {
        // Create insight from the response
        final insight = GeminiInsight(
          id: 'image-insight-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Visual Analysis: $topic',
          summary: _extractSummary(response.text!) ?? 'Analysis of image related to Down syndrome and emotional development.',
          fullContent: response.text!,
          source: 'Image Analysis via Gemini AI, ${DateTime.now().year}',
          publishDate: DateTime.now(),
          isFavorite: false,
        );
        
        _isLoading = false;
        notifyListeners();
        return insight;
      }
      
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Error generating insight with image: $e');
      _error = 'Failed to analyze image: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Extract a summary from the response text
  String? _extractSummary(String text) {
    // Try to extract first paragraph as summary
    final paragraphs = text.split('\n\n');
    if (paragraphs.isNotEmpty) {
      final firstPara = paragraphs[0].trim();
      if (firstPara.length > 20 && firstPara.length < 300) {
        return firstPara;
      }
    }
    
    // Otherwise, extract first 1-2 sentences
    final sentenceMatch = RegExp(r'^(.+?[.!?])\s+(.+?[.!?])?').firstMatch(text);
    if (sentenceMatch != null) {
      if (sentenceMatch.group(2) != null) {
        return '${sentenceMatch.group(1)} ${sentenceMatch.group(2)}';
      }
      return sentenceMatch.group(1);
    }
    
    // If all else fails, take first 150 characters
    if (text.length > 20) {
      final summary = text.substring(0, text.length > 150 ? 150 : text.length);
      return summary.lastIndexOf(' ') > 100 
          ? summary.substring(0, summary.lastIndexOf(' ')) + '...'
          : summary;
    }
    
    return null;
  }
  
  /// Get MIME type from file extension
  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      case 'bmp':
        return 'bmp';
      default:
        return 'jpeg'; // default fallback
    }
  }
  /// Toggle favorite status for an insight
  void toggleFavorite(String insightId) {
    final index = _insights.indexWhere((insight) => insight.id == insightId);
    if (index >= 0) {
      _insights[index].isFavorite = !_insights[index].isFavorite;
      notifyListeners();
    }
  }

  /// Get today's featured insight
  GeminiInsight? get todaysInsight {
    if (_insights.isEmpty) return null;
    // In a real app, this might select the most recent or most relevant insight
    return _insights.first;
  }

  /// Generate mock insights data
  /// In a real app, this would be replaced with actual Gemini API calls
  List<GeminiInsight> _getMockInsights() {
    return [
      GeminiInsight(
        id: 'insight-1',
        title: 'Emotional Recognition Patterns in Children with Down Syndrome',
        summary: 'Recent studies show that children with Down syndrome recognize happiness more easily than other emotions. This helps explain why they often respond well to positive reinforcement and joyful interactions.',
        fullContent: '''
New research from the University of Michigan reveals fascinating patterns in emotional recognition among children with Down syndrome.

Key findings:
- Children with Down syndrome typically recognize happy facial expressions more accurately than other emotions
- They may have more difficulty identifying negative emotions like fear or anger
- This emotional recognition pattern impacts how they develop social relationships

What this means for you:
Try using more exaggerated positive expressions when communicating important information. Visual supports with clear emotional cues can also help your child better understand different emotional states.

This research helps explain why many children with Down syndrome respond particularly well to positive reinforcement and enthusiastic praise during learning activities.
''',
        source: 'Journal of Developmental Psychology, 2025',
        publishDate: DateTime.now().subtract(const Duration(days: 2)),
        imageUrl: 'https://images.unsplash.com/photo-1516627145497-ae6968895b24',
      ),
      
      GeminiInsight(
        id: 'insight-2',
        title: 'Structured Routines Improve Emotional Regulation',
        summary: 'A new study reveals that consistent daily routines significantly help children with Down syndrome regulate their emotions and reduce anxiety during transitions.',
        fullContent: '''
Recent findings published in the Journal of Applied Behavior Analysis demonstrate the powerful impact of structured routines on emotional regulation in children with Down syndrome.

The study followed 45 families over a six-month period and found that children with consistent daily routines showed:
- 42% reduction in emotional outbursts during transitions
- Improved ability to self-regulate during stressful situations
- Better overall mood and emotional stability

Practical application:
Creating visual schedules and maintaining consistent routines around bedtime, meals, and other daily activities can significantly reduce anxiety and improve emotional well-being for your child.

Even small changes toward more structured routines showed measurable benefits within just a few weeks.
''',
        source: 'Journal of Applied Behavior Analysis, 2025',
        publishDate: DateTime.now().subtract(const Duration(days: 5)),
        imageUrl: 'https://images.unsplash.com/photo-1594608661623-aa0bd3a69a98',
      ),
      
      GeminiInsight(
        id: 'insight-3',
        title: 'Music Therapy Shows Promise for Emotional Development',
        summary: 'Engaging with music helps children with Down syndrome develop emotional awareness and expression skills, according to new research from Stanford University.',
        fullContent: '''
A groundbreaking study from Stanford University's Center for Music and the Brain reveals that regular music therapy sessions can significantly enhance emotional development in children with Down syndrome.

The research, which included 63 participants aged 4-12, found that children who participated in twice-weekly music therapy sessions for six months showed:
- Enhanced ability to identify and name their emotions
- Improved emotional expression through both verbal and non-verbal means
- Greater engagement in social-emotional learning activities
- Reduced frustration during challenging tasks

Most effective activities included:
- Rhythmic activities that connected emotions to physical movement
- Songs that specifically labeled and described different feelings
- Interactive music-making that encouraged turn-taking and emotional expression

The researchers noted that the structured yet creative nature of music therapy provided an ideal environment for emotional learning, combining predictability with expressive freedom.
''',
        source: 'Stanford University Center for Music and the Brain, 2025',
        publishDate: DateTime.now().subtract(const Duration(days: 10)),
        imageUrl: 'https://images.unsplash.com/photo-1513883049090-d0b7439799bf',
      ),
      
      GeminiInsight(
        id: 'insight-4',
        title: 'Social Stories Reduce Anxiety in New Situations',
        summary: 'Personalized social stories significantly reduce anxiety and improve behavior when children with Down syndrome face new or challenging situations.',
        fullContent: '''
New research from the Children's Hospital of Philadelphia has quantified the effectiveness of personalized social stories for children with Down syndrome.

The study involved 78 children ages 5-14 who were exposed to new situations both with and without prior social story preparation. Key findings include:

- Children who reviewed a personalized social story before a new situation showed 67% less anxious behavior
- Heart rate variability measurements confirmed significantly lower physiological stress responses
- Parents reported greater cooperation and participation when social stories were used
- Digital social stories with photos of the actual locations/people were most effective

The researchers emphasize that social stories work best when they:
1. Use simple, concrete language
2. Include specific information about what will happen
3. Offer clear guidance on expected behaviors
4. Incorporate visuals relevant to the child
5. Are reviewed multiple times before the actual event

This evidence-based approach provides a practical tool for parents and caregivers to help children with Down syndrome navigate potentially stressful new experiences with greater confidence and emotional regulation.
''',
        source: 'Journal of Pediatric Psychology, 2024',
        publishDate: DateTime.now().subtract(const Duration(days: 15)),
        imageUrl: 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9',
      ),
      
      GeminiInsight(
        id: 'insight-5',
        title: 'Emotional Vocabulary Development Through Visual Supports',
        summary: 'Visual emotion cards significantly expand emotional vocabulary and self-expression in children with Down syndrome, according to new research.',
        fullContent: '''
A new study from the University of Washington's Speech and Language Development Center has found that visual emotion cards can dramatically improve emotional vocabulary and expression in children with Down syndrome.

The 12-month study followed 94 children ages 3-10 who used specialized visual emotion cards as part of their daily routines. Researchers documented:

- 230% average increase in emotion-related vocabulary
- Significant improvement in ability to express personal emotional states
- Enhanced ability to recognize emotions in others
- Reduced frustration-related behaviors as communication improved

The most effective implementation included:
- Daily emotion identification activities (such as "How are you feeling?" routines)
- Emotion cards available during all parts of the day, not just during designated activities
- Integration of emotion cards into conflict resolution and problem-solving
- Gradual introduction of more nuanced emotions beyond the basics

Parents reported that emotion cards were particularly helpful during transitions and challenging situations when verbal communication was more difficult for their children.

The research team emphasized that consistent, long-term use showed the greatest benefits, with vocabulary continuing to expand throughout the study period.
''',
        source: 'University of Washington Speech and Language Development Center, 2025',
        publishDate: DateTime.now().subtract(const Duration(days: 20)),
        imageUrl: 'https://images.unsplash.com/photo-1605522561233-768ad7a8fab6',
      ),
    ];
  }

  /// Public method to test Gemini API connectivity directly
  Future<String> testDirectApiRequest(String prompt) async {
    return _tryDirectGeminiAPIRequest(prompt);
  }
}