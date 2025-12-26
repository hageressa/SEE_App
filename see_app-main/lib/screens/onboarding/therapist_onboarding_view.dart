import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_app/screens/onboarding/therapist_credentials_view.dart';
import 'package:see_app/screens/onboarding/therapist_specialties_view.dart';
import 'package:see_app/state/onboarding_state.dart';

/// Therapist-specific onboarding view that acts as a router for the separate view screens.
/// Now redirects to the appropriate view component based on the current page.
/// This maintains backwards compatibility while allowing the modular approach.
class TherapistOnboardingView extends StatelessWidget {
  const TherapistOnboardingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<OnboardingState>(context);
    
    // Determine which page to show based on current index
    if (state.currentPage == 1) {
      return const TherapistCredentialsView();
    } else {
      return const TherapistSpecialtiesView();
    }
  }
}