import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:see_app/state/onboarding_state.dart';
import 'package:see_app/utils/theme.dart';

/// Specialties and availability view for therapist onboarding
/// Contains areas of expertise, experience level, available days and appointment types
/// Enhanced with improved UI and additional functionality
class TherapistSpecialtiesView extends StatelessWidget {
  const TherapistSpecialtiesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: Provider.of<OnboardingState>(context).specialtiesFormKey,
      child: ListView(
        padding: const EdgeInsets.all(SeeAppTheme.spacing16),
        physics: const ClampingScrollPhysics(),
        children: [
          // Enhanced header for professional specialties
          _buildHeaderCard(
            context,
            title: 'Professional Specialties',
            subtitle: 'Help parents find you based on your areas of expertise.',
            icon: Icons.psychology_outlined,
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Enhanced specialties section
          _buildSpecialtiesCard(context),
          
          const SizedBox(height: SeeAppTheme.spacing24),
          
          // Enhanced header for experience level
          _buildHeaderCard(
            context,
            title: 'Experience & Expertise',
            subtitle: 'Share your level of experience working with children with Down Syndrome.',
            icon: Icons.timeline_outlined,
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Enhanced experience level section  
          _buildExperienceCard(context),
          
          const SizedBox(height: SeeAppTheme.spacing24),
          
          // Enhanced header for scheduling preferences
          _buildHeaderCard(
            context,
            title: 'Scheduling & Availability',
            subtitle: 'Set your working days, service types, and session preferences.',
            icon: Icons.calendar_today_outlined,
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Enhanced availability section
          _buildAvailabilityCard(context),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Enhanced appointment types section
          _buildAppointmentTypesCard(context),
          
          const SizedBox(height: SeeAppTheme.spacing24),
          
          // NEW: Enhanced header for service details
          _buildHeaderCard(
            context,
            title: 'Service Details',
            subtitle: 'Set your session rates, age groups, and other important details.',
            icon: Icons.payments_outlined,
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // NEW: Service details section
          _buildServiceDetailsCard(context),
          
          const SizedBox(height: SeeAppTheme.spacing24),
          
          // Enhanced completion card
          _buildEnhancedCompletionCard(context),
          
          const SizedBox(height: SeeAppTheme.spacing32),
        ],
      ),
    );
  }
  
  /// Section header card with icon and description (consistent with credentials view)
  Widget _buildHeaderCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(SeeAppTheme.spacing16),
      decoration: BoxDecoration(
        color: SeeAppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
        border: Border.all(
          color: SeeAppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: SeeAppTheme.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: SeeAppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: SeeAppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: SeeAppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: SeeAppTheme.spacing4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: SeeAppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Enhanced specialties card with categorization
  Widget _buildSpecialtiesCard(BuildContext context) {
    final state = Provider.of<OnboardingState>(context);
    
    // Specialty categories for better organization
    final Map<String, List<String>> specialtyCategories = {
      'Therapy Types': ['Speech Therapy', 'Occupational Therapy', 'Physical Therapy', 'Behavioral Therapy', 'Music Therapy', 'Art Therapy'],
      'Developmental Areas': ['Early Intervention', 'Motor Skills', 'Language & Communication', 'Social Skills', 'Feeding & Swallowing', 'Sensory Integration'],
      'Special Focus': ['School Readiness', 'Life Skills', 'Transition Planning', 'Parent Training', 'Augmentative Communication', 'Assistive Technology'],
    };
    
    return Container(
      padding: const EdgeInsets.all(SeeAppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Helper text
          Text(
            'Select all areas of expertise that apply to your practice',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: SeeAppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Categorized specialty selection
          ...specialtyCategories.entries.map((category) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category title
                Container(
                  margin: const EdgeInsets.only(bottom: SeeAppTheme.spacing8),
                  child: Text(
                    category.key,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: SeeAppTheme.primaryColor,
                    ),
                  ),
                ),
                // Specialties wrap
                Wrap(
                  spacing: SeeAppTheme.spacing8,
                  runSpacing: SeeAppTheme.spacing8,
                  children: category.value.map((specialty) {
                    final isSelected = state.selectedSpecialties.contains(specialty);
                    return FilterChip(
                      label: Text(specialty),
                      selected: isSelected,
                      onSelected: (selected) {
                        state.toggleSpecialty(specialty, selected);
                        HapticFeedback.selectionClick();
                      },
                      backgroundColor: Colors.grey.shade50,
                      selectedColor: SeeAppTheme.primaryColor.withOpacity(0.1),
                      checkmarkColor: SeeAppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? SeeAppTheme.primaryColor : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
                        side: BorderSide(
                          color: isSelected ? SeeAppTheme.primaryColor : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: SeeAppTheme.spacing16),
              ],
            );
          }).toList(),
          
          // Selected specialties count
          Container(
            padding: const EdgeInsets.all(SeeAppTheme.spacing12),
            decoration: BoxDecoration(
              color: SeeAppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
              border: Border.all(
                color: state.selectedSpecialties.isEmpty 
                  ? SeeAppTheme.error.withOpacity(0.5) 
                  : SeeAppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  state.selectedSpecialties.isEmpty ? Icons.warning : Icons.check_circle,
                  color: state.selectedSpecialties.isEmpty ? SeeAppTheme.error : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: SeeAppTheme.spacing8),
                Text(
                  state.selectedSpecialties.isEmpty
                      ? 'Please select at least one specialty'
                      : 'You\'ve selected ${state.selectedSpecialties.length} specialties',
                  style: TextStyle(
                    color: state.selectedSpecialties.isEmpty ? SeeAppTheme.error : SeeAppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Enhanced experience level card with visual improvements
  Widget _buildExperienceCard(BuildContext context) {
    final state = Provider.of<OnboardingState>(context);
    
    return Container(
      padding: const EdgeInsets.all(SeeAppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select your level of experience with children with Down Syndrome',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: SeeAppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Enhanced experience options with icons and better visual styling
          _buildEnhancedExperienceOption(
            context: context,
            title: 'Beginner',
            icon: Icons.star_outline,
            description: 'New to working with children with Down Syndrome. Looking to grow your expertise.',
            state: state,
          ),
          
          _buildEnhancedExperienceOption(
            context: context,
            title: 'Intermediate',
            icon: Icons.star_half,
            description: '1-3 years of experience working with children with Down Syndrome.',
            state: state,
          ),
          
          _buildEnhancedExperienceOption(
            context: context,
            title: 'Expert',
            icon: Icons.star,
            description: '4+ years of specialized experience with Down Syndrome. Advanced knowledge and techniques.',
            state: state,
          ),
          
          // NEW: Additional experience details
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Years with Down Syndrome clients
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 20,
                    color: SeeAppTheme.primaryColor,
                  ),
                  const SizedBox(width: SeeAppTheme.spacing8),
                  const Text(
                    'Down Syndrome Client Count',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: SeeAppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SeeAppTheme.spacing8),
              
              // Client count slider
              StatefulBuilder(
                builder: (context, setState) {
                  // Default to 10 clients
                  double clientCount = 10;
                  
                  return Column(
                    children: [
                      Slider(
                        value: clientCount,
                        min: 0,
                        max: 50,
                        divisions: 50,
                        activeColor: SeeAppTheme.primaryColor,
                        inactiveColor: SeeAppTheme.primaryColor.withOpacity(0.2),
                        label: clientCount.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            clientCount = value;
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '0',
                            style: TextStyle(
                              fontSize: 12,
                              color: SeeAppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            "${clientCount.round()} clients",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: SeeAppTheme.primaryColor,
                            ),
                          ),
                          Text(
                            '50+',
                            style: TextStyle(
                              fontSize: 12,
                              color: SeeAppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Enhanced experience option with icon and better visual design
  Widget _buildEnhancedExperienceOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String description,
    required OnboardingState state,
  }) {
    final bool isSelected = state.experienceLevel == title;
    
    return Container(
      margin: const EdgeInsets.only(bottom: SeeAppTheme.spacing12),
      decoration: BoxDecoration(
        color: isSelected ? SeeAppTheme.primaryColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
        border: Border.all(
          color: isSelected ? SeeAppTheme.primaryColor : Colors.grey.shade200,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: SeeAppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: InkWell(
        onTap: () {
          state.setExperienceLevel(title);
          HapticFeedback.selectionClick();
        },
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(SeeAppTheme.spacing12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Radio indicator and icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? SeeAppTheme.primaryColor : Colors.grey.shade100,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey.shade500,
                  size: 20,
                ),
              ),
              const SizedBox(width: SeeAppTheme.spacing12),
              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? SeeAppTheme.primaryColor : SeeAppTheme.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: SeeAppTheme.spacing4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: SeeAppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Checkmark indicator
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: SeeAppTheme.primaryColor,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Enhanced availability card with grid layout
  Widget _buildAvailabilityCard(BuildContext context) {
    final state = Provider.of<OnboardingState>(context);
    
    return Container(
      padding: const EdgeInsets.all(SeeAppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.date_range,
                size: 20,
                color: SeeAppTheme.primaryColor,
              ),
              const SizedBox(width: SeeAppTheme.spacing8),
              const Text(
                'Available Days',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SeeAppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: SeeAppTheme.spacing12),
          Text(
            'Select the days you are typically available for appointments',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: SeeAppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Enhanced days selection with grid layout for better space utilization
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: SeeAppTheme.spacing8,
            mainAxisSpacing: SeeAppTheme.spacing8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: state.daysOfWeek.map((day) {
              final isSelected = state.availableDays.contains(day);
              final dayAbbreviation = day.substring(0, 3);
              
              return InkWell(
                onTap: () {
                  state.toggleAvailableDay(day, !isSelected);
                  HapticFeedback.selectionClick();
                },
                borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? SeeAppTheme.primaryColor 
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
                    border: Border.all(
                      color: isSelected 
                          ? SeeAppTheme.primaryColor
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayAbbreviation,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? Colors.white 
                              : SeeAppTheme.textPrimary,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          // Warning message if no days selected
          if (state.availableDays.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: SeeAppTheme.spacing12),
              padding: const EdgeInsets.all(SeeAppTheme.spacing8),
              decoration: BoxDecoration(
                color: SeeAppTheme.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
                border: Border.all(color: SeeAppTheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: SeeAppTheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: SeeAppTheme.spacing8),
                  Text(
                    'Please select at least one available day',
                    style: TextStyle(
                      color: SeeAppTheme.error,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
          // NEW: Time slot preferences
          const SizedBox(height: SeeAppTheme.spacing16),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 20,
                color: SeeAppTheme.primaryColor,
              ),
              const SizedBox(width: SeeAppTheme.spacing8),
              const Text(
                'Preferred Time Slots',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SeeAppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: SeeAppTheme.spacing12),
          
                // Time slot selection
                Wrap(
                  spacing: SeeAppTheme.spacing8,
                  runSpacing: SeeAppTheme.spacing8,
                  children: [
                    _buildTimeSlotChip(context, 'Morning (8am-12pm)'),
                    _buildTimeSlotChip(context, 'Afternoon (12pm-4pm)'),
                    _buildTimeSlotChip(context, 'Evening (4pm-8pm)'),
                    _buildTimeSlotChip(context, 'Weekends Only'),
                  ],
                ),
                
                // Show selection count
                if (state.preferredTimeSlots.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: SeeAppTheme.spacing12),
                    padding: const EdgeInsets.all(SeeAppTheme.spacing8),
                    decoration: BoxDecoration(
                      color: SeeAppTheme.error.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
                      border: Border.all(color: SeeAppTheme.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: SeeAppTheme.error,
                          size: 16,
                        ),
                        const SizedBox(width: SeeAppTheme.spacing8),
                        Text(
                          'Please select at least one time slot',
                          style: TextStyle(
                            color: SeeAppTheme.error,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
        ],
      ),
    );
  }
  
  /// Time slot selection chip connected to state
  Widget _buildTimeSlotChip(BuildContext context, String slot) {
    final state = Provider.of<OnboardingState>(context);
    final bool isSelected = state.preferredTimeSlots.contains(slot);
    
    return FilterChip(
      label: Text(slot),
      selected: isSelected,
      onSelected: (selected) {
        state.toggleTimeSlot(slot, selected);
        HapticFeedback.selectionClick();
      },
      backgroundColor: Colors.grey.shade50,
      selectedColor: SeeAppTheme.primaryColor.withOpacity(0.1),
      checkmarkColor: SeeAppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? SeeAppTheme.primaryColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
        side: BorderSide(
          color: isSelected ? SeeAppTheme.primaryColor : Colors.grey.shade300,
          width: 1,
        ),
      ),
    );
  }
  
  /// Enhanced appointment types card with improved visuals
  Widget _buildAppointmentTypesCard(BuildContext context) {
    final state = Provider.of<OnboardingState>(context);
    
    return Container(
      padding: const EdgeInsets.all(SeeAppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.meeting_room,
                size: 20,
                color: SeeAppTheme.primaryColor,
              ),
              const SizedBox(width: SeeAppTheme.spacing8),
              const Text(
                'Appointment Types',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SeeAppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: SeeAppTheme.spacing12),
          Text(
            'Choose how you prefer to meet with clients',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: SeeAppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Enhanced appointment type options with better visuals
          ...state.appointmentTypes.entries.map((entry) {
            final IconData icon = _getAppointmentIcon(entry.key);
            final String description = _getAppointmentDescription(entry.key);
            
            return _buildEnhancedAppointmentTypeOption(
              context, 
              title: entry.key,
              icon: icon,
              description: description,
              isSelected: entry.value,
              state: state,
            );
          }).toList(),
          
          // Warning if no appointment types selected
          if (!state.appointmentTypes.values.contains(true))
            Container(
              margin: const EdgeInsets.only(top: SeeAppTheme.spacing12),
              padding: const EdgeInsets.all(SeeAppTheme.spacing8),
              decoration: BoxDecoration(
                color: SeeAppTheme.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
                border: Border.all(color: SeeAppTheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: SeeAppTheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: SeeAppTheme.spacing8),
                  Text(
                    'Please select at least one appointment type',
                    style: TextStyle(
                      color: SeeAppTheme.error,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  /// Enhanced appointment type option with description and visual styling
  Widget _buildEnhancedAppointmentTypeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    required bool isSelected,
    required OnboardingState state,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: SeeAppTheme.spacing12),
      decoration: BoxDecoration(
        color: isSelected ? SeeAppTheme.primaryColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
        border: Border.all(
          color: isSelected ? SeeAppTheme.primaryColor : Colors.grey.shade200,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: SeeAppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: InkWell(
        onTap: () {
          state.toggleAppointmentType(title, !isSelected);
          HapticFeedback.selectionClick();
        },
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(SeeAppTheme.spacing12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? SeeAppTheme.primaryColor : Colors.grey.shade100,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey.shade500,
                  size: 20,
                ),
              ),
              const SizedBox(width: SeeAppTheme.spacing12),
              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? SeeAppTheme.primaryColor : SeeAppTheme.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: SeeAppTheme.spacing4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: SeeAppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? SeeAppTheme.primaryColor : Colors.white,
                  border: Border.all(
                    color: isSelected ? SeeAppTheme.primaryColor : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// NEW: Service details card for rates and client age preferences
  Widget _buildServiceDetailsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SeeAppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session rate
          _buildSessionRateSection(context),
          
          const SizedBox(height: SeeAppTheme.spacing24),
          
          // Client age preferences
          _buildClientAgeSection(context),
          
          const SizedBox(height: SeeAppTheme.spacing24),
          
          // Additional services
          _buildAdditionalServicesSection(context),
        ],
      ),
    );
  }
  
  /// Session rate section with range slider connected to state
  Widget _buildSessionRateSection(BuildContext context) {
    final state = Provider.of<OnboardingState>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.payments,
              size: 20,
              color: SeeAppTheme.primaryColor,
            ),
            const SizedBox(width: SeeAppTheme.spacing8),
            const Text(
              'Session Rates',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: SeeAppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: SeeAppTheme.spacing12),
        
        Text(
          'Set your typical fee range per session (in USD)',
          style: TextStyle(
            fontSize: 14,
            color: SeeAppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: SeeAppTheme.spacing16),
        
        // Rate selector connected to state
        StatefulBuilder(
          builder: (context, setState) {
            // Use values from state
            RangeValues _currentRangeValues = state.sessionRateRange;
            
            return Column(
              children: [
                RangeSlider(
                  values: _currentRangeValues,
                  min: 50,
                  max: 300,
                  divisions: 25,
                  activeColor: SeeAppTheme.primaryColor,
                  inactiveColor: SeeAppTheme.primaryColor.withOpacity(0.2),
                  labels: RangeLabels(
                    '\$${_currentRangeValues.start.round()}',
                    '\$${_currentRangeValues.end.round()}',
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      _currentRangeValues = values;
                      state.setSessionRateRange(values);
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${_currentRangeValues.start.round()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: SeeAppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      'to',
                      style: TextStyle(
                        fontSize: 14,
                        color: SeeAppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '\$${_currentRangeValues.end.round()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: SeeAppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                
                // Insurance note
                const SizedBox(height: SeeAppTheme.spacing12),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: SeeAppTheme.textSecondary,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: SeeAppTheme.spacing8),
                    Expanded(
                      child: Text(
                        'You\'ll be able to add insurance details after completing your profile',
                        style: TextStyle(
                          fontSize: 12,
                          color: SeeAppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
  
  /// Client age preferences section connected to state
  Widget _buildClientAgeSection(BuildContext context) {
    final state = Provider.of<OnboardingState>(context);
    // Age groups for selection
    const List<String> ageGroups = [
      'Infants (0-1 year)', 
      'Toddlers (1-3 years)', 
      'Preschool (3-5 years)',
      'Elementary (5-11 years)', 
      'Adolescents (12-17 years)', 
      'Young Adults (18+)'
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.child_care,
              size: 20,
              color: SeeAppTheme.primaryColor,
            ),
            const SizedBox(width: SeeAppTheme.spacing8),
            const Text(
              'Client Age Preferences',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: SeeAppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: SeeAppTheme.spacing12),
        
        Text(
          'Select the age groups you specialize in working with',
          style: TextStyle(
            fontSize: 14,
            color: SeeAppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: SeeAppTheme.spacing16),
        
        // Age group grid for better space utilization
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: SeeAppTheme.spacing8,
            mainAxisSpacing: SeeAppTheme.spacing8,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ageGroups.length,
          itemBuilder: (context, index) {
            final ageGroup = ageGroups[index];
            final isSelected = state.clientAgePreferences.contains(ageGroup);
            
            return InkWell(
              onTap: () {
                state.toggleClientAgePreference(ageGroup, !isSelected);
                HapticFeedback.selectionClick();
              },
              borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
              child: Container(
                padding: const EdgeInsets.all(SeeAppTheme.spacing8),
                decoration: BoxDecoration(
                  color: isSelected ? SeeAppTheme.primaryColor.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
                  border: Border.all(
                    color: isSelected ? SeeAppTheme.primaryColor : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? SeeAppTheme.primaryColor : Colors.white,
                        border: Border.all(
                          color: isSelected ? SeeAppTheme.primaryColor : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            )
                          : null,
                    ),
                    const SizedBox(width: SeeAppTheme.spacing8),
                    Expanded(
                      child: Text(
                        ageGroups[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? SeeAppTheme.primaryColor : SeeAppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        
        // Warning if no age preferences selected
        if (state.clientAgePreferences.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: SeeAppTheme.spacing12),
            padding: const EdgeInsets.all(SeeAppTheme.spacing8),
            decoration: BoxDecoration(
              color: SeeAppTheme.error.withOpacity(0.05),
              borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
              border: Border.all(color: SeeAppTheme.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: SeeAppTheme.error,
                  size: 16,
                ),
                const SizedBox(width: SeeAppTheme.spacing8),
                Text(
                  'Please select at least one age group',
                  style: TextStyle(
                    color: SeeAppTheme.error,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  /// Additional services selection connected to state
  Widget _buildAdditionalServicesSection(BuildContext context) {
    final state = Provider.of<OnboardingState>(context);
    
    // Sample additional services
    const List<String> additionalServices = [
      'Parent Coaching', 
      'Group Therapy', 
      'School Consultations',
      'IEP Support', 
      'Bilingual Services', 
      'Sibling Support',
      'Weekend Availability',
      'Emergency Services'
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.add_box,
              size: 20,
              color: SeeAppTheme.primaryColor,
            ),
            const SizedBox(width: SeeAppTheme.spacing8),
            const Text(
              'Additional Services',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: SeeAppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: SeeAppTheme.spacing12),
        
        Text(
          'Select any additional services you offer (optional)',
          style: TextStyle(
            fontSize: 14,
            color: SeeAppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: SeeAppTheme.spacing16),
        
        // Additional services wrap connected to state
        Wrap(
          spacing: SeeAppTheme.spacing8,
          runSpacing: SeeAppTheme.spacing8,
          children: additionalServices.map((service) {
            // Get current selection state from the provider
            final isSelected = state.additionalServices.contains(service);
            
            return FilterChip(
              label: Text(service),
              selected: isSelected,
              onSelected: (selected) {
                // Update state when selection changes
                state.toggleAdditionalService(service, selected);
                HapticFeedback.selectionClick();
              },
              backgroundColor: Colors.grey.shade50,
              selectedColor: SeeAppTheme.primaryColor.withOpacity(0.1),
              checkmarkColor: SeeAppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? SeeAppTheme.primaryColor : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
                side: BorderSide(
                  color: isSelected ? SeeAppTheme.primaryColor : Colors.grey.shade300,
                  width: 1,
                ),
              ),
            );
          }).toList(),
        ),
        
        // Show selection count if any services selected
        if (state.additionalServices.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: SeeAppTheme.spacing12),
            padding: const EdgeInsets.all(SeeAppTheme.spacing8),
            decoration: BoxDecoration(
              color: SeeAppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
              border: Border.all(color: SeeAppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: SeeAppTheme.spacing8),
                Text(
                  'You\'ve selected ${state.additionalServices.length} additional services',
                  style: TextStyle(
                    color: SeeAppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  /// Enhanced completion card with visual improvements
  Widget _buildEnhancedCompletionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SeeAppTheme.spacing24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SeeAppTheme.primaryColor.withOpacity(0.8),
            SeeAppTheme.primaryColor.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: SeeAppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.verified,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: SeeAppTheme.spacing16),
          const Text(
            'Your profile is almost complete!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SeeAppTheme.spacing12),
          const Text(
            'Click Finish to complete your professional profile and start connecting with families who need your expertise.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SeeAppTheme.spacing24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: SeeAppTheme.spacing12,
              horizontal: SeeAppTheme.spacing16,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: SeeAppTheme.spacing8),
                Expanded(
                  child: Text(
                    'You can update your profile information at any time from your account settings.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get appointment type icon
  IconData _getAppointmentIcon(String type) {
    switch (type) {
      case 'In-Person':
        return Icons.person;
      case 'Virtual/Telehealth':
        return Icons.videocam;
      case 'Home Visits':
        return Icons.home;
      default:
        return Icons.event;
    }
  }
  
  /// Get appointment type description
  String _getAppointmentDescription(String type) {
    switch (type) {
      case 'In-Person':
        return 'Sessions at your office or clinic location. Traditional face-to-face therapy.';
      case 'Virtual/Telehealth':
        return 'Remote sessions via video conferencing. Convenient for families with transportation challenges.';
      case 'Home Visits':
        return 'Travel to client homes for sessions in their natural environment. Additional travel fees may apply.';
      default:
        return 'Standard appointment option.';
    }
  }
}