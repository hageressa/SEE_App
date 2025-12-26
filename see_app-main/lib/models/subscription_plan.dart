import 'package:flutter/material.dart';

/// Subscription plan tiers available in the app
enum SubscriptionTier {
  free,
  basic,
  premium,
}

/// Features that can be unlocked with different subscription tiers
enum SubscriptionFeature {
  realtimeMonitoring,
  emotionTracking,
  distressAlerts,
  advancedAnalytics,
  exportReports,
  multipleChildren,
  prioritySupport,
}

/// Represents a subscription plan within the app
class SubscriptionPlan {
  final SubscriptionTier tier;
  final String name;
  final String description;
  final List<SubscriptionFeature> features;
  final double monthlyPrice;
  final double yearlyPrice;
  final Color primaryColor;
  final bool isPopular;
  final bool requiresDevice;

  const SubscriptionPlan({
    required this.tier,
    required this.name,
    required this.description,
    required this.features,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.primaryColor,
    this.isPopular = false,
    this.requiresDevice = false,
  });

  /// Returns predefined subscription plans
  static List<SubscriptionPlan> getPlans() {
    return [
      SubscriptionPlan(
        tier: SubscriptionTier.free,
        name: 'Free',
        description: 'Basic features for getting started',
        features: [
          SubscriptionFeature.emotionTracking,
        ],
        monthlyPrice: 0,
        yearlyPrice: 0,
        primaryColor: Colors.grey,
        requiresDevice: false,
      ),
      SubscriptionPlan(
        tier: SubscriptionTier.basic,
        name: 'Basic',
        description: 'Essential features for daily use',
        features: [
          SubscriptionFeature.emotionTracking,
          SubscriptionFeature.distressAlerts,
          SubscriptionFeature.realtimeMonitoring,
        ],
        monthlyPrice: 9.99,
        yearlyPrice: 99.99,
        primaryColor: Colors.blue,
        requiresDevice: true,
      ),
      SubscriptionPlan(
        tier: SubscriptionTier.premium,
        name: 'Premium',
        description: 'Complete access to all features',
        features: [
          SubscriptionFeature.emotionTracking,
          SubscriptionFeature.distressAlerts,
          SubscriptionFeature.realtimeMonitoring,
          SubscriptionFeature.advancedAnalytics,
          SubscriptionFeature.exportReports,
          SubscriptionFeature.multipleChildren,
          SubscriptionFeature.prioritySupport,
        ],
        monthlyPrice: 19.99,
        yearlyPrice: 199.99,
        primaryColor: Colors.purple,
        isPopular: true,
        requiresDevice: true,
      ),
    ];
  }
  
  /// Returns feature name from enum
  static String getFeatureName(SubscriptionFeature feature) {
    switch (feature) {
      case SubscriptionFeature.realtimeMonitoring:
        return 'Real-time Emotion Monitoring';
      case SubscriptionFeature.emotionTracking:
        return 'Basic Emotion Tracking';
      case SubscriptionFeature.distressAlerts:
        return 'Distress Alerts';
      case SubscriptionFeature.advancedAnalytics:
        return 'Advanced Analytics';
      case SubscriptionFeature.exportReports:
        return 'Export Reports';
      case SubscriptionFeature.multipleChildren:
        return 'Multiple Children';
      case SubscriptionFeature.prioritySupport:
        return 'Priority Support';
    }
  }
  
  /// Returns feature description from enum
  static String getFeatureDescription(SubscriptionFeature feature) {
    switch (feature) {
      case SubscriptionFeature.realtimeMonitoring:
        return 'Monitor your child\'s emotions in real-time with the SEE device';
      case SubscriptionFeature.emotionTracking:
        return 'Track emotions manually and view historical data';
      case SubscriptionFeature.distressAlerts:
        return 'Receive alerts when your child is in distress';
      case SubscriptionFeature.advancedAnalytics:
        return 'Access detailed analytics and patterns over time';
      case SubscriptionFeature.exportReports:
        return 'Export data and reports for therapists or healthcare providers';
      case SubscriptionFeature.multipleChildren:
        return 'Add and track multiple children with one account';
      case SubscriptionFeature.prioritySupport:
        return 'Get priority support from our customer service team';
    }
  }
  
  /// Returns feature icon from enum
  static IconData getFeatureIcon(SubscriptionFeature feature) {
    switch (feature) {
      case SubscriptionFeature.realtimeMonitoring:
        return Icons.timer;
      case SubscriptionFeature.emotionTracking:
        return Icons.timeline;
      case SubscriptionFeature.distressAlerts:
        return Icons.notifications_active;
      case SubscriptionFeature.advancedAnalytics:
        return Icons.insights;
      case SubscriptionFeature.exportReports:
        return Icons.file_download;
      case SubscriptionFeature.multipleChildren:
        return Icons.group;
      case SubscriptionFeature.prioritySupport:
        return Icons.support_agent;
    }
  }
}