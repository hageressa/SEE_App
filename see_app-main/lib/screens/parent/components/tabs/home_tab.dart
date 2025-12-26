import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/article.dart';
import 'package:see_app/models/gemini_insight.dart';
import 'package:see_app/models/mission.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/services/community_service.dart';
import 'package:see_app/services/gemini_service.dart';
import 'package:see_app/services/mission_service.dart';
import 'package:see_app/services/ai_therapist_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:see_app/widgets/community_wall.dart';
import 'package:see_app/widgets/connect_reflect_section.dart';
import 'package:see_app/widgets/today_insight_card.dart';
import 'package:see_app/widgets/ai_therapist_section.dart';
import 'package:see_app/widgets/streak_display.dart';

/// Home tab for displaying content feed - shows articles, resources, and tips
class HomeTab extends StatefulWidget {
  final Function() onRefreshContent;
  final Function(Article) onViewArticle;
  final Function(Article) onSaveArticleToFavorites;
  final Function() onViewAllArticles;
  final Function() onNavigateToHelp;
  final Article? currentArticle;
  final bool isArticleOpen;
  final bool suppressNoChildrenMessage;

  const HomeTab({
    super.key,
    required this.onRefreshContent,
    required this.onViewArticle,
    required this.onSaveArticleToFavorites,
    required this.onViewAllArticles,
    required this.onNavigateToHelp,
    this.currentArticle,
    this.isArticleOpen = false,
    this.suppressNoChildrenMessage = false,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  GeminiInsight? _currentInsight;
  bool _isInsightDialogOpen = false;
  @override
  void initState() {
    super.initState();
    
    // Ensure Gemini insights are loaded
    Future.microtask(() {
      final geminiService = Provider.of<GeminiService>(context, listen: false);
      if (geminiService.insights.isEmpty && !geminiService.isLoading) {
        geminiService.fetchInsights();
      }
    });
  }

  /// Handles viewing the full insight
  void _viewFullInsight() {
    final geminiService = Provider.of<GeminiService>(context, listen: false);
    final insight = geminiService.todaysInsight;
    if (insight == null) return;
    
    setState(() {
      _currentInsight = insight;
      _isInsightDialogOpen = true;
    });
    
    // Show the insight dialog
    showDialog(
      context: context,
      builder: (context) => GeminiInsightDialog(
        insight: insight,
        onSaveInsight: _saveInsight,
      ),
    ).then((_) {
      // When dialog is closed
      setState(() {
        _isInsightDialogOpen = false;
      });
    });
  }
  
  /// Handles saving an insight
  void _saveInsight(GeminiInsight insight) {
    HapticFeedback.selectionClick();
    
    // Toggle favorite status
    final geminiService = Provider.of<GeminiService>(context, listen: false);
    geminiService.toggleFavorite(insight.id);
    
    // Show confirmation if not already showing dialog
    if (!_isInsightDialogOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            insight.isFavorite 
                ? 'Insight saved to favorites' 
                : 'Insight removed from favorites'
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh content
        await widget.onRefreshContent();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content refreshed'),
            duration: Duration(seconds: 1),
          ),
        );
        return Future.delayed(const Duration(milliseconds: 800));
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Welcome hero section - using user data from auth service
                Consumer<AuthService>(
                  builder: (context, authService, _) {
                    final user = authService.currentUser;
                    final greeting = _getTimeBasedGreeting();
                    final hasName = user?.name != null && user!.name.isNotEmpty;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting and user info
                        Text(
                          hasName 
                              ? '$greeting, ${user!.name.split(' ').first}!'
                              : greeting,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: theme_utils.SeeAppTheme.spacing4),
                        Text(
                          'How are you feeling today?',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: theme_utils.SeeAppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
                        
                        // Streak Display Widget
                        Consumer<MissionService>(
                          builder: (context, missionService, _) {
                            if (missionService.userStreak != null) {
                              return StreakDisplay(
                                currentStreak: missionService.userStreak!.currentStreak,
                                longestStreak: missionService.userStreak!.longestStreak,
                                showTrophyAnimation: missionService.userStreak!.currentStreak > 0 &&
                                    missionService.userStreak!.currentStreak % 7 == 0,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        
                        const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
                      ],
                    );
                  },
                ),

                // Today's Insight from Gemini AI
                _buildTodaysInsight(context),
                const SizedBox(height: theme_utils.SeeAppTheme.spacing32),
                
                // AI Therapist Section
                Padding(
                  padding: const EdgeInsets.only(bottom: theme_utils.SeeAppTheme.spacing32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'AI Therapist Assistance',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => const QuickAITherapistDialog(),
                              );
                            },
                            child: const Text('Ask a question'),
                            style: TextButton.styleFrom(
                              foregroundColor: theme_utils.SeeAppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: theme_utils.SeeAppTheme.spacing12),
                      const AITherapistSection(),
                    ],
                  ),
                ),

                // Connect & Reflect section (improved with fixes)
                Padding(
                  padding: const EdgeInsets.only(bottom: theme_utils.SeeAppTheme.spacing32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Connect & Reflect',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Consumer<MissionService>(
                            builder: (context, missionService, _) {
                              return TextButton(
                                onPressed: () {
                                  // Force refresh missions
                                  missionService.fetchMissions();
                                },
                                child: const Text('Refresh'),
                                style: TextButton.styleFrom(
                                  foregroundColor: theme_utils.SeeAppTheme.primaryColor,
                                ),
                              );
                            }
                          ),
                        ],
                      ),
                      const SizedBox(height: theme_utils.SeeAppTheme.spacing12),
                      _buildConnectReflectSection(context),
                    ],
                  ),
                ),
                
                // Parent Community section
                Padding(
                  padding: const EdgeInsets.only(bottom: theme_utils.SeeAppTheme.spacing32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parent Community',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: theme_utils.SeeAppTheme.spacing12),
                      _buildCommunityWallSection(context),
                    ],
                  ),
                ),
                
                // Tips & Advice section
                Padding(
                  padding: const EdgeInsets.only(bottom: theme_utils.SeeAppTheme.spacing32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Tips & Advice',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: theme_utils.SeeAppTheme.spacing12),
                      _buildTipsSection(context),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the Today's Insight section with Gemini AI content
  Widget _buildTodaysInsight(BuildContext context) {
    return Consumer<GeminiService>(
      builder: (context, geminiService, child) {
        // Show loading state
        if (geminiService.isLoading) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
            ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.psychology_outlined,
                          color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.7),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: theme_utils.SeeAppTheme.spacing12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Insight",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Loading latest research...",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: theme_utils.SeeAppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                  const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
                ],
              ),
            ),
          );
        }
        
        // Show error state
        if (geminiService.error != null) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
            ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: theme_utils.SeeAppTheme.spacing12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Insight",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Unable to load insights",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: theme_utils.SeeAppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        geminiService.fetchInsights();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
                ],
              ),
            ),
          );
        }
        
        // If no insights are available, show placeholder
        if (geminiService.insights.isEmpty) {
          return _buildInsightPlaceholder(context);
        }
        
        // Show today's insight
        final insight = geminiService.todaysInsight;
        if (insight == null) {
          return _buildInsightPlaceholder(context);
        }
        
        return TodayInsightCard(
          insight: insight,
          onViewFullInsight: _viewFullInsight,
          onSaveInsight: _saveInsight,
        );
      },
    );
  }
  
  /// Builds a placeholder for when insights are not available
  Widget _buildInsightPlaceholder(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology_outlined,
                size: 40,
                color: theme_utils.SeeAppTheme.secondaryColor,
              ),
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
            Text(
              'AI Insights Coming Soon',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
            Text(
              'We\'re preparing AI-powered insights about the latest research on Down syndrome and emotional development.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: theme_utils.SeeAppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
          ],
        ),
      ),
    );
  }

  /// Builds the featured article card
  Widget _buildFeaturedArticle(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.currentArticle != null) {
          widget.onViewArticle(widget.currentArticle!);
        }
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
        ),
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'featured-article',
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(theme_utils.SeeAppTheme.radiusLarge)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Material(
                    color: Colors.transparent,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.2),
                                theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.4),
                              ],
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Image.network(
                            'https://images.pexels.com/photos/8535214/pexels-photo-8535214.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
                                child: Center(
                                  child: Icon(
                                    Icons.article_outlined,
                                    size: 48,
                                    color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.7),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: theme_utils.SeeAppTheme.spacing8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
                    ),
                    child: Text(
                      'FEATURED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme_utils.SeeAppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
                  Text(
                    'Understanding Emotional Development in Children with Down Syndrome',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
                  Text(
                    'Learn about key milestones and how to support healthy emotional growth in children with Down Syndrome.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: theme_utils.SeeAppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                        child: const Text(
                          'DR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: theme_utils.SeeAppTheme.spacing8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. Rebecca Thompson',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Child Psychologist • 2 days ago',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: theme_utils.SeeAppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.bookmark_border),
                        onPressed: () {
                          if (widget.currentArticle != null) {
                            widget.onSaveArticleToFavorites(widget.currentArticle!);
                          }
                        },
                        color: theme_utils.SeeAppTheme.primaryColor,
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
  
  /// Builds the latest articles section
  Widget _buildLatestArticles(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Latest Articles',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: widget.onViewAllArticles,
              child: const Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: theme_utils.SeeAppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
        _buildArticlesList(context),
      ],
    );
  }
  
  /// Builds a list of articles
  Widget _buildArticlesList(BuildContext context) {
    final articles = [
      {
        'title': 'Communication Strategies for Non-Verbal Children',
        'author': 'Sarah Johnson, SLP',
        'time': '3 days ago',
        'category': 'Communication',
      },
      {
        'title': 'Promoting Independence Through Daily Routines',
        'author': 'Michael Chen, OT',
        'time': '1 week ago',
        'category': 'Skills Development',
      },
      {
        'title': 'The Benefits of Inclusive Education',
        'author': 'Dr. Lisa Morgan',
        'time': '1 week ago',
        'category': 'Education',
      },
    ];
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        
        return GestureDetector(
          onTap: () {
            // Create a mock Article from the Map
            final mockArticle = Article(
              id: 'article-$index',
              title: article['title']!,
              content: 'Content for ${article['title']}',
              authorName: article['author']!,
              category: article['category']!,
              publishDate: DateTime.now().subtract(Duration(days: index + 1)),
            );
            widget.onViewArticle(mockArticle);
          },
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
            ),
            margin: const EdgeInsets.only(bottom: theme_utils.SeeAppTheme.spacing12),
            child: Padding(
              padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.article_outlined,
                        color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: theme_utils.SeeAppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
                          ),
                          child: Text(
                            article['category']!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: theme_utils.SeeAppTheme.spacing4),
                        Text(
                          article['title']!,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${article['author']} • ${article['time']}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: theme_utils.SeeAppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.bookmark_border, size: 18),
                              onPressed: () {
                                // Create a mock Article from the Map
                                final mockArticle = Article(
                                  id: 'article-$index',
                                  title: article['title']!,
                                  content: 'Content for ${article['title']}',
                                  authorName: article['author']!,
                                  category: article['category']!,
                                  publishDate: DateTime.now().subtract(Duration(days: index + 1)),
                                );
                                widget.onSaveArticleToFavorites(mockArticle);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Builds the tips and advice section
  Widget _buildTipsAndAdvice(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tips & Advice',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
        _buildTipsSection(context),
      ],
    );
  }
  
  /// Builds the Community Wall section where parents can share experiences
  Widget _buildCommunityWallSection(BuildContext context) {
    return Consumer<MissionService>(
      builder: (context, missionService, child) {
        // Show limited functionality if no completed missions yet
        final bool hasCompletedMissions = missionService.missions.any((m) => m.isCompleted);
        final completedMission = hasCompletedMissions 
            ? missionService.missions.firstWhere((m) => m.isCompleted)
            : null;
            
        // Create sample posts if community is empty
        final List<Map<String, dynamic>> samplePosts = [
          {
            'author': 'Emily B.',
            'content': 'Found a great visual timer app that helps my 6-year-old understand time better during activities!',
            'likes': 14,
            'timeAgo': '2h ago',
            'avatar': 'https://randomuser.me/api/portraits/women/${math.Random().nextInt(60)}.jpg',
          },
          {
            'author': 'Michael T.',
            'content': 'How do you handle sensory overload during family gatherings? My son struggles with the noise levels.',
            'likes': 8, 
            'timeAgo': '5h ago',
            'avatar': 'https://randomuser.me/api/portraits/men/${math.Random().nextInt(60)}.jpg',
          },
          {
            'author': 'Sarah K.',
            'content': 'Just completed the emotional regulation mission! The breathing exercise cards were a huge hit with my daughter.',
            'likes': 22,
            'timeAgo': '1d ago', 
            'avatar': 'https://randomuser.me/api/portraits/women/${math.Random().nextInt(60) + 10}.jpg',
          },
        ];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with icon and title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme_utils.SeeAppTheme.primaryColor.withOpacity(0.7),
                            theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.diversity_3,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Parent Community',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    // Show full community wall dialog
                    showDialog(
                      context: context,
                      builder: (context) => Dialog.fullscreen(
                        child: Scaffold(
                          appBar: AppBar(
                            title: const Text('Parent Community'),
                            leading: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          body: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CommunityWall(
                              showHeader: false,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.group, size: 18),
                  label: const Text('Join Community'),
                  style: TextButton.styleFrom(
                    backgroundColor: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
                    foregroundColor: theme_utils.SeeAppTheme.primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
            
            // Community wall with improved styling
            Card(
              elevation: 4,
              shadowColor: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
              ),
              margin: EdgeInsets.zero,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      theme_utils.SeeAppTheme.primaryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
                ),
                child: Column(
                  children: [
                    // Community header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline, 
                            color: theme_utils.SeeAppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recent Discussions',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme_utils.SeeAppTheme.primaryColor,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${samplePosts.length} posts',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: theme_utils.SeeAppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Divider
                    Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.2)),
                    
                    // Sample posts (fallback content if CommunityWall is empty)
                    ...samplePosts.map((post) => _buildCommunityPost(context, post)).toList(),
                    
                    // Create post button
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog.fullscreen(
                            child: Scaffold(
                              appBar: AppBar(
                                title: const Text('Create Post'),
                                leading: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                              body: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CommunityWall(
                                  showHeader: false,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(theme_utils.SeeAppTheme.radiusLarge),
                            bottomRight: Radius.circular(theme_utils.SeeAppTheme.radiusLarge),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: theme_utils.SeeAppTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Share Your Experience',
                                style: TextStyle(
                                  color: theme_utils.SeeAppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Helper method to build community posts
  Widget _buildCommunityPost(BuildContext context, Map<String, dynamic> post) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(post['avatar']),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post['author'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    post['timeAgo'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Post content
          Text(
            post['content'],
            style: const TextStyle(fontSize: 14),
          ),
          
          // Post actions
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite_border,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post['likes']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reply',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Builds the Connect & Reflect Missions section
  Widget _buildConnectReflectSection(BuildContext context) {
    return Consumer<MissionService>(
      builder: (context, missionService, child) {
        // Ensure missions are loaded when this widget is displayed
        if (!missionService.isLoading && missionService.missions.isEmpty) {
          // Only trigger fetch if we're not already loading and have no missions
          Future.microtask(() => missionService.fetchMissions());
        }

        // Show loading state with animation
        if (missionService.isLoading) {
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
                  colors: [
                    theme_utils.SeeAppTheme.primaryColor.withOpacity(0.05),
                    theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
              ),
              padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme_utils.SeeAppTheme.primaryColor,
                              theme_utils.SeeAppTheme.secondaryColor,
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
                          Icons.family_restroom,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: theme_utils.SeeAppTheme.spacing16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Connect & Reflect",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Loading your daily connection mission...",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: theme_utils.SeeAppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
                  Center(
                    child: SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(theme_utils.SeeAppTheme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOutQuad);
        }
        
        // Show error state with animation
        if (missionService.error != null) {
          return Card(
            elevation: 4,
            shadowColor: Colors.red.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
            ),
            margin: EdgeInsets.zero,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.red.withOpacity(0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
              ),
              padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: theme_utils.SeeAppTheme.spacing16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Connect & Reflect",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Unable to load your missions",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Try again
                        missionService.fetchMissions();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      ),
                    ),
                  ),
                  const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOutQuad);
        }
        
        // Add a fallback in case missions are empty but no error or loading state
        if (missionService.missions.isEmpty) {
          return _buildMissionPlaceholder(context);
        }
        
        // If everything looks good, show the actual Connect & Reflect section
        return const ConnectReflectSection()
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.05, end: 0, duration: 600.ms, curve: Curves.easeOutQuad);
      },
    );
  }
  
  /// Builds a placeholder when no missions are available
  Widget _buildMissionPlaceholder(BuildContext context) {
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
            colors: [
              Colors.white,
              theme_utils.SeeAppTheme.joyColor.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
        ),
        padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme_utils.SeeAppTheme.joyColor,
                        theme_utils.SeeAppTheme.primaryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme_utils.SeeAppTheme.joyColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.family_restroom,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: theme_utils.SeeAppTheme.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Connect & Reflect",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Your daily connection activity will appear here",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme_utils.SeeAppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme_utils.SeeAppTheme.joyColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      color: theme_utils.SeeAppTheme.joyColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Strengthen Your Connection",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme_utils.SeeAppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Daily activities help build understanding and bonding with your child through play and conversation.",
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Try to fetch missions again
                      Provider.of<MissionService>(context, listen: false).fetchMissions();
                    },
                    child: const Text("Check for Activities"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme_utils.SeeAppTheme.joyColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, end: 0, duration: 600.ms, curve: Curves.easeOutQuad);
  }
  
  /// Builds the tips section with scrollable cards
  Widget _buildTipsSection(BuildContext context) {
    final tips = [
      {
        'title': 'Creating Visual Schedules',
        'description': 'Help establish routines with visual supports',
        'icon': Icons.calendar_today_outlined,
        'color': theme_utils.SeeAppTheme.primaryColor,
      },
      {
        'title': 'Sensory-Friendly Environment',
        'description': 'Adjustments to make home more comfortable',
        'icon': Icons.home_outlined,
        'color': theme_utils.SeeAppTheme.secondaryColor,
      },
      {
        'title': 'Social Story Techniques',
        'description': 'Prepare children for new experiences',
        'icon': Icons.book_outlined,
        'color': theme_utils.SeeAppTheme.joyColor,
      },
      {
        'title': 'Self-Regulation Strategies',
        'description': 'Techniques to help manage emotions',
        'icon': Icons.psychology_outlined,
        'color': theme_utils.SeeAppTheme.calmColor,
      },
    ];
    
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tips.length,
        itemBuilder: (context, index) {
          final tip = tips[index];
          
          return Container(
            width: 160,
            margin: EdgeInsets.only(right: index == tips.length - 1 ? 0 : theme_utils.SeeAppTheme.spacing12),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
              ),
              color: (tip['color'] as Color).withOpacity(0.15),
              shadowColor: (tip['color'] as Color).withOpacity(0.3),
              surfaceTintColor: (tip['color'] as Color).withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      tip['icon'] as IconData,
                      color: tip['color'] as Color,
                      size: 32,
                    ),
                    const Spacer(),
                    Text(
                      tip['title'] as String,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: theme_utils.SeeAppTheme.spacing4),
                    Text(
                      tip['description'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme_utils.SeeAppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// Returns a time-appropriate greeting based on the current time of day
  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }
}