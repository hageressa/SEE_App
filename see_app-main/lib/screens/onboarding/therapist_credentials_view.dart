import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:see_app/state/onboarding_state.dart';
import 'package:see_app/utils/theme.dart';
import 'package:see_app/utils/validators.dart';

/// Professional credentials view for therapist onboarding
/// Contains comprehensive professional details including profile photo,
/// credentials, education, certifications, and license information
class TherapistCredentialsView extends StatelessWidget {
  const TherapistCredentialsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: Provider.of<OnboardingState>(context).credentialsFormKey,
      child: ListView(
        padding: const EdgeInsets.all(SeeAppTheme.spacing16),
        physics: const ClampingScrollPhysics(),
        children: [
          // Professional profile card with profile photo
          _buildProfilePhotoCard(context),
          
          const SizedBox(height: SeeAppTheme.spacing24),
          
          // Professional title with enhanced container styling
          _buildHeaderCard(
            context,
            title: 'Professional Information',
            subtitle: 'This detailed information helps parents find the right specialist for their child.',
            icon: Icons.badge_outlined,
          ),
          
          const SizedBox(height: SeeAppTheme.spacing24),

          // Professional details form
          _buildCredentialsForm(context),
          
          const SizedBox(height: SeeAppTheme.spacing24),
          
          // Education & Certifications
          _buildHeaderCard(
            context,
            title: 'Education & Certifications',
            subtitle: 'Share your academic background and professional qualifications.',
            icon: Icons.school_outlined,
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Education form
          _buildEducationForm(context),
          
          const SizedBox(height: SeeAppTheme.spacing24),
          
          // License & Verification
          _buildHeaderCard(
            context,
            title: 'License & Verification',
            subtitle: 'Add your professional license and credentials for verification.',
            icon: Icons.verified_outlined,
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // License form
          _buildLicenseForm(context),
          
          const SizedBox(height: SeeAppTheme.spacing24),
          
          // Contact & Social
          _buildHeaderCard(
            context, 
            title: 'Contact & Practice', 
            subtitle: 'How parents can reach you or learn more about your practice.',
            icon: Icons.business_outlined,
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Contact form
          _buildContactForm(context),
          
          const SizedBox(height: SeeAppTheme.spacing32),
        ],
      ),
    );
  }
  
  /// Profile photo card with upload functionality
  Widget _buildProfilePhotoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SeeAppTheme.spacing16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SeeAppTheme.primaryColor.withOpacity(0.7),
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
          const Text(
            'Welcome to the SEE Professional Network',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SeeAppTheme.spacing24),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Profile avatar container
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Provider.of<OnboardingState>(context).profilePhotoUrl.isNotEmpty
                      ? Image.network(
                          Provider.of<OnboardingState>(context).profilePhotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback if image loading fails
                            return const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const CircularProgressIndicator();
                          },
                        )
                      : const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.grey,
                        ),
                ),
              ),
              // Upload button overlay
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SeeAppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    _showPhotoUploadOptions(context, Provider.of<OnboardingState>(context, listen: false));
                  },
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SeeAppTheme.spacing16),
          const Text(
            'Add a professional photo',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SeeAppTheme.spacing8),
          const Text(
            'A clear, professional headshot helps build trust with parents',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Section header card with icon and description
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

  /// Professional credentials form 
  Widget _buildCredentialsForm(BuildContext context) {
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Specialty with icon
          _buildFormField(
            context: context,
            controller: state.specialtyController,
            label: 'Primary Specialty',
            hint: 'e.g. Speech Pathologist, OT, PT',
            icon: Icons.star,
            validator: FormValidators.requiredField,
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Secondary specialty (new field)
          _buildFormField(
            context: context,
            controller: TextEditingController(), // Would need to be added to state
            label: 'Secondary Specialty (Optional)',
            hint: 'e.g. Behavioral Therapy, Early Intervention',
            icon: Icons.psychology,
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Professional title connected to state
          _buildFormField(
            context: context,
            controller: state.professionalTitleController,
            label: 'Professional Title',
            hint: 'e.g. Lead Therapist, Clinical Director',
            icon: Icons.badge,
            validator: FormValidators.requiredField,
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Years of Experience with slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.work_history,
                    size: 20,
                    color: SeeAppTheme.primaryColor,
                  ),
                  const SizedBox(width: SeeAppTheme.spacing8),
                  const Text(
                    'Years of Experience',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: SeeAppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SeeAppTheme.spacing8),
              
              StatefulBuilder(
                builder: (context, setState) {
                  // Default to 5 years for this demo
                  double years = 5;
                  
                  if (state.experienceController.text.isNotEmpty) {
                    years = double.tryParse(state.experienceController.text) ?? 5;
                  }
                  
                  return Column(
                    children: [
                      Slider(
                        value: years,
                        min: 0,
                        max: 30,
                        divisions: 30,
                        activeColor: SeeAppTheme.primaryColor,
                        inactiveColor: SeeAppTheme.primaryColor.withOpacity(0.2),
                        label: years.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            years = value;
                            state.experienceController.text = value.round().toString();
                          });
                        },
                      ),
                      Text(
                        "${years.round()} ${years.round() == 1 ? 'year' : 'years'}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: SeeAppTheme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // About with rich text editor styling 
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.description,
                    size: 20,
                    color: SeeAppTheme.primaryColor,
                  ),
                  const SizedBox(width: SeeAppTheme.spacing8),
                  const Text(
                    'About Your Practice',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: SeeAppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SeeAppTheme.spacing8),
              
              // Text editor toolbar simulation
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SeeAppTheme.spacing8, 
                  vertical: SeeAppTheme.spacing4
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(SeeAppTheme.radiusMedium),
                    topRight: Radius.circular(SeeAppTheme.radiusMedium),
                  ),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.format_bold, size: 18),
                      onPressed: () {},
                      color: Colors.grey.shade700,
                      tooltip: 'Bold',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_italic, size: 18),
                      onPressed: () {},
                      color: Colors.grey.shade700,
                      tooltip: 'Italic',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_list_bulleted, size: 18),
                      onPressed: () {},
                      color: Colors.grey.shade700,
                      tooltip: 'Bullet List',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: const Icon(Icons.link, size: 18),
                      onPressed: () {},
                      color: Colors.grey.shade700,
                      tooltip: 'Add Link',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(SeeAppTheme.radiusMedium),
                    bottomRight: Radius.circular(SeeAppTheme.radiusMedium),
                  ),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: TextFormField(
                  controller: state.aboutController,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Tell parents about your approach and experience with children with Down Syndrome...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(SeeAppTheme.spacing16),
                  ),
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  validator: (value) => FormValidators.validateMinLength(value, 30),
                ),
              ),
              
              const SizedBox(height: SeeAppTheme.spacing8),
              
              // Character count
              StatefulBuilder(
                builder: (context, setState) {
                  state.aboutController.addListener(() {
                    setState(() {});
                  });
                  
                  final int charCount = state.aboutController.text.length;
                  final bool isMinLength = charCount >= 30;
                  
                  return Text(
                    '$charCount characters (min. 30)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isMinLength ? Colors.green : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.right,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Education and certifications form
  Widget _buildEducationForm(BuildContext context) {
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Highest degree connected to state
          _buildFormField(
            context: context,
            controller: state.degreeController,
            label: 'Highest Degree',
            hint: 'e.g. Master\'s in Speech-Language Pathology',
            icon: Icons.school,
            validator: FormValidators.requiredField,
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // University/institution connected to state
          _buildFormField(
            context: context,
            controller: state.institutionController,
            label: 'University/Institution',
            hint: 'e.g. University of Michigan',
            icon: Icons.account_balance,
            validator: FormValidators.requiredField,
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Graduation Year connected to state
          _buildFormField(
            context: context,
            controller: state.graduationYearController,
            label: 'Graduation Year',
            hint: 'e.g. 2015',
            icon: Icons.calendar_today,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter graduation year';
              }
              final int? year = int.tryParse(value);
              if (year == null) {
                return 'Please enter a valid year';
              }
              if (year < 1950 || year > DateTime.now().year) {
                return 'Please enter a valid graduation year';
              }
              return null;
            },
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Certifications
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    size: 20,
                    color: SeeAppTheme.primaryColor,
                  ),
                  const SizedBox(width: SeeAppTheme.spacing8),
                  const Text(
                    'Certifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: SeeAppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SeeAppTheme.spacing12),
              
              // Certification chips connected to state
              _buildCertificationChips(context, state),
              
              const SizedBox(height: SeeAppTheme.spacing12),
              
              // Add certification button
              ElevatedButton.icon(
                onPressed: () {
                  _showAddCertificationDialog(context, state);
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Certification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: SeeAppTheme.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: SeeAppTheme.spacing16,
                    vertical: SeeAppTheme.spacing12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// License and verification form
  Widget _buildLicenseForm(BuildContext context) {
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // License number connected to state
          _buildFormField(
            context: context,
            controller: state.licenseNumberController,
            label: 'License Number',
            hint: 'e.g. SLP12345678',
            icon: Icons.badge,
            validator: FormValidators.requiredField,
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Issuing authority connected to state
          _buildFormField(
            context: context,
            controller: state.licenseAuthorityController,
            label: 'Issuing Authority/State',
            hint: 'e.g. California Board of Speech-Language Pathology',
            icon: Icons.location_city,
            validator: FormValidators.requiredField,
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Expiration date with working date picker
          _buildFormField(
            context: context,
            controller: TextEditingController(
              text: state.licenseExpiration != null
                  ? '${state.licenseExpiration!.month}/${state.licenseExpiration!.year}'
                  : '',
            ),
            label: 'Expiration Date',
            hint: 'MM/YYYY',
            icon: Icons.event,
            validator: FormValidators.requiredField,
            onTap: () {
              _showDatePicker(context, state);
            },
            readOnly: true,
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // License upload
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 20,
                    color: SeeAppTheme.primaryColor,
                  ),
                  const SizedBox(width: SeeAppTheme.spacing8),
                  const Text(
                    'License Document',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: SeeAppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SeeAppTheme.spacing12),
              
              // Upload box with document preview
              state.licenseDocumentUrl.isNotEmpty
                ? _buildLicenseDocumentPreview(context, state)
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(SeeAppTheme.spacing16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: SeeAppTheme.spacing8),
                        const Text(
                          'Drag and drop or click to upload',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: SeeAppTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: SeeAppTheme.spacing4),
                        Text(
                          'PDF, JPG or PNG (max 5MB)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: SeeAppTheme.spacing12),
                        ElevatedButton(
                          onPressed: () {
                            _uploadLicenseDocument(context, state);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SeeAppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: SeeAppTheme.spacing16,
                              vertical: SeeAppTheme.spacing12,
                            ),
                          ),
                          child: const Text('Select File'),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Contact and social media form
  Widget _buildContactForm(BuildContext context) {
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Practice/Clinic name connected to state
          _buildFormField(
            context: context,
            controller: state.practiceNameController,
            label: 'Practice/Clinic Name',
            hint: 'e.g. Better Horizons Therapy',
            icon: Icons.business,
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Practice website connected to state
          _buildFormField(
            context: context,
            controller: state.websiteController,
            label: 'Website (Optional)',
            hint: 'e.g. https://example.com',
            icon: Icons.language,
            keyboardType: TextInputType.url,
          ),
          
          const SizedBox(height: SeeAppTheme.spacing16),
          
          // Social media
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.share,
                    size: 20,
                    color: SeeAppTheme.primaryColor,
                  ),
                  const SizedBox(width: SeeAppTheme.spacing8),
                  const Text(
                    'Social Media (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: SeeAppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SeeAppTheme.spacing12),
              
              // Social media inputs in a row for better space efficiency
              Row(
                children: [
                  Expanded(
                    child: _buildSocialMediaInput(
                      context,
                      controller: state.linkedinController,
                      icon: Icons.business_center,
                      hint: 'LinkedIn',
                      iconColor: const Color(0xFF0077B5),
                    ),
                  ),
                  const SizedBox(width: SeeAppTheme.spacing12),
                  Expanded(
                    child: _buildSocialMediaInput(
                      context,
                      controller: state.facebookController,
                      icon: Icons.facebook,
                      hint: 'Facebook',
                      iconColor: const Color(0xFF1877F2),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: SeeAppTheme.spacing12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildSocialMediaInput(
                      context,
                      controller: state.youtubeController,
                      icon: Icons.video_library,
                      hint: 'YouTube',
                      iconColor: const Color(0xFFFF0000),
                    ),
                  ),
                  const SizedBox(width: SeeAppTheme.spacing12),
                  Expanded(
                    child: _buildSocialMediaInput(
                      context,
                      controller: state.instagramController,
                      icon: Icons.camera_alt,
                      hint: 'Instagram',
                      iconColor: const Color(0xFFE1306C),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Generic form field with icon
  Widget _buildFormField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FormFieldValidator<String>? validator,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: SeeAppTheme.primaryColor,
            ),
            const SizedBox(width: SeeAppTheme.spacing8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: SeeAppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: SeeAppTheme.spacing8),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? Colors.grey.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: SeeAppTheme.spacing16, 
                vertical: SeeAppTheme.spacing12
              ),
              suffixIcon: readOnly ? const Icon(Icons.arrow_drop_down, color: Colors.grey) : null,
            ),
            textInputAction: textInputAction,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            readOnly: readOnly,
            onTap: onTap,
          ),
        ),
      ],
    );
  }
  
  /// Social media input with icon
  Widget _buildSocialMediaInput(
    BuildContext context, {
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: SeeAppTheme.spacing16, 
            vertical: SeeAppTheme.spacing12
          ),
          prefixIcon: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        textInputAction: TextInputAction.next,
      ),
    );
  }
  
  /// Certification chips display
  Widget _buildCertificationChips(BuildContext context, OnboardingState state) {
    return Wrap(
      spacing: SeeAppTheme.spacing8,
      runSpacing: SeeAppTheme.spacing8,
      children: state.certifications.map((cert) {
        return Chip(
          label: Text(cert),
          backgroundColor: SeeAppTheme.primaryColor.withOpacity(0.1),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () {
            // Remove certification
            state.removeCertification(cert);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Removed $cert'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          },
          labelStyle: const TextStyle(
            color: SeeAppTheme.primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: SeeAppTheme.spacing8,
            vertical: SeeAppTheme.spacing4,
          ),
        );
      }).toList(),
    );
  }
  
  /// Dialog to add a new certification
  void _showAddCertificationDialog(BuildContext context, OnboardingState state) {
    final TextEditingController certController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Certification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your professional certification or credential',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: SeeAppTheme.spacing16),
            TextField(
              controller: certController,
              decoration: const InputDecoration(
                labelText: 'Certification',
                hintText: 'e.g. ASHA CCC-SLP, BCBA, etc.',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (certController.text.isNotEmpty) {
                state.addCertification(certController.text.trim());
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SeeAppTheme.primaryColor,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  /// Photo upload options dialog
  void _showPhotoUploadOptions(BuildContext context, OnboardingState state) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Upload Profile Photo'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _uploadProfilePhoto(context, state, true);
            },
            child: const ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take Photo'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _uploadProfilePhoto(context, state, false);
            },
            child: const ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Upload profile photo (simulated)
  void _uploadProfilePhoto(BuildContext context, OnboardingState state, bool camera) {
    // In a real app, this would use image_picker package to get the image
    // For this implementation, we'll simulate it with a fixed URL
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Uploading photo...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    // Simulate a delay for the upload
    Future.delayed(const Duration(milliseconds: 1500), () {
      // Set a placeholder profile image URL
      state.setProfilePhotoUrl('https://randomuser.me/api/portraits/men/32.jpg');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }
  
  /// License document preview
  Widget _buildLicenseDocumentPreview(BuildContext context, OnboardingState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SeeAppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
        border: Border.all(
          color: SeeAppTheme.primaryColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SeeAppTheme.spacing8),
                decoration: BoxDecoration(
                  color: SeeAppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(SeeAppTheme.radiusSmall),
                ),
                child: const Icon(
                  Icons.description,
                  color: SeeAppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: SeeAppTheme.spacing12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'License Document',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'PDF Document',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  state.setLicenseDocumentUrl('');
                },
                color: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: SeeAppTheme.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  // View document action
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening document...'),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SeeAppTheme.primaryColor,
                  side: BorderSide(color: SeeAppTheme.primaryColor),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _uploadLicenseDocument(context, state);
                },
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Replace'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SeeAppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Upload license document (simulated)
  void _uploadLicenseDocument(BuildContext context, OnboardingState state) {
    // In a real app, this would use file_picker package to get the document
    // For this implementation, we'll simulate it
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Uploading document...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    // Simulate a delay for the upload
    Future.delayed(const Duration(milliseconds: 1500), () {
      // Set a placeholder document URL
      state.setLicenseDocumentUrl('https://example.com/license_document.pdf');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('License document uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }
  
  /// Show date picker for license expiration
  void _showDatePicker(BuildContext context, OnboardingState state) async {
    final DateTime currentDate = DateTime.now();
    final DateTime initialDate = state.licenseExpiration ?? 
                                DateTime(currentDate.year + 2, currentDate.month);
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: currentDate,
      lastDate: DateTime(currentDate.year + 10),
      helpText: 'SELECT LICENSE EXPIRATION DATE',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: SeeAppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: SeeAppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      state.setLicenseExpiration(picked);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'License expiration set to ${picked.month}/${picked.year}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}