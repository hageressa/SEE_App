import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/subscription_plan.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/services/connection_service.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/screens/messaging/message_screen.dart';

/// Screen for managing subscription plans and purchasing the SEE device
class SubscriptionScreen extends StatefulWidget {
  final SubscriptionFeature? highlightedFeature;
  final AppUser? therapist;
  final String? childId;
  final String? childName;
  final num? therapistFee;

  const SubscriptionScreen({
    super.key,
    this.highlightedFeature,
    this.therapist,
    this.childId,
    this.childName,
    this.therapistFee,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isYearlyBilling = false;
  SubscriptionTier _selectedTier = SubscriptionTier.free;
  final List<SubscriptionPlan> _plans = SubscriptionPlan.getPlans();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Highlight a specific plan if a feature is selected
    if (widget.highlightedFeature != null) {
      for (final plan in _plans) {
        if (plan.features.contains(widget.highlightedFeature)) {
          _selectedTier = plan.tier;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.therapist != null ? 'Payment Required' : 'Subscription Plans',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: theme_utils.SeeAppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Therapist assignment info header
          if (widget.therapist != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Therapist Assignment',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Therapist: ${widget.therapist!.name}'),
                  if (widget.childName != null) Text('Child: ${widget.childName}'),
                  if (widget.therapistFee != null) 
                    Text('Fee: \$${widget.therapistFee!.toStringAsFixed(2)}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Main content
          Expanded(
            child: Column(
              children: [
                // Tab bar
                Container(
                  color: theme_utils.SeeAppTheme.primaryColor,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    tabs: const [
                      Tab(text: 'Plans'),
                      Tab(text: 'SEE Device'),
                    ],
                  ),
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Plans tab
                      _buildPlansTab(),
                      // Device tab
                      _buildDeviceTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Plan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the plan that best fits your needs.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: theme_utils.SeeAppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Billing toggle
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBillingOption('Monthly', !_isYearlyBilling),
                  _buildBillingOption('Yearly (Save 15%)', _isYearlyBilling),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Plan cards
          ...List.generate(_plans.length, (index) {
            final plan = _plans[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPlanCard(plan),
            );
          }),
          
          const SizedBox(height: 16),
          
          // Note about device requirement
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Device Requirement',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Some features require the SEE device to function. The device monitors real-time emotional states and sends data to the app.',
                  style: TextStyle(
                    color: theme_utils.SeeAppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    _tabController.animateTo(1); // Switch to device tab
                  },
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Learn About the Device'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingOption(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isYearlyBilling = label.contains('Yearly');
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? theme_utils.SeeAppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isSelected = _selectedTier == plan.tier;
    final price = _isYearlyBilling ? plan.yearlyPrice : plan.monthlyPrice;
    final formattedPrice = price == 0 ? 'Free' : '\$${price.toStringAsFixed(2)}';
    final period = _isYearlyBilling ? '/year' : '/month';
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTier = plan.tier;
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? plan.primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: plan.primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: plan.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(theme_utils.SeeAppTheme.radiusMedium - 1),
                  topRight: Radius.circular(theme_utils.SeeAppTheme.radiusMedium - 1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              plan.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: plan.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (plan.isPopular)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
                                ),
                                child: const Text(
                                  'POPULAR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme_utils.SeeAppTheme.secondaryColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.description,
                          style: TextStyle(
                            color: plan.primaryColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            TextSpan(
                              text: formattedPrice,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: plan.primaryColor,
                              ),
                            ),
                            if (price > 0)
                              TextSpan(
                                text: period,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: plan.primaryColor.withOpacity(0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_isYearlyBilling && price > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
                          ),
                          child: const Text(
                            'SAVE 15%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Features
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Features',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    SubscriptionFeature.values.length,
                    (index) {
                      final feature = SubscriptionFeature.values[index];
                      final isIncluded = plan.features.contains(feature);
                      final isHighlighted = widget.highlightedFeature == feature;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              isIncluded ? Icons.check_circle : Icons.remove_circle_outline,
                              color: isIncluded ? Colors.green : Colors.grey.shade400,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    SubscriptionPlan.getFeatureName(feature),
                                    style: TextStyle(
                                      color: isIncluded
                                          ? theme_utils.SeeAppTheme.textPrimary
                                          : Colors.grey.shade400,
                                      fontWeight: isHighlighted ? FontWeight.bold : null,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (plan.requiresDevice && feature != SubscriptionFeature.emotionTracking)
                                    Icon(
                                      Icons.device_hub,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ).animate(
                          target: isHighlighted ? 1 : 0,
                        ).tint(
                          color: theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.05),
                          duration: const Duration(milliseconds: 300),
                        ).elevation(end: 4, duration: const Duration(milliseconds: 300)),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Action button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    
                    if (plan.requiresDevice) {
                      // Show device tab if the plan requires a device
                      _tabController.animateTo(1);
                    } else {
                      // Handle therapist assignment payment
                      if (widget.therapist != null && widget.childId != null) {
                        await _handleTherapistAssignmentPayment(plan);
                      } else {
                        // Regular subscription flow
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Free plan activated'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
                    ),
                  ),
                  child: Text(
                    widget.therapist != null ? 'Confirm Payment' : 'Choose Plan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate(
        delay: Duration(milliseconds: 100 * _plans.indexOf(plan)),
      ).fadeIn(duration: 400.ms)
       .slideY(begin: 0.05, end: 0, duration: 400.ms),
    );
  }

  Widget _buildDeviceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEE Device',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock premium features with the Smart Emotional Enhancement device.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: theme_utils.SeeAppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Device image placeholder
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
            ),
            child: const Center(
              child: Icon(
                Icons.device_hub,
                size: 80,
                color: theme_utils.SeeAppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Device description
          const Text(
            'About the SEE Device',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The SEE device is a wearable sensor designed specifically for children with Down Syndrome. '
            'It monitors vital signs and emotional indicators in real-time, providing valuable data to parents and therapists.',
            style: TextStyle(
              height: 1.5,
              color: theme_utils.SeeAppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Device features
          const Text(
            'Key Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDeviceFeature(
            icon: Icons.timer,
            title: 'Real-time Monitoring',
            description: 'Continuously tracks emotional state indicators',
          ),
          _buildDeviceFeature(
            icon: Icons.battery_full,
            title: 'Long Battery Life',
            description: 'Up to 72 hours on a single charge',
          ),
          _buildDeviceFeature(
            icon: Icons.water_drop,
            title: 'Water Resistant',
            description: 'Safe for daily activities (IPX7 rated)',
          ),
          _buildDeviceFeature(
            icon: Icons.bluetooth,
            title: 'Wireless Connection',
            description: 'Easy Bluetooth pairing with the app',
          ),
          const SizedBox(height: 24),
          
          // Purchase button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                // In a real app: Implement device purchase
                HapticFeedback.mediumImpact();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Complete Your Purchase'),
                    content: SizedBox(
                      width: 300,
                      height: 300,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SEE Device Package Includes:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('• 1x SEE Wearable Device'),
                          const Text('• 1x Charging Cable'),
                          const Text('• 1x User Manual'),
                          const Text('• Access to Premium Features'),
                          const SizedBox(height: 16),
                          const Text(
                            'Shipping Information:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Shipping Address',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Payment Method:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.credit_card, color: theme_utils.SeeAppTheme.primaryColor),
                              const SizedBox(width: 8),
                              const Text('Credit/Debit Card'),
                              const Spacer(),
                              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                            ],
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order placed successfully! Tracking information will be sent to your email.'),
                              duration: Duration(seconds: 4),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                        ),
                        child: const Text('Complete Purchase'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Purchase Device'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme_utils.SeeAppTheme.secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              children: [
                Text(
                  'Order now to receive the device within 2-3 business days',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.green[800],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Free shipping on all orders • 30-day money back guarantee',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Colors.green[700],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
            ),
            child: Icon(
              icon,
              color: theme_utils.SeeAppTheme.secondaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: theme_utils.SeeAppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Handle therapist assignment payment
  Future<void> _handleTherapistAssignmentPayment(SubscriptionPlan plan) async {
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final parentId = authService.currentUser?.id;
      
      if (parentId == null) {
        throw Exception('User not authenticated');
      }

      // Update payment status to paid
      await databaseService.updatePaymentStatus(
        parentId: parentId,
        childId: widget.childId!,
        therapistId: widget.therapist!.id,
        status: 'paid',
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful! ${widget.therapist!.name} is now assigned to ${widget.childName}.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Navigate to chat screen
      if (mounted) {
        final conversation = await databaseService.getOrCreateConversation(
          parentId, 
          widget.therapist!.id,
          metadata: {
            'childId': widget.childId,
            'childName': widget.childName,
          },
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MessageScreen(
              conversationId: conversation.id,
              otherUserId: widget.therapist!.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}