import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/models/emotion_data.dart' as emotion_model;
import 'package:see_app/models/subscription_plan.dart';
import 'package:see_app/models/suggestion_feedback.dart';
import 'package:see_app/services/emotion_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:see_app/widgets/calming_suggestion_card.dart';
import 'package:see_app/widgets/distress_alert_card.dart';
import 'package:see_app/widgets/emotion_trend_chart.dart';
import 'package:see_app/widgets/subscription_banner.dart';
import 'package:see_app/screens/subscription_screen.dart';

/// Helper widgets for the dashboard tab
part 'widgets/loading_placeholder.dart';
part 'widgets/error_view.dart';
part 'widgets/feature_placeholder.dart';

/// Dashboard tab for displaying emotion data, alerts and suggestions
class DashboardTab extends StatefulWidget {
  final List<Child> children;
  final Child? selectedChild;
  final Function(Child) onChangeChild;
  final Function(String) onChangeTimeRange;
  final Function() onRefreshData;
  final Function() onAddNewChild;
  final Function(emotion_model.DistressAlert) onResolveAlert;
  final Function(emotion_model.DistressAlert) onViewAlertDetails;
  final Function() onViewAlertHistory;
  final Function(emotion_model.CalmingSuggestion) onViewSuggestionDetails;
  final Function(emotion_model.CalmingSuggestion, bool) onToggleFavoriteSuggestion;
  final Function() onViewAllSuggestions;
  final Function() onShowRecordingModal;
  final Function({SubscriptionFeature? highlightedFeature}) onNavigateToSubscription;
  final Function(
    emotion_model.CalmingSuggestion, 
    dynamic rating, 
    emotion_model.EmotionType beforeEmotion, 
    double beforeIntensity,
    emotion_model.EmotionType? afterEmotion, 
    double? afterIntensity, 
    String? comments
  )? onRateSuggestion;
  
  final Future<List<emotion_model.EmotionData>> emotionDataFuture;
  final Future<List<emotion_model.DistressAlert>> alertsFuture;
  final Future<List<emotion_model.CalmingSuggestion>> suggestionsFuture;
  
  final bool isLoading;
  final String timeRange;
  final bool hasDevice;
  final bool showEmotionBanner;
  final bool showAlertsBanner;
  final bool showSuggestionsBanner;

  const DashboardTab({
    super.key,
    required this.children,
    required this.selectedChild,
    required this.onChangeChild,
    required this.onChangeTimeRange,
    required this.onRefreshData,
    required this.onAddNewChild,
    required this.onResolveAlert,
    required this.onViewAlertDetails,
    required this.onViewAlertHistory,
    required this.onViewSuggestionDetails,
    required this.onToggleFavoriteSuggestion,
    required this.onViewAllSuggestions,
    required this.onShowRecordingModal,
    required this.onNavigateToSubscription,
    required this.emotionDataFuture,
    required this.alertsFuture,
    required this.suggestionsFuture,
    required this.isLoading,
    required this.timeRange,
    required this.hasDevice,
    required this.showEmotionBanner,
    required this.showAlertsBanner,
    required this.showSuggestionsBanner,
    this.onRateSuggestion,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  Widget build(BuildContext context) {
    // Show empty state guidance for new users with no children
    if (widget.children.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await widget.onRefreshData();
          return Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - 200, // Ensure it's scrollable
            padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
            child: _buildEmptyDashboard(),
          ),
        ),
      );
    }
    
    // Regular dashboard for users with children
    return RefreshIndicator(
      onRefresh: () async {
        await widget.onRefreshData();
        return Future.delayed(const Duration(milliseconds: 500));
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildChildSelector(),
                const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
                _buildEmotionOverview(),
                const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
                _buildAlertSection(),
                const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
                _buildSuggestionsSection(),
                const SizedBox(height: 80), // Bottom padding for FAB
              ]),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds an empty dashboard for new users
  Widget _buildEmptyDashboard() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.child_care,
            size: 64,
            color: theme_utils.SeeAppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Welcome to SEE!",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "Start by adding your child to track their emotional well-being and get personalized suggestions.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: theme_utils.SeeAppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: widget.onAddNewChild,
          icon: const Icon(Icons.add),
          label: const Text("Add Your Child"),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme_utils.SeeAppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 32, 
              vertical: 16
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            // Show help information
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('The SEE app helps track and improve emotional well-being for children with Down syndrome'),
                duration: Duration(seconds: 3),
              ),
            );
          },
          child: const Text("Learn how it works"),
        ),
        const SizedBox(height: 40),
      ],
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: 0.1, end: 0, duration: 600.ms, curve: Curves.easeOutQuad);
  }
  
  /// Builds the child selector for the dashboard
  Widget _buildChildSelector() {
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
            Text(
              'Select Child',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: widget.children.map((child) {
                  final isSelected = widget.selectedChild?.id == child.id;
                    final effectiveWidth = width / widget.children.length;
                    
                    return SizedBox(
                      width: effectiveWidth > 120 ? 120 : effectiveWidth - 16,
                      child: _buildChildAvatar(child, isSelected),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: 0.1, end: 0, duration: 600.ms, curve: Curves.easeOutQuad);
  }
  
  /// Builds a child avatar for the child selector
  Widget _buildChildAvatar(Child child, bool isSelected) {
    return InkWell(
      onTap: () => widget.onChangeChild(child),
      borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: theme_utils.SeeAppTheme.spacing12, 
          horizontal: theme_utils.SeeAppTheme.spacing8
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
          border: Border.all(
            color: isSelected
                ? theme_utils.SeeAppTheme.primaryColor
                : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? theme_utils.SeeAppTheme.primaryColor.withOpacity(0.2)
                        : Colors.grey.shade100,
                  ),
                  child: Center(
                    child: Text(
                      child.name.substring(0, 1),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? theme_utils.SeeAppTheme.primaryColor
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme_utils.SeeAppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  child.name,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? theme_utils.SeeAppTheme.primaryColor
                        : theme_utils.SeeAppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: theme_utils.SeeAppTheme.spacing4),
                Text(
                  '${child.age}y',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? theme_utils.SeeAppTheme.primaryColor.withOpacity(0.7)
                        : theme_utils.SeeAppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the emotion overview card
  Widget _buildEmotionOverview() {
    // If no device is connected, show a modified version with subscription banner
    // In production, we always show the emotion tracking UI regardless of device status
    // This handles both device and non-device scenarios
    
    // Original implementation with real-time data when device is connected
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
        child: FutureBuilder<List<emotion_model.EmotionData>>(
          future: widget.emotionDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || widget.isLoading) {
              return const _LoadingPlaceholder(
                title: 'Emotion Trends',
                subtitle: 'Loading emotional patterns...',
                height: 260,
              );
            }
            
            if (snapshot.hasError) {
              return _ErrorView(
                title: 'Emotion Trends',
                message: 'Failed to load emotion data. Please try again.',
                onRetry: () => widget.onRefreshData(),
              );
            }
            
            final emotionData = snapshot.data!;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Emotion Trends',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildTimeRangeSelector(),
                  ],
                ),
                const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
                Text(
                  'Tracking ${widget.selectedChild?.name ?? "child"}\'s emotional patterns',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: theme_utils.SeeAppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: 220,
                      child: EmotionTrendChart(emotionData: emotionData),
                    );
                  }
                ),
                const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
                _buildEmotionSummary(emotionData),
              ],
            );
          }
        ),
      ),
    ).animate()
      .fadeIn(duration: 700.ms, delay: 200.ms)
      .slideY(begin: 0.2, end: 0, duration: 700.ms, delay: 200.ms, curve: Curves.easeOutQuad);
  }
  
  /// Builds UI for manual emotion entry
  Widget _buildManualEmotionEntry() {
    return Container(
      padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Record Emotion Manually',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: theme_utils.SeeAppTheme.spacing12),
          Text(
            'Until you connect the SEE device, you can record emotions manually.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: theme_utils.SeeAppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onShowRecordingModal();
              },
              icon: const Icon(Icons.add),
              label: const Text('Record Emotion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds the time range selector
  Widget _buildTimeRangeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeChip('Day', widget.timeRange == 'day'),
          _buildTimeChip('Week', widget.timeRange == 'week'),
          _buildTimeChip('Month', widget.timeRange == 'month'),
        ],
      ),
    );
  }
  
  /// Builds a time range chip
  Widget _buildTimeChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.onChangeTimeRange(label.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: theme_utils.SeeAppTheme.spacing12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme_utils.SeeAppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
  
  /// Builds a summary of emotion data
  Widget _buildEmotionSummary(List<emotion_model.EmotionData> data) {
    // Calculate most frequent emotion
    final Map<emotion_model.EmotionType, int> emotionCounts = {};
    for (var emotion in data) {
      emotionCounts[emotion.type] = (emotionCounts[emotion.type] ?? 0) + 1;
    }
    
    emotion_model.EmotionType? mostFrequentEmotion;
    int maxCount = 0;
    emotionCounts.forEach((emotion, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequentEmotion = emotion;
      }
    });
    
    // Calculate highest intensity emotion
    emotion_model.EmotionType? highestIntensityEmotion;
    double maxIntensity = 0;
    for (var emotion in data) {
      if (emotion.intensity > maxIntensity) {
        maxIntensity = emotion.intensity;
        highestIntensityEmotion = emotion.type;
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Insights:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
          _buildInsightRow(
            'Most common emotion:', 
            mostFrequentEmotion != null
                ? emotion_model.EmotionData.getEmotionName(mostFrequentEmotion!)
                : 'N/A',
            _getEmotionIcon(mostFrequentEmotion),
            _getEmotionColor(mostFrequentEmotion),
          ),
          const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
          _buildInsightRow(
            'Highest intensity:', 
            highestIntensityEmotion != null
                ? '${emotion_model.EmotionData.getEmotionName(highestIntensityEmotion!)} (${(maxIntensity * 100).toInt()}%)'
                : 'N/A',
            _getEmotionIcon(highestIntensityEmotion),
            _getEmotionColor(highestIntensityEmotion),
          ),
        ],
      ),
    );
  }
  
  /// Builds an insight row for the emotion summary
  Widget _buildInsightRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: theme_utils.SeeAppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: theme_utils.SeeAppTheme.spacing8),
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: theme_utils.SeeAppTheme.spacing4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(duration: 2000.ms, color: color.withOpacity(0.7)),
      ],
    );
  }
  
  /// Gets the icon for an emotion type
  IconData _getEmotionIcon(emotion_model.EmotionType? emotion) {
    if (emotion == null) return Icons.help_outline;
    
    final themeType = _convertToThemeEmotionType(emotion);
    return theme_utils.SeeAppTheme.getEmotionIcon(themeType);
  }
  
  /// Gets the color for an emotion type
  Color _getEmotionColor(emotion_model.EmotionType? emotion) {
    if (emotion == null) return Colors.grey;
    
    final themeType = _convertToThemeEmotionType(emotion);
    return theme_utils.SeeAppTheme.getEmotionColor(themeType);
  }
  
  /// Converts emotion model type to theme emotion type
  theme_utils.EmotionType _convertToThemeEmotionType(emotion_model.EmotionType type) {
    switch (type) {
      case emotion_model.EmotionType.joy:
        return theme_utils.EmotionType.joy;
      case emotion_model.EmotionType.sadness:
        return theme_utils.EmotionType.sadness;
      case emotion_model.EmotionType.anger:
        return theme_utils.EmotionType.anger;
      case emotion_model.EmotionType.fear:
        return theme_utils.EmotionType.fear;
      case emotion_model.EmotionType.calm:
        return theme_utils.EmotionType.calm;
      default:
        return theme_utils.EmotionType.calm;
    }
  }
  
  /// Converts emotion model alert severity to theme alert severity
  theme_utils.AlertSeverity _convertToThemeAlertSeverity(emotion_model.AlertSeverity severity) {
    switch (severity) {
      case emotion_model.AlertSeverity.low:
        return theme_utils.AlertSeverity.low;
      case emotion_model.AlertSeverity.medium:
        return theme_utils.AlertSeverity.medium;
      case emotion_model.AlertSeverity.high:
        return theme_utils.AlertSeverity.high;
      default:
        return theme_utils.AlertSeverity.low;
    }
  }
  
  /// Builds the distress alerts section
  Widget _buildAlertSection() {
    // In production, we always show the alerts UI regardless of device status
    
    // Original implementation with real-time data when device is connected
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
        child: FutureBuilder<List<emotion_model.DistressAlert>>(
          future: widget.alertsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || widget.isLoading) {
              return const _LoadingPlaceholder(
                title: 'Distress Alerts',
                subtitle: 'Checking for alerts...',
                height: 150,
              );
            }
            
            if (snapshot.hasError) {
              return _ErrorView(
                title: 'Distress Alerts',
                message: 'Failed to load alerts. Please try again.',
                onRetry: () => widget.onRefreshData(),
              );
            }
            
            final alerts = snapshot.data!;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Distress Alerts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (alerts.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          widget.onViewAlertHistory();
                        },
                        icon: const Icon(Icons.history, size: 16),
                        label: const Text('History'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme_utils.SeeAppTheme.primaryColor,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: theme_utils.SeeAppTheme.spacing8),
                        ),
                      ),
                  ],
                ),
                
                if (alerts.isEmpty)
                  _buildNoAlertsView()
                else
                  _buildAlertList(alerts),
              ],
            );
          }
        ),
      ),
    ).animate()
      .fadeIn(duration: 800.ms, delay: 400.ms)
      .slideY(begin: 0.3, end: 0, duration: 800.ms, delay: 400.ms, curve: Curves.easeOutQuad);
  }
  
  /// Builds the view when there are no alerts
  Widget _buildNoAlertsView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme_utils.SeeAppTheme.alertLow.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 32,
                color: theme_utils.SeeAppTheme.alertLow,
              ),
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
            Text(
              'No active alerts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: theme_utils.SeeAppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
            Text(
              '${widget.selectedChild?.name ?? "Your child"} seems to be doing well!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: theme_utils.SeeAppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Builds a list of distress alerts
  Widget _buildAlertList(List<emotion_model.DistressAlert> alerts) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: theme_utils.SeeAppTheme.spacing8),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: theme_utils.SeeAppTheme.spacing8),
          child: DistressAlertCard(
            alert: alerts[index],
            onResolve: () {
              widget.onResolveAlert(alerts[index]);
            },
            onViewDetails: () {
              widget.onViewAlertDetails(alerts[index]);
            },
          ),
        );
      },
    );
  }
  
  /// Builds the calming suggestions section
  Widget _buildSuggestionsSection() {
    // In production, we always show the suggestions UI regardless of device status
    
    // Original implementation with real-time data when device is connected
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
        child: FutureBuilder<List<emotion_model.CalmingSuggestion>>(
          future: widget.suggestionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || widget.isLoading) {
              return const _LoadingPlaceholder(
                title: 'Calming Suggestions',
                subtitle: 'Loading personalized activities...',
                height: 200,
              );
            }
            
            if (snapshot.hasError) {
              return _ErrorView(
                title: 'Calming Suggestions',
                message: 'Failed to load suggestions. Please try again.',
                onRetry: () => widget.onRefreshData(),
              );
            }
            
            final suggestions = snapshot.data!;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Calming Suggestions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        widget.onViewAllSuggestions();
                      },
                      icon: const Icon(Icons.grid_view, size: 16),
                      label: const Text('View All'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme_utils.SeeAppTheme.primaryColor,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: theme_utils.SeeAppTheme.spacing8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: theme_utils.SeeAppTheme.spacing4),
                Text(
                  'Personalized activities for ${widget.selectedChild?.name ?? "child"}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: theme_utils.SeeAppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
                _buildSuggestionsList(suggestions),
              ],
            );
          }
        ),
      ),
    ).animate()
      .fadeIn(duration: 900.ms, delay: 600.ms)
      .slideY(begin: 0.4, end: 0, duration: 900.ms, delay: 600.ms, curve: Curves.easeOutQuad);
  }
  
  /// Builds a horizontal list of calming suggestions
  Widget _buildSuggestionsList(List<emotion_model.CalmingSuggestion> suggestions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 290,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == suggestions.length - 1 ? 0 : theme_utils.SeeAppTheme.spacing16,
                ),
                child: CalmingSuggestionCard(
                  suggestion: suggestion,
                  onTap: () {
                    widget.onViewSuggestionDetails(suggestion);
                  },
                  onFavoriteToggled: (isFavorite) {
                    widget.onToggleFavoriteSuggestion(suggestion, isFavorite);
                  },
                  onRateSuggestion: widget.onRateSuggestion != null 
                      ? (emotion_model.CalmingSuggestion suggestion, EffectivenessRating rating, 
                         emotion_model.EmotionType beforeEmotion, double beforeIntensity, 
                         emotion_model.EmotionType? afterEmotion, double? afterIntensity, String? comments) {
                          widget.onRateSuggestion!(
                            suggestion, 
                            rating, 
                            beforeEmotion, 
                            beforeIntensity, 
                            afterEmotion, 
                            afterIntensity, 
                            comments
                          );
                        }
                      : null,
                ),
              );
            },
          ),
        );
      }
    );
  }
}
