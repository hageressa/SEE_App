import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/screens/onboarding/parent_onboarding_screen.dart';
import 'package:see_app/screens/onboarding/therapist_credentials_view.dart';
import 'package:see_app/screens/onboarding/therapist_onboarding_view.dart';
import 'package:see_app/screens/onboarding/therapist_specialties_view.dart';
import 'package:see_app/screens/onboarding/welcome_view.dart';
import 'package:see_app/screens/parent/parent_dashboard.dart';
import 'package:see_app/screens/therapist/redesigned_therapist_dashboard.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/state/onboarding_state.dart';
import 'package:see_app/utils/theme.dart';
import 'package:see_app/screens/onboarding/therapist_onboarding_steps/welcome_step.dart';
import 'package:see_app/screens/onboarding/therapist_onboarding_steps/profile_step.dart';
import 'package:see_app/screens/onboarding/therapist_onboarding_steps/professional_info_step.dart';
import 'package:see_app/screens/onboarding/therapist_onboarding_steps/about_step.dart';
import 'package:see_app/screens/onboarding/therapist_onboarding_steps/specialties_step.dart';
import 'package:see_app/screens/onboarding/therapist_onboarding_steps/availability_step.dart';
import 'package:see_app/screens/onboarding/therapist_onboarding_steps/credentials_step.dart';
import 'package:see_app/screens/onboarding/therapist_onboarding_steps/review_step.dart';

/// A screen that guides new users through setting up their account 
/// with an improved, structured onboarding experience.
class OnboardingScreen extends StatelessWidget {
  final AppUser user;
  
  const OnboardingScreen({
    super.key, 
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    // For parents, use the new streamlined onboarding screen
    if (user.role == UserRole.parent) {
      return ParentOnboardingScreen(user: user);
    }

    // For therapists, keep the existing flow
    return ChangeNotifierProvider(
      create: (_) => OnboardingState(user: user),
      child: const _TherapistOnboardingContent(),
    );
  }
}

class _TherapistOnboardingContent extends StatefulWidget {
  const _TherapistOnboardingContent();

  @override
  State<_TherapistOnboardingContent> createState() => _TherapistOnboardingContentState();
}

class _TherapistOnboardingContentState extends State<_TherapistOnboardingContent> {
  bool _isLoading = false;
  int _currentStep = 0;
  late final List<Widget> _steps;
  late final List<String> _stepTitles;

  @override
  void initState() {
    super.initState();
    _steps = [
      WelcomeStep(),
      ProfileStep(),
      ProfessionalInfoStep(),
      AboutStep(),
      SpecialtiesStep(),
      AvailabilityStep(),
      CredentialsStep(),
      ReviewStep(),
    ];
    _stepTitles = [
      'Welcome',
      'Profile',
      'Professional Info',
      'About You',
      'Specialties',
      'Availability',
      'Credentials',
      'Review',
    ];
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  bool _isCurrentStepSkippable() {
    // Specialties, Availability, and Credentials steps are skippable.
    return _currentStep >= 4 && _currentStep <= 6;
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isLoading = true);
    try {
      final state = Provider.of<OnboardingState>(context, listen: false);
      await DatabaseService().updateUser(state.user.id, {
        'onboardingCompleted': true,
        'professionalTitle': state.professionalTitleController.text,
        'experience': state.experienceController.text,
        'about': state.aboutController.text,
        'specialties': state.selectedSpecialties,
      });
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const RedesignedTherapistDashboard(),
          ),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      // Handle error, maybe show a snackbar
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildStepper(),
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: _steps,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                TextButton.icon(
                  onPressed: _previousStep,
                  icon: Icon(Icons.arrow_back_ios, size: 16, color: Colors.white70),
                  label: Text('Back', style: TextStyle(color: Colors.white70, fontSize: 16)),
                )
              else
                const SizedBox(width: 90),
              Row(
                children: [
                  if (_isCurrentStepSkippable())
                    TextButton(
                      onPressed: _nextStep,
                      child: const Text('Skip', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ),
                  if (_isCurrentStepSkippable()) const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _currentStep < _steps.length - 1 ? _nextStep : _finishOnboarding,
                    child: Text(
                      _currentStep < _steps.length - 1 ? 'Next' : 'Finish',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentStep < _steps.length - 1 ? Colors.white : Colors.green,
                      foregroundColor: _currentStep < _steps.length - 1 ? Theme.of(context).colorScheme.primary : Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: List.generate(_stepTitles.length, (i) {
          final isActive = i == _currentStep;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }
} 