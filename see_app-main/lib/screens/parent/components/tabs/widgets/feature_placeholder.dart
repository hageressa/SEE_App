part of '../dashboard_tab.dart';

/// Feature placeholder widget for subscription-based features
class FeaturePlaceholder extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onLearnMore;
  final double height;
  final SubscriptionFeature? feature;

  const FeaturePlaceholder({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onLearnMore,
    this.height = 200,
    this.feature,
  }) : super(key: key);

  // Convenience constructor that derives title, description, and icon from feature type
  factory FeaturePlaceholder.fromFeature({
    Key? key,
    required SubscriptionFeature feature,
    required VoidCallback onLearnMore,
    double height = 200,
  }) {
    String title;
    String description;
    IconData icon;
    
    switch (feature) {
      case SubscriptionFeature.realtimeMonitoring:
        title = 'Real-time Emotion Monitoring';
        description = 'Get live updates on your child\'s emotional state';
        icon = Icons.timeline;
        break;
      case SubscriptionFeature.distressAlerts:
        title = 'Distress Alert System';
        description = 'Be notified when your child experiences emotional distress';
        icon = Icons.notification_important;
        break;
      default:
        title = 'Premium Feature';
        description = 'Unlock additional features with a subscription';
        icon = Icons.star;
    }
    
    return FeaturePlaceholder(
      key: key,
      title: title,
      description: description,
      icon: icon,
      onLearnMore: onLearnMore,
      height: height,
      feature: feature,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: theme_utils.SeeAppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: theme_utils.SeeAppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
          ElevatedButton(
            onPressed: onLearnMore,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme_utils.SeeAppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }
}