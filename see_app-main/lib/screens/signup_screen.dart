import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/user.dart' as app_user;
import 'package:see_app/screens/login_screen.dart';
import 'package:see_app/screens/onboarding/onboarding_screen.dart';
import 'package:see_app/screens/parent/parent_dashboard.dart';
import 'package:see_app/screens/therapist/redesigned_therapist_dashboard.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:see_app/widgets/see_logo.dart';
import 'package:see_app/state/onboarding_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:see_app/utils/validators.dart';

class SignupScreen extends StatefulWidget {
  final String initialUserType;
  
  const SignupScreen({
    super.key,
    this.initialUserType = 'parent',
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  late String _userType;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Animation controller
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _userType = widget.initialUserType;
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    // Start animation
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }
  
  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }
  
  void _resetError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }
  
  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final databaseService = Provider.of<DatabaseService>(context, listen: false);
        
        // Get user details
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        final name = _nameController.text.trim();
        
        // Convert string user type to enum
        final role = _userType == 'therapist' 
            ? app_user.UserRole.therapist 
            : app_user.UserRole.parent;
        
        debugPrint('Creating new ${role == app_user.UserRole.therapist ? "THERAPIST" : "PARENT"} account');
        
        // Register the user
        final user = await authService.registerWithEmailAndPassword(
          email: email,
          password: password,
          name: name,
          role: role,
        );
        
        if (user != null) {
          // After registration, create therapist profile if needed
          if (role == app_user.UserRole.therapist) {
            try {
              // The role is already set during registration in AuthService,
              // but we can ensure the profile is created.
              if (mounted) {
                await databaseService.createInitialTherapistProfile(
                  userId: user.id,
                  name: name,
                  email: email,
                );
              }
            } catch (e) {
              debugPrint('Error creating therapist profile: $e');
              // Decide if this should be a fatal error for the user
            }
          }
          
          // Show onboarding or dashboard based on user state
          if (mounted) {
            if (!authService.isOnboarded) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                    create: (_) => OnboardingState(user: user),
                    child: OnboardingScreen(user: user),
                  ),
                ),
              );
            } else {
              // Navigate to appropriate dashboard
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => user.role == app_user.UserRole.parent
                      ? const ParentDashboard()
                      : const RedesignedTherapistDashboard(),
                ),
              );
            }
          }
        } else {
          debugPrint('Account creation failed');
          if (mounted) {
            setState(() {
              _errorMessage = 'Account creation failed. Please try again.';
            });
          }
        }
      } on FirebaseAuthException catch (e) {
          String errorMessage;
          
          switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'An account already exists with this email';
            _showExistingAccountDialog();
            break;
            case 'invalid-email':
            errorMessage = 'Please enter a valid email address';
              break;
            case 'weak-password':
            errorMessage = 'Password should be at least 6 characters long';
              break;
            default:
            errorMessage = 'Error: ${e.message}';
              break;
          }
          
          if (mounted) {
            setState(() {
              _errorMessage = errorMessage;
            });
          }
        debugPrint('Firebase auth error: ${e.code} - ${e.message}');
      } catch (e) {
        debugPrint('Unexpected error during signup: $e');
        if (mounted) {
          setState(() {
            _errorMessage = 'Unexpected error occurred. Please try again.';
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  void _showExistingAccountDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Account Already Exists',
            style: TextStyle(
              color: theme_utils.SeeAppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'An account with this email already exists. Would you like to log in instead?'
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Stay Here'),
            ),
            ElevatedButton(
              onPressed: () {
                // Close dialog and navigate to login screen
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    }
  }
  
  String? _validateName(String? value) {
    _resetError();
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }
  
  String? _validateEmail(String? value) {
    _resetError();
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }
  
  String? _validatePassword(String? value) {
    _resetError();
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
  
  String? _validateConfirmPassword(String? value) {
    _resetError();
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    return Scaffold(
      backgroundColor: theme_utils.SeeAppTheme.lightBackground,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar with back button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8
                ),
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: theme_utils.SeeAppTheme.primaryColor,
                      tooltip: 'Back to Login',
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo and title
                      Center(
                          child: Column(
                            children: [
                            Hero(
                              tag: 'app_logo',
                              child: SeeLogo(size: 80, showText: true),
                            ),
                            const SizedBox(height: 16),
                              Text(
                              'Create your account',
                                style: TextStyle(
                                fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme_utils.SeeAppTheme.textPrimary,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'Welcome to SEE - Sign up to get started',
                              style: TextStyle(
                                fontSize: 16,
                                color: theme_utils.SeeAppTheme.textSecondary,
                              ),
                                    ),
                                  ],
                                ),
                              ),
                              
                      const SizedBox(height: 32),
                              
                      // Role selection buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _userType = 'parent';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: _userType == 'parent' ? Colors.white : theme_utils.SeeAppTheme.primaryColor, backgroundColor: _userType == 'parent' ? theme_utils.SeeAppTheme.primaryColor : Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: _userType == 'parent' ? theme_utils.SeeAppTheme.primaryColor : Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                  ),
                                  elevation: _userType == 'parent' ? 5 : 1,
                                ),
                                icon: Icon(
                                  Icons.family_restroom,
                                  color: _userType == 'parent' ? Colors.white : theme_utils.SeeAppTheme.primaryColor,
                                ),
                                label: Text(
                                  'I am a Parent',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _userType == 'parent' ? Colors.white : theme_utils.SeeAppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _userType = 'therapist';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: _userType == 'therapist' ? Colors.white : theme_utils.SeeAppTheme.primaryColor, backgroundColor: _userType == 'therapist' ? theme_utils.SeeAppTheme.primaryColor : Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: _userType == 'therapist' ? theme_utils.SeeAppTheme.primaryColor : Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                  ),
                                  elevation: _userType == 'therapist' ? 5 : 1,
                                ),
                                icon: Icon(
                                  Icons.medical_services,
                                  color: _userType == 'therapist' ? Colors.white : theme_utils.SeeAppTheme.primaryColor,
                                ),
                                label: Text(
                                  'I am a Therapist',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _userType == 'therapist' ? Colors.white : theme_utils.SeeAppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: theme_utils.SeeAppTheme.spacing24), // Add some spacing after the buttons
                              
                      // Error message if any
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: theme_utils.SeeAppTheme.alertHigh.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme_utils.SeeAppTheme.alertHigh.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: theme_utils.SeeAppTheme.alertHigh,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: theme_utils.SeeAppTheme.alertHigh,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                              
                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                    // Name Field
                                    _buildTextField(
                                      controller: _nameController,
                                      label: 'Full Name',
                              icon: Icons.person_outline_rounded,
                                      validator: _validateName,
                                      textCapitalization: TextCapitalization.words,
                                    ),
                                    
                            const SizedBox(height: 20),
                                    
                                    // Email Field
                                    _buildTextField(
                                      controller: _emailController,
                                      label: 'Email',
                              icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: _validateEmail,
                                    ),
                                    
                            const SizedBox(height: 20),
                                    
                                    // Password Field
                                    _buildTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                              icon: Icons.lock_outline_rounded,
                                      obscureText: !_isPasswordVisible,
                                      validator: _validatePassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                          color: theme_utils.SeeAppTheme.textSecondary,
                                          size: 20,
                                        ),
                                        onPressed: _togglePasswordVisibility,
                                        splashRadius: 20,
                                      ),
                                    ),
                                    
                            const SizedBox(height: 20),
                                    
                                    // Confirm Password Field
                                    _buildTextField(
                                      controller: _confirmPasswordController,
                                      label: 'Confirm Password',
                              icon: Icons.lock_outlined,
                                      obscureText: !_isConfirmPasswordVisible,
                                      validator: _validateConfirmPassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isConfirmPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                          color: theme_utils.SeeAppTheme.textSecondary,
                                          size: 20,
                                        ),
                                        onPressed: _toggleConfirmPasswordVisibility,
                                        splashRadius: 20,
                                      ),
                                    ),
                                    
                            const SizedBox(height: 32),
                                    
                                    // Signup Button
                                    SizedBox(
                                      width: double.infinity,
                              height: 56,
                                      child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSignup,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: Colors.grey.shade300,
                                  elevation: 0,
                                          shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? SizedBox(
                                                height: 24,
                                                width: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                    : const Text(
                                                    'Create Account',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                              ),
                                      ),
                                    ),
                                    
                            const SizedBox(height: 24),
                                    
                                    // Login Link
                            Center(
                              child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Already have an account? ',
                                          style: TextStyle(
                                            color: theme_utils.SeeAppTheme.textSecondary,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(
                                            'Log In',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: theme_utils.SeeAppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ),
                            
                            const SizedBox(height: 32),
                            ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: (_) => _resetError(),
      style: TextStyle(
        fontSize: 16,
        color: theme_utils.SeeAppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme_utils.SeeAppTheme.primaryColor, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme_utils.SeeAppTheme.cardBackground,
        labelStyle: TextStyle(
          color: theme_utils.SeeAppTheme.textSecondary,
        ),
        floatingLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme_utils.SeeAppTheme.primaryColor,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme_utils.SeeAppTheme.primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme_utils.SeeAppTheme.alertHigh,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme_utils.SeeAppTheme.alertHigh,
            width: 1.5,
          ),
        ),
        errorStyle: TextStyle(
          fontSize: 12,
          color: theme_utils.SeeAppTheme.alertHigh,
        ),
      ),
    );
  }
}