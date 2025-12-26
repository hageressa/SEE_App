import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:see_app/models/subscription_plan.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

/// A banner widget that indicates features requiring device purchase
/// and subscription plans
class SubscriptionBanner extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onLearnMore;
  final VoidCallback? onClose;
  final IconData icon;
  final bool isCompact;
  final bool isDismissible;

  const SubscriptionBanner({
    super.key,
    required this.title,
    required this.description,
    required this.onLearnMore,
    this.onClose,
    this.icon = Icons.device_hub,
    this.isCompact = false,
    this.isDismissible = true,
  });
  
  /// Factory constructor for device features
  factory SubscriptionBanner.forDeviceFeature({
    required SubscriptionFeature feature,
    required VoidCallback onLearnMore,
    VoidCallback? onClose,
    bool isCompact = false,
    bool isDismissible = true,
  }) {
    return SubscriptionBanner(
      title: 'SEE Device Required',
      description: '${SubscriptionPlan.getFeatureName(feature)} requires the SEE device. '
          'Purchase the device to unlock this feature.',
      onLearnMore: onLearnMore,
      onClose: onClose,
      icon: SubscriptionPlan.getFeatureIcon(feature),
      isCompact: isCompact,
      isDismissible: isDismissible,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
        side: BorderSide(
          color: theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      color: theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.1),
      child: Stack(
        children: [
          // Banner Content
          Padding(
            padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with device icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
                      ),
                      child: Icon(
                        icon,
                        color: theme_utils.SeeAppTheme.secondaryColor,
                        size: isCompact ? 16 : 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme_utils.SeeAppTheme.secondaryColor,
                          fontSize: isCompact ? 14 : 16,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (!isCompact) const SizedBox(height: 12),
                
                // Description text
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: theme_utils.SeeAppTheme.textSecondary,
                    fontSize: isCompact ? 12 : 14,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Action button
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onLearnMore();
                  },
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Learn More'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 8 : 12,
                      vertical: isCompact ? 4 : 8,
                    ),
                    foregroundColor: theme_utils.SeeAppTheme.secondaryColor,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          
          // Close button if dismissible
          if (isDismissible && onClose != null)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  size: isCompact ? 16 : 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: theme_utils.SeeAppTheme.textSecondary,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onClose!();
                },
              ),
            ),
          
          // Decorative element
          Positioned(
            bottom: -10,
            right: -10,
            child: Container(
              width: isCompact ? 40 : 60,
              height: isCompact ? 40 : 60,
              decoration: BoxDecoration(
                color: theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          Positioned(
            top: -15,
            left: 40,
            child: Container(
              width: isCompact ? 30 : 40,
              height: isCompact ? 30 : 40,
              decoration: BoxDecoration(
                color: theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .moveY(begin: 10, end: 0, duration: 600.ms, curve: Curves.easeOutQuad);
  }
}

/// A placeholder widget that shows a non-interactive preview of features
/// requiring device purchase
class FeaturePlaceholder extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onLearnMore;
  final double height;
  
  const FeaturePlaceholder({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onLearnMore,
    this.height = 200,
  });

  /// Factory constructor for device features
  factory FeaturePlaceholder.forDeviceFeature({
    required SubscriptionFeature feature,
    required VoidCallback onLearnMore,
    double height = 200,
  }) {
    return FeaturePlaceholder(
      title: SubscriptionPlan.getFeatureName(feature),
      description: SubscriptionPlan.getFeatureDescription(feature),
      icon: SubscriptionPlan.getFeatureIcon(feature),
      onLearnMore: onLearnMore,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: theme_utils.SeeAppTheme.secondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: theme_utils.SeeAppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onLearnMore,
            icon: const Icon(Icons.add_shopping_cart, size: 16),
            label: const Text('Get Device'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme_utils.SeeAppTheme.secondaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}