import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:uuid/uuid.dart';

class OnboardingState extends ChangeNotifier {
  final AppUser user;
  late PageController _pageController;
  int _currentPage = 0;
  int _totalPages = 3;
  bool _isLoading = false;
  String? _validationMessage;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> credentialsFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> specialtiesFormKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController childNameController = TextEditingController();
  final TextEditingController childAgeController = TextEditingController();
  final TextEditingController additionalInfoController = TextEditingController();
  
  // Therapist form controllers
  final TextEditingController specialtyController = TextEditingController();
  final TextEditingController professionalTitleController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController degreeController = TextEditingController();
  final TextEditingController institutionController = TextEditingController();
  final TextEditingController graduationYearController = TextEditingController();
  final TextEditingController licenseNumberController = TextEditingController();
  final TextEditingController licenseAuthorityController = TextEditingController();
  final TextEditingController practiceNameController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController linkedinController = TextEditingController();
  final TextEditingController facebookController = TextEditingController();
  final TextEditingController youtubeController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();

  // Form data
  Map<String, dynamic> formData = {
    'childName': '',
    'childAge': 0,
    'childGender': '',
    'childBirthdate': null,
    'additionalInfo': '',
    'parentConcerns': <String, bool>{},
    'selectedConcerns': <String>[],
    'isWorkingWithTherapist': false,
    
    // Therapist specific fields
    'specialty': '',
    'professionalTitle': '',
    'experience': '',
    'about': '',
    'selectedSpecialties': <String>[],
    'profilePhotoUrl': '',
    'certifications': <String>[],
    'degree': '',
    'institution': '',
    'graduationYear': '',
    'licenseNumber': '',
    'licenseAuthority': '',
    'licenseExpiration': null,
    'licenseDocumentUrl': '',
    'practiceName': '',
    'website': '',
    'socialMedia': {
      'linkedin': '',
      'facebook': '',
      'youtube': '',
      'instagram': '',
    },
    'experienceLevel': '',
    'clientAgePreferences': <String>[],
    'preferredTimeSlots': <String>[],
    'additionalServices': <String>[],
    'sessionRateRange': const RangeValues(50, 200),
    'downsClientCount': 0,
    'availableDays': <String>[],
    'appointmentTypes': <String, bool>{},
  };

  // Days of week for availability selection
  final List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Child info
  String _childName = '';
  int _childAge = 0;
  String _childGender = '';
  List<String> _selectedConcerns = [];

  // Getters
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isLoading => _isLoading;
  String? get validationMessage => _validationMessage;
  PageController get pageController => _pageController;

  // Child info getters
  String get childName => formData['childName'] as String;
  int get childAge => formData['childAge'] as int;
  String get childGender => formData['childGender'] as String;
  List<String> get selectedConcerns => 
      List<String>.from(formData['selectedConcerns'] as List<dynamic>);
  DateTime? get childBirthdate => formData['childBirthdate'] as DateTime?;
  String get additionalInfo => formData['additionalInfo'] as String;
  Map<String, bool> get parentConcerns => 
      Map<String, bool>.from(formData['parentConcerns'] as Map<dynamic, dynamic>);
  bool get isWorkingWithTherapist => formData['isWorkingWithTherapist'] as bool;
  
  // Therapist getters
  List<String> get selectedSpecialties => 
      List<String>.from(formData['selectedSpecialties'] as List<dynamic>);
  List<String> get availableDays => 
      List<String>.from(formData['availableDays'] as List<dynamic>);
  String get experienceLevel => formData['experienceLevel'] as String;
  Map<String, bool> get appointmentTypes => 
      Map<String, bool>.from(formData['appointmentTypes'] as Map<dynamic, dynamic>);
      
  // Additional therapist getters
  String get profilePhotoUrl => formData['profilePhotoUrl'] as String;
  List<String> get certifications => 
      List<String>.from(formData['certifications'] as List<dynamic>);
  String get professionalTitle => formData['professionalTitle'] as String;
  String get degree => formData['degree'] as String;
  String get institution => formData['institution'] as String;
  String get graduationYear => formData['graduationYear'] as String;
  String get licenseNumber => formData['licenseNumber'] as String;
  String get licenseAuthority => formData['licenseAuthority'] as String;
  DateTime? get licenseExpiration => formData['licenseExpiration'] as DateTime?;
  String get licenseDocumentUrl => formData['licenseDocumentUrl'] as String;
  String get practiceName => formData['practiceName'] as String;
  String get website => formData['website'] as String;
  Map<String, String> get socialMedia => 
      Map<String, String>.from(formData['socialMedia'] as Map<dynamic, dynamic>);
  
  List<String> get preferredTimeSlots => 
      List<String>.from(formData['preferredTimeSlots'] as List<dynamic>);
  List<String> get clientAgePreferences => 
      List<String>.from(formData['clientAgePreferences'] as List<dynamic>);
  RangeValues get sessionRateRange => formData['sessionRateRange'] as RangeValues;
  List<String> get additionalServices => 
      List<String>.from(formData['additionalServices'] as List<dynamic>);
  int get downsClientCount => formData['downsClientCount'] as int;

  // Methods
  void setPageController(PageController controller) {
    _pageController = controller;
  }
  
  void setCurrentPage(int page) {
    _currentPage = page;
    _validationMessage = null;
    notifyListeners();
  }
  
  void nextPage() {
    if (_currentPage < _totalPages - 1) {
      _currentPage++;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }
  
  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Parent-specific handlers
  void setGender(String gender) {
    formData['childGender'] = gender;
    notifyListeners();
  }
  
  void setChildBirthdate(DateTime birthdate) {
    formData['childBirthdate'] = birthdate;
    final now = DateTime.now();
    final age = (now.difference(birthdate).inDays / 365).floor();
    formData['childAge'] = age;
    childAgeController.text = age.toString();
    notifyListeners();
  }
  
  void toggleConcern(String concern, bool value) {
    final concerns = Map<String, bool>.from(formData['parentConcerns'] as Map<dynamic, dynamic>);
    concerns[concern] = value;
    formData['parentConcerns'] = concerns;
    notifyListeners();
  }
  
  void setWorkingWithTherapist(bool value) {
    formData['isWorkingWithTherapist'] = value;
    notifyListeners();
  }
  
  // Therapist-specific handlers
  void toggleSpecialty(String specialty, bool selected) {
    final specialties = List<String>.from(formData['selectedSpecialties'] as List<dynamic>);
    if (selected && !specialties.contains(specialty)) {
      specialties.add(specialty);
    } else if (!selected && specialties.contains(specialty)) {
      specialties.remove(specialty);
    }
    formData['selectedSpecialties'] = specialties;
    notifyListeners();
  }
  
  void setProfilePhotoUrl(String url) {
    formData['profilePhotoUrl'] = url;
    notifyListeners();
  }
  
  void addCertification(String certification) {
    final certs = List<String>.from(formData['certifications'] as List<dynamic>);
    if (!certs.contains(certification)) {
      certs.add(certification);
      formData['certifications'] = certs;
      notifyListeners();
    }
  }
  
  void removeCertification(String certification) {
    final certs = List<String>.from(formData['certifications'] as List<dynamic>);
    if (certs.contains(certification)) {
      certs.remove(certification);
      formData['certifications'] = certs;
      notifyListeners();
    }
  }
  
  void setLicenseExpiration(DateTime date) {
    formData['licenseExpiration'] = date;
    notifyListeners();
  }
  
  void setLicenseDocumentUrl(String url) {
    formData['licenseDocumentUrl'] = url;
    notifyListeners();
  }
  
  void toggleClientAgePreference(String ageGroup, bool selected) {
    final ageGroups = List<String>.from(formData['clientAgePreferences'] as List<dynamic>);
    if (selected && !ageGroups.contains(ageGroup)) {
      ageGroups.add(ageGroup);
    } else if (!selected && ageGroups.contains(ageGroup)) {
      ageGroups.remove(ageGroup);
    }
    formData['clientAgePreferences'] = ageGroups;
    notifyListeners();
  }
  
  void toggleTimeSlot(String timeSlot, bool selected) {
    final timeSlots = List<String>.from(formData['preferredTimeSlots'] as List<dynamic>);
    if (selected && !timeSlots.contains(timeSlot)) {
      timeSlots.add(timeSlot);
    } else if (!selected && timeSlots.contains(timeSlot)) {
      timeSlots.remove(timeSlot);
    }
    formData['preferredTimeSlots'] = timeSlots;
    notifyListeners();
  }
  
  void toggleAdditionalService(String service, bool selected) {
    final services = List<String>.from(formData['additionalServices'] as List<dynamic>);
    if (selected && !services.contains(service)) {
      services.add(service);
    } else if (!selected && services.contains(service)) {
      services.remove(service);
    }
    formData['additionalServices'] = services;
    notifyListeners();
  }
  
  void setSessionRateRange(RangeValues range) {
    formData['sessionRateRange'] = range;
    notifyListeners();
  }
  
  void setDownsClientCount(int count) {
    formData['downsClientCount'] = count;
    notifyListeners();
  }
  
  void toggleAvailableDay(String day, bool selected) {
    final days = List<String>.from(formData['availableDays'] as List<dynamic>);
    if (selected && !days.contains(day)) {
      days.add(day);
    } else if (!selected && days.contains(day)) {
      days.remove(day);
    }
    formData['availableDays'] = days;
    notifyListeners();
  }
  
  void toggleAppointmentType(String type, bool value) {
    final types = Map<String, bool>.from(formData['appointmentTypes'] as Map<dynamic, dynamic>);
    types[type] = value;
    formData['appointmentTypes'] = types;
    notifyListeners();
  }
  
  void setExperienceLevel(String level) {
    formData['experienceLevel'] = level;
    notifyListeners();
  }

  // Form validation
  bool validateCurrentPage() {
    _validationMessage = null;
    
    if (_currentPage == 0) {
      return true;
    } else if (user.role == UserRole.parent) {
      switch (_currentPage) {
        case 1:
          return _validateChildBasicInfo();
        case 2:
          return _validateConcerns();
        case 3:
          return true;
        default:
          return true;
      }
    } else if (user.role == UserRole.therapist) {
      switch (_currentPage) {
        case 1:
          return _validateTherapistInfo();
        case 2:
          return _validateTherapistAvailability();
        default:
          return true;
      }
    }
    
    return true;
  }
  
  bool _validateChildBasicInfo() {
    if (childName.isEmpty) {
      _validationMessage = "Please enter your child's name";
      notifyListeners();
      return false;
    }

    if (childAge <= 0) {
      _validationMessage = "Please enter a valid age";
      notifyListeners();
      return false;
    }

    if (childGender.isEmpty) {
      _validationMessage = "Please select your child's gender";
      notifyListeners();
      return false;
    }

    return formKey.currentState?.validate() ?? true;
  }
  
  bool _validateConcerns() {
    if (!parentConcerns.values.contains(true)) {
      _validationMessage = 'Please select at least one area of focus';
      notifyListeners();
      return false;
    }
    return formKey.currentState?.validate() ?? true;
  }
  
  bool _validateTherapistInfo() {
    if (formData['specialty']?.toString().isEmpty ?? true) {
      _validationMessage = 'Please enter your primary specialty';
      notifyListeners();
      return false;
    }
    
    if (formData['experience']?.toString().isEmpty ?? true) {
      _validationMessage = 'Please enter your years of experience';
      notifyListeners();
      return false;
    }
    
    if (formData['about']?.toString().isEmpty ?? true) {
      _validationMessage = 'Please tell us about yourself';
      notifyListeners();
      return false;
    }
    
    return credentialsFormKey.currentState?.validate() ?? true;
  }
  
  bool _validateTherapistAvailability() {
    final List<String> errors = [];
    
    if (selectedSpecialties.isEmpty) {
      errors.add('Please select at least one specialty');
    }
    
    if (availableDays.isEmpty) {
      errors.add('Please select at least one available day');
    }
    
    if (!appointmentTypes.values.contains(true)) {
      errors.add('Please select at least one appointment type');
    }
    
    if (errors.isNotEmpty) {
      _validationMessage = errors.join('\n');
      notifyListeners();
      return false;
    }
    
    return true;
  }
  
  int calculateAgeFromBirthdate() {
    if (formData['childBirthdate'] == null) {
      return 5;
    }
    
    final birthdate = formData['childBirthdate'] as DateTime;
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    
    if (now.month < birthdate.month || 
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    
    return age > 0 ? age : 0;
  }
  
  Future<bool> completeOnboarding(DatabaseService? databaseService) async {
    try {
      if (databaseService == null) {
        debugPrint('Error: DatabaseService is null in completeOnboarding');
        return false;
      }
      
      final Map<String, dynamic> additionalInfo = {
        'onboardingCompleted': true,
        'onboardingCompletedAt': DateTime.now().toIso8601String(),
      };
      
      if (user.role == UserRole.parent) {
        AuthService? authService;
        try {
          authService = databaseService.auth;
        } catch (e) {
          debugPrint('Error getting AuthService: $e');
        }
        
        if (authService != null) {
          final success = await authService.completeOnboarding();
          if (success) {
            return true;
          }
        }
        
        try {
          await databaseService.updateUser(
            user.id,
            {'additionalInfo.onboardingCompleted': true},
          );
          return true;
        } catch (e) {
          debugPrint('Error in alternate onboarding completion: $e');
          return false;
        }
      } else {
        AuthService? authService;
        try {
          authService = databaseService.auth;
        } catch (e) {
          debugPrint('Error getting AuthService: $e');
        }
        
        if (authService != null) {
          final success = await authService.completeOnboarding();
          if (success) {
            return true;
          }
        }
        
        try {
          await databaseService.updateUser(
            user.id,
            {'additionalInfo.onboardingCompleted': true},
          );
          return true;
        } catch (e) {
          debugPrint('Error in alternate therapist onboarding completion: $e');
          return false;
        }
      }
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      return false;
    }
  }

  @override
  void dispose() {
    childNameController.dispose();
    childAgeController.dispose();
    additionalInfoController.dispose();
    specialtyController.dispose();
    experienceController.dispose();
    aboutController.dispose();
    professionalTitleController.dispose();
    degreeController.dispose();
    institutionController.dispose();
    graduationYearController.dispose();
    licenseNumberController.dispose();
    licenseAuthorityController.dispose();
    practiceNameController.dispose();
    websiteController.dispose();
    linkedinController.dispose();
    facebookController.dispose();
    youtubeController.dispose();
    instagramController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  OnboardingState({required this.user}) {
    _pageController = PageController(initialPage: 0);

    // Initialize controllers with form data
    childNameController.addListener(() {
      formData['childName'] = childNameController.text;
    });

    childAgeController.addListener(() {
      formData['childAge'] = int.tryParse(childAgeController.text) ?? 0;
    });

    additionalInfoController.addListener(() {
      formData['additionalInfo'] = additionalInfoController.text;
    });

    // Therapist controller listeners
    specialtyController.addListener(() {
      formData['specialty'] = specialtyController.text;
    });

    professionalTitleController.addListener(() {
      formData['professionalTitle'] = professionalTitleController.text;
    });

    experienceController.addListener(() {
      formData['experience'] = experienceController.text;
    });

    aboutController.addListener(() {
      formData['about'] = aboutController.text;
    });

    degreeController.addListener(() {
      formData['degree'] = degreeController.text;
    });

    institutionController.addListener(() {
      formData['institution'] = institutionController.text;
    });

    graduationYearController.addListener(() {
      formData['graduationYear'] = graduationYearController.text;
    });

    licenseNumberController.addListener(() {
      formData['licenseNumber'] = licenseNumberController.text;
    });

    licenseAuthorityController.addListener(() {
      formData['licenseAuthority'] = licenseAuthorityController.text;
    });

    practiceNameController.addListener(() {
      formData['practiceName'] = practiceNameController.text;
    });

    websiteController.addListener(() {
      formData['website'] = websiteController.text;
    });

    linkedinController.addListener(() {
      formData['socialMedia']['linkedin'] = linkedinController.text;
    });

    facebookController.addListener(() {
      formData['socialMedia']['facebook'] = facebookController.text;
    });

    youtubeController.addListener(() {
      formData['socialMedia']['youtube'] = youtubeController.text;
    });

    instagramController.addListener(() {
      formData['socialMedia']['instagram'] = instagramController.text;
    });
  }

  // Parent-specific methods
  void setChildInfo({
    required String name,
    required int age,
    required String gender,
  }) {
    formData['childName'] = name;
    formData['childAge'] = age;
    formData['childGender'] = gender;
    childNameController.text = name;
    childAgeController.text = age.toString();
    notifyListeners();
  }

  void setConcerns(List<String> concerns) {
    formData['selectedConcerns'] = concerns;
    // Also update parentConcerns map for backward compatibility
    final Map<String, bool> concernsMap = {};
    for (final concern in concerns) {
      concernsMap[concern] = true;
    }
    formData['parentConcerns'] = concernsMap;
    notifyListeners();
  }
}