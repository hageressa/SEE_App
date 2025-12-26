import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/screens/parent/parent_dashboard.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/state/onboarding_state.dart';
import 'package:see_app/utils/theme.dart';

class ParentOnboardingScreen extends StatefulWidget {
  final AppUser user;

  const ParentOnboardingScreen({
    super.key,
    required this.user,
  });

  @override
  State<ParentOnboardingScreen> createState() => _ParentOnboardingScreenState();
}

class _ParentOnboardingScreenState extends State<ParentOnboardingScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<String> _concerns = [
    'Speech and Language',
    'Social Skills',
    'Behavior',
    'Motor Skills',
    'Sensory Processing',
    'Learning',
    'Attention and Focus',
    'Emotional Regulation',
    'Daily Living Skills',
    'Other',
  ];

  int _currentStep = 0;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    setState(() {
      _currentStep = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _tabController.animateTo(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _tabController.animateTo(_currentStep - 1);
    }
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SeeAppTheme.spacing24),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? SeeAppTheme.primaryColor : SeeAppTheme.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep(OnboardingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SeeAppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tell us about your child', style: SeeAppTheme.displayMedium),
          const SizedBox(height: SeeAppTheme.spacing16),
          TextFormField(
            controller: state.childNameController,
            decoration: InputDecoration(
              labelText: "Child's Name",
              hintText: "Enter your child's name",
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter your child's name";
              }
              if (value.length < 2) {
                return "Name must be at least 2 characters long";
              }
              return null;
            },
          ),
          const SizedBox(height: SeeAppTheme.spacing24),
          TextFormField(
            controller: state.childAgeController,
            decoration: InputDecoration(
              labelText: "Child's Age",
              hintText: "Enter your child's age",
              prefixIcon: const Icon(Icons.cake_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter your child's age";
              }
              final age = int.tryParse(value);
              if (age == null || age <= 0) {
                return "Please enter a valid age";
              }
              if (age > 18) {
                return "Age must be 18 or younger";
              }
              return null;
            },
          ),
          const SizedBox(height: SeeAppTheme.spacing24),
          Text('Choose an Avatar', style: SeeAppTheme.headlineMedium),
          const SizedBox(height: SeeAppTheme.spacing16),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAvatarOption(state, 'boy', 'Boy'),
                _buildAvatarOption(state, 'girl', 'Girl'),
                _buildAvatarOption(state, 'other', 'Other'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarOption(OnboardingState state, String type, String label) {
    final isSelected = state.childGender == type;
    return GestureDetector(
      onTap: () {
        state.setChildInfo(
          name: state.childName,
          age: state.childAge,
          gender: type,
        );
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? SeeAppTheme.primaryColor : Colors.transparent,
                width: 3,
              ),
              shape: BoxShape.circle,
            ),
            child: Lottie.asset(
              'assets/lottie/${type}_avatar.json',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: SeeAppTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildConcernsStep(OnboardingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SeeAppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Areas of Focus', style: SeeAppTheme.displayMedium),
          const SizedBox(height: SeeAppTheme.spacing16),
          Text(
            'Select the areas where your child might need support',
            style: SeeAppTheme.bodyLarge.copyWith(color: SeeAppTheme.textSecondary),
          ),
          const SizedBox(height: SeeAppTheme.spacing24),
          Wrap(
            spacing: SeeAppTheme.spacing12,
            runSpacing: SeeAppTheme.spacing12,
            children: _concerns.map((concern) {
              final isSelected = state.selectedConcerns.contains(concern);
              return FilterChip(
                label: Text(concern),
                selected: isSelected,
                onSelected: (bool selected) {
                  final concerns = List<String>.from(state.selectedConcerns);
                  if (selected) {
                    concerns.add(concern);
                  } else {
                    concerns.remove(concern);
                  }
                  state.setConcerns(concerns);
                },
                selectedColor: SeeAppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: SeeAppTheme.primaryColor,
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
                  side: BorderSide(
                    color: isSelected ? SeeAppTheme.primaryColor : SeeAppTheme.textSecondary.withOpacity(0.3),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStep(OnboardingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SeeAppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showConfetti)
            Lottie.asset(
              'assets/lottie/confetti.json',
              height: 200,
              repeat: false,
            ),
          Text("You're Almost Done!", style: SeeAppTheme.displayMedium),
          const SizedBox(height: SeeAppTheme.spacing16),
          Text(
            "Let's review the information you've provided:",
            style: SeeAppTheme.bodyLarge.copyWith(color: SeeAppTheme.textSecondary),
          ),
          const SizedBox(height: SeeAppTheme.spacing24),
          _buildSummaryCard(
            title: 'Basic Information',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${state.childName}'),
                Text('Age: ${state.childAge}'),
                Text('Avatar: ${state.childGender}'),
              ],
            ),
          ),
          const SizedBox(height: SeeAppTheme.spacing16),
          _buildSummaryCard(
            title: 'Areas of Focus',
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.selectedConcerns.map((concern) {
                return Chip(
                  label: Text(concern),
                  backgroundColor: SeeAppTheme.primaryColor.withOpacity(0.1),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required Widget content}) {
    return Card(
      elevation: SeeAppTheme.elevationSmall,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SeeAppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: SeeAppTheme.headlineMedium),
            const SizedBox(height: SeeAppTheme.spacing12),
            content,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<OnboardingState>(context);
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(Icons.child_care, size: 80, color: SeeAppTheme.primaryColor),
              const SizedBox(height: 32),
              Text(
                'Welcome to SEE!',
                style: SeeAppTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                "You're all set up! To get started, add your child from the dashboard after onboarding. This will help us personalize your experience.",
                style: SeeAppTheme.bodyLarge.copyWith(color: SeeAppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                                  final success = await state.completeOnboarding(databaseService);
                                  if (success && mounted) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => const ParentDashboard(),
                                      ),
                                    );
                                  } else if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to complete setup. Please try again.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
                        ),
                      ),
                child: const Text('Finish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 