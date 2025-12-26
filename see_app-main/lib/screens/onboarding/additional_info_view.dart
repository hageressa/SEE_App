import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:see_app/state/onboarding_state.dart';
import 'package:see_app/utils/theme.dart';

/// Final step of the multi-screen parent onboarding process.
/// Redesigned to be more compact while maintaining visual appeal.
class AdditionalInfoView extends StatelessWidget {
  const AdditionalInfoView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<OnboardingState>(context);
    
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.65, 
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Form(
        key: state.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact header with icon and text in a row
            _buildCompactHeader(context),
            
            // More compact content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SeeAppTheme.spacing16,
                  vertical: SeeAppTheme.spacing8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Additional info text area
                    _buildAdditionalInfoInput(state),
                    
                    const SizedBox(height: SeeAppTheme.spacing16),
                    
                    // Therapist status selector
                    _buildTherapistStatusSelector(state),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Compact header with icon and text side-by-side
  Widget _buildCompactHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SeeAppTheme.spacing16,
        vertical: SeeAppTheme.spacing12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.withOpacity(0.2),
            Colors.blueAccent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          // Smaller icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              Icons.note_add_rounded,
              size: 38,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          
          const SizedBox(width: SeeAppTheme.spacing12),
          
          // Header text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Almost there!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 2.0,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Share any additional information that might help us",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // More compact text area for additional information
  Widget _buildAdditionalInfoInput(OnboardingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Additional Information (Optional)",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: SeeAppTheme.spacing8),
        Container(
          height: 120, // Fixed height to prevent excessive space usage
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: TextFormField(
            controller: state.additionalInfoController,
            minLines: 3,
            maxLines: 5,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: "Any other information you'd like to share about your child...",
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(SeeAppTheme.spacing12),
            ),
            // Counter for character limit
            maxLength: 500,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (
              BuildContext context, {
              required int currentLength,
              required bool isFocused,
              required int? maxLength,
            }) {
              return Text(
                "$currentLength / $maxLength",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  // More compact therapist status selector with inline info
  Widget _buildTherapistStatusSelector(OnboardingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Are you currently working with a therapist?",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: SeeAppTheme.spacing12),
        // Row of status options
        Row(
          children: [
            _buildTherapistStatusOption(
              label: "Yes",
              isSelected: state.isWorkingWithTherapist,
              icon: Icons.check_circle_outline,
              activeColor: Colors.green,
              onTap: () => state.setWorkingWithTherapist(true),
            ),
            const SizedBox(width: SeeAppTheme.spacing12),
            _buildTherapistStatusOption(
              label: "No",
              isSelected: !state.isWorkingWithTherapist,
              icon: Icons.cancel_outlined,
              activeColor: Colors.red.shade300,
              onTap: () => state.setWorkingWithTherapist(false),
            ),
          ],
        ),
        // More compact additional info if working with therapist
        if (state.isWorkingWithTherapist) 
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(top: SeeAppTheme.spacing12),
            padding: const EdgeInsets.all(SeeAppTheme.spacing12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.white.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Great! We'll prepare additional features for collaboration.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        "You can invite your therapist later from the dashboard.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  // More compact therapist status option
  Widget _buildTherapistStatusOption({
    required String label,
    required bool isSelected,
    required IconData icon,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48, // Fixed height
          padding: const EdgeInsets.symmetric(
            horizontal: SeeAppTheme.spacing8,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? activeColor.withOpacity(0.2) 
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
            border: Border.all(
              color: isSelected 
                  ? activeColor 
                  : Colors.white.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.2),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : Colors.white.withOpacity(0.6),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}