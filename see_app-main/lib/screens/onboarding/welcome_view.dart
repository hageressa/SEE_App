import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/state/onboarding_state.dart';
import 'package:see_app/utils/theme.dart';
import 'package:see_app/widgets/see_logo.dart';

/// The welcome screen for the onboarding process.
/// This is shown as the first page to all users.
class WelcomeView extends StatelessWidget {
  const WelcomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<OnboardingState>(context);
    
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(SeeAppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.favorite,
                  size: 60,
                  color: SeeAppTheme.primaryColor,
                ),
              ),
            ),
            
            const SizedBox(height: SeeAppTheme.spacing24),
            
            // Welcome text
            Text(
              'Welcome to SEE',
              style: SeeAppTheme.headlineLarge.copyWith(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: SeeAppTheme.spacing16),
            
            // App description
            Text(
              'Supporting emotional development in children with Down syndrome through meaningful connections.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: SeeAppTheme.spacing32),
            
            // Role selection text
            Text(
              'Please select your role:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: SeeAppTheme.getResponsiveSpacing(context, SeeAppTheme.spacing32)),
            
            // Features card - removed animation that might cause rendering issues
            _buildFeaturesCard(context, state),
          ],
        ),
      ),
    );
  }

  // Features card with softer background and larger text for benefits
  Widget _buildFeaturesCard(BuildContext context, OnboardingState state) {
    return Container(
      padding: const EdgeInsets.all(SeeAppTheme.spacing24),
      decoration: BoxDecoration(
        // Softer gradient colors for better readability
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SeeAppTheme.primaryColor.withOpacity(0.12),
            SeeAppTheme.primaryColor.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusLarge),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(SeeAppTheme.spacing12),
            decoration: BoxDecoration(
              color: SeeAppTheme.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Icon(
              state.user.role == UserRole.parent
                  ? Icons.family_restroom
                  : Icons.medical_services,
              size: 48,
              color: Colors.white,
              semanticLabel: state.user.role == UserRole.parent 
                  ? 'Family icon' 
                  : 'Medical services icon',
            ),
          ),
          const SizedBox(height: SeeAppTheme.spacing16),
          Text(
            state.user.role == UserRole.parent
                ? 'You\'ll be able to:'
                : 'As a therapist, you can:',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Role-specific feature list
          ...state.user.role == UserRole.parent
              ? _buildParentFeatures(context)
              : _buildTherapistFeatures(context),
        ],
      ),
    );
  }

  // Parent-specific features with shorter, clearer text
  List<Widget> _buildParentFeatures(BuildContext context) {
    return [
      _buildFeatureItem(context, 'Track emotions daily.', Icons.track_changes),
      _buildFeatureItem(context, 'Connect with therapists.', Icons.people),
      _buildFeatureItem(context, 'Get personal guidance.', Icons.psychology),
      _buildFeatureItem(context, 'See progress clearly.', Icons.trending_up),
    ];
  }

  // Therapist-specific features with shorter, clearer text
  List<Widget> _buildTherapistFeatures(BuildContext context) {
    return [
      _buildFeatureItem(context, 'Connect with families needing help.', Icons.connect_without_contact),
      _buildFeatureItem(context, 'Manage your appointments.', Icons.calendar_month),
      _buildFeatureItem(context, 'Share helpful resources.', Icons.share),
      _buildFeatureItem(context, 'Track client progress.', Icons.insights),
    ];
  }

  // Feature item with larger text and improved styling
  Widget _buildFeatureItem(BuildContext context, String text, IconData iconData) {
    return Container(
      margin: const EdgeInsets.only(bottom: SeeAppTheme.spacing16),
      padding: const EdgeInsets.all(SeeAppTheme.spacing16), // Increased padding
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12), // Softer background
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(SeeAppTheme.spacing8),
            decoration: BoxDecoration(
              color: SeeAppTheme.primaryColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: SeeAppTheme.spacing12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: SeeAppTheme.getResponsiveFontSize(context, 17), // Larger text
              ),
            ),
          ),
        ],
      ),
    );
  }
}