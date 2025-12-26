part of '../dashboard_tab.dart';

/// A unified loading placeholder widget for async data loading states
class _LoadingPlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;
  final double height;
  final IconData? icon;
  final Color? iconColor;
  final bool showProgress;
  final Widget? customContent;
  
  const _LoadingPlaceholder({
    required this.title,
    required this.subtitle,
    required this.height,
    this.icon,
    this.iconColor,
    this.showProgress = true,
    this.customContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
        border: Border.all(
          color: theme_utils.SeeAppTheme.textSecondary.withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon!,
                  color: iconColor ?? theme_utils.SeeAppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: theme_utils.SeeAppTheme.spacing12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: theme_utils.SeeAppTheme.spacing4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: theme_utils.SeeAppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (customContent != null)
            Expanded(child: customContent!)
          else if (showProgress)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme_utils.SeeAppTheme.primaryColor.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
                    Text(
                      'Loading...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: theme_utils.SeeAppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}