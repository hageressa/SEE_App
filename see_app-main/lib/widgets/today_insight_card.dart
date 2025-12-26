import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:see_app/models/gemini_insight.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

/// A widget that displays a Gemini AI-generated insight in a conversational format
class TodayInsightCard extends StatelessWidget {
  /// The insight to display
  final GeminiInsight insight;
  
  /// Callback for when the user wants to view the full insight
  final VoidCallback onViewFullInsight;
  
  /// Callback for when the user wants to save the insight
  final Function(GeminiInsight) onSaveInsight;

  final bool isLoading;
  final String? errorMessage;

  const TodayInsightCard({
    super.key,
    required this.insight,
    required this.onViewFullInsight,
    required this.onSaveInsight,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState(context);
    }

    if (errorMessage != null) {
      return _buildErrorState(context);
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme_utils.SeeAppTheme.primaryColor.withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing8),
                    decoration: BoxDecoration(
                      color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
                    ),
                    child: Icon(
                      Icons.psychology,
                      color: theme_utils.SeeAppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: theme_utils.SeeAppTheme.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s AI Insight',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: theme_utils.SeeAppTheme.spacing4),
                        Text(
                          'Personalized guidance based on recent patterns',
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
              Text(
                insight.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: theme_utils.SeeAppTheme.spacing12),
              Text(
                insight.summary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: theme_utils.SeeAppTheme.textSecondary,
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: onViewFullInsight,
                    icon: const Icon(Icons.article_outlined),
                    label: const Text('Read More'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme_utils.SeeAppTheme.primaryColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => onSaveInsight(insight),
                    icon: Icon(
                      insight.isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: insight.isSaved
                          ? theme_utils.SeeAppTheme.primaryColor
                          : theme_utils.SeeAppTheme.textSecondary,
                    ),
                    tooltip: insight.isSaved ? 'Saved' : 'Save for later',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildLoadingState(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
      ),
      child: Container(
        padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing24),
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
                    borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: theme_utils.SeeAppTheme.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
                      Container(
                        width: 200,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing12),
            ...List.generate(3, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )),
          ],
        ),
      ),
    ).animate().shimmer(duration: 1500.ms, colors: [
      Colors.transparent,
      Colors.white.withOpacity(0.2),
      Colors.transparent,
    ]);
  }

  Widget _buildErrorState(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
      ),
      child: Container(
        padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme_utils.SeeAppTheme.error.withOpacity(0.5),
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
            Text(
              errorMessage ?? 'Failed to load insight',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: theme_utils.SeeAppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
            TextButton.icon(
              onPressed: onViewFullInsight, // Use this as retry
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: TextButton.styleFrom(
                foregroundColor: theme_utils.SeeAppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

/// A dialog that displays the full content of a Gemini insight
class GeminiInsightDialog extends StatelessWidget {
  final GeminiInsight insight;
  final Function(GeminiInsight) onSaveInsight;
  
  const GeminiInsightDialog({
    super.key,
    required this.insight,
    required this.onSaveInsight,
  });
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
      ),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            Container(
              padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
              decoration: BoxDecoration(
                color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(theme_utils.SeeAppTheme.radiusLarge),
                  topRight: Radius.circular(theme_utils.SeeAppTheme.radiusLarge),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Research Insight",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme_utils.SeeAppTheme.primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with darker color for better contrast
                    Text(
                      insight.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87, // Explicit dark color for contrast
                      ),
                    ),
                    const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
                    
                    // Source and date
                    Row(
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
                            insight.source,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: theme_utils.SeeAppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: theme_utils.SeeAppTheme.spacing8),
                        Text(
                          "${_getFormattedDate(insight.publishDate)} • Gemini AI",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: theme_utils.SeeAppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
                    
                    // Summary section with enhanced contrast
                    Container(
                      padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing12),
                      decoration: BoxDecoration(
                        color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
                        border: Border.all(
                          color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Summary:",
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme_utils.SeeAppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
                          Text(
                            insight.summary,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Colors.black87, // Explicit dark color for contrast
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
                    
                    // Full content with improved contrast and visual styling
                    if (insight.fullContent.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Research Details:",
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87, // Explicit dark color
                              ),
                            ),
                            const SizedBox(height: theme_utils.SeeAppTheme.spacing12),
                            // Format paragraphs with clear visual styling
                            ...insight.fullContent.split('\n\n').map((paragraph) {
                              return paragraph.isNotEmpty 
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: theme_utils.SeeAppTheme.spacing12),
                                    child: Text(
                                      paragraph.trim(),
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.black87, // Explicit dark color for contrast
                                        height: 1.5, // Better line height for readability
                                      ),
                                    ),
                                  )
                                : const SizedBox(height: 4);
                            }).toList(),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
                          border: Border.all(
                            color: Colors.amber,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                            const SizedBox(width: theme_utils.SeeAppTheme.spacing8),
                            Expanded(
                              child: Text(
                                "Detailed content is not available. Please check back later.",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
                    
                    const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
                    
                    // Disclaimer with better contrast
                    Container(
                      padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200, // Slightly darker background
                        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
                        border: Border.all(
                          color: Colors.grey.shade400, // Darker border for better visibility
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey.shade800, // Darker icon for better visibility
                            size: 20,
                          ),
                          const SizedBox(width: theme_utils.SeeAppTheme.spacing8),
                          Expanded(
                            child: Text(
                              "This content is AI-generated based on recent scientific research. Always consult with healthcare professionals for personalized advice.",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade800, // Darker text for better contrast
                                fontWeight: FontWeight.w500, // Slightly bolder for readability
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer with save button - improved contrast
            Container(
              padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50, // Slight background color
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade300, // Darker border for definition
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onSaveInsight(insight);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Insight saved to favorites'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme_utils.SeeAppTheme.primaryColor,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          insight.isSaved ? Icons.bookmark : Icons.bookmark_border,
                        ),
                        const SizedBox(width: theme_utils.SeeAppTheme.spacing8),
                        Text(
                          insight.isSaved ? "Saved" : "Save",
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Formats the date for display
  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final publishDate = DateTime(date.year, date.month, date.day);
    
    if (publishDate == today) {
      return 'Today';
    } else if (publishDate == yesterday) {
      return 'Yesterday';
    } else {
      // Format as month/day/year
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}