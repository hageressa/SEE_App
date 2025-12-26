import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/screens/onboarding/onboarding_screen.dart';
import 'package:see_app/screens/parent/parent_dashboard.dart';
import 'package:see_app/screens/signup_screen.dart';
import 'package:see_app/screens/therapist/redesigned_therapist_dashboard.dart';
import 'package:see_app/screens/diagnostic_screen.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/utils/theme.dart';
import 'package:see_app/widgets/see_logo.dart';
import 'package:see_app/state/onboarding_state.dart';
import 'package:see_app/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Animation controller
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    
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
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }
  
  void _resetError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }
  
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        
        // Attempt to sign in
        final user = await authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        
        // User authenticated successfully
        if (user != null && mounted) {
          // Show onboarding or dashboard based on user state
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
                builder: (context) => user.role == UserRole.parent
                    ? const ParentDashboard()
                    : const RedesignedTherapistDashboard(),
              ),
            );
          }
        } else {
          // Failed to authenticate
          setState(() {
            _errorMessage = 'Login failed. Please check your credentials.';
            _isLoading = false;
          });
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email format';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled';
            break;
          default:
            errorMessage = 'Error: ${e.message}';
            break;
        }
        
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
      } catch (e) {
          setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
          _isLoading = false;
          });
          debugPrint('Login error: $e');
        }
    }
  }
  
  Future<void> _createTestAccounts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Use the new createTestAccounts method from AuthService
      final success = await authService.createTestAccounts();
      
      if (success) {
        // The method automatically signs in as the parent
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Test accounts created and signed in successfully!'),
              backgroundColor: SeeAppTheme.calmColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error creating test accounts. Check logs for details.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      // Handle unexpected errors
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
        });
        debugPrint('Error creating test accounts: $e');
        
        // Show a more user-friendly error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create test accounts: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
  
  void _navigateToDiagnostics() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DiagnosticScreen(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeeAppTheme.lightBackground,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                    ),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Logo and title
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            Hero(
                              tag: 'app_logo',
                              child: SeeLogo(size: 100, showText: true),
                          ),
                            const SizedBox(height: 24),
                            Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: SeeAppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to continue',
                              style: TextStyle(
                                fontSize: 16,
                                color: SeeAppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),
                      
                                      // Error message if any
                                      if (_errorMessage != null)
                                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                                          decoration: BoxDecoration(
                            color: SeeAppTheme.alertHigh.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                              color: SeeAppTheme.alertHigh.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.error_outline_rounded,
                                color: SeeAppTheme.alertHigh,
                                size: 18,
                                              ),
                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _errorMessage!,
                                                  style: TextStyle(
                                    color: SeeAppTheme.alertHigh,
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
                                  color: SeeAppTheme.textSecondary,
                                            size: 20,
                                          ),
                                          onPressed: _togglePasswordVisibility,
                                          splashRadius: 20,
                                        ),
                                      ),
                                      
                                      // Forgot Password link
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            // Show dialog to enter email for password reset
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Reset Password'),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Text(
                                                      'Enter your email to receive a password reset link:',
                                                    ),
                                          const SizedBox(height: 16),
                                                    TextFormField(
                                                      initialValue: _emailController.text,
                                                      decoration: InputDecoration(
                                                        labelText: 'Email',
                                              prefixIcon: const Icon(Icons.email_outlined),
                                                        border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                        ),
                                                      ),
                                                      keyboardType: TextInputType.emailAddress,
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      final email = _emailController.text.trim();
                                                      if (email.isEmpty || !RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email)) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(
                                                            content: Text('Please enter a valid email address'),
                                                            backgroundColor: Colors.red,
                                                          ),
                                                        );
                                                        return;
                                                      }
                                                      
                                                      Navigator.pop(context);
                                                      
                                                      // Show loading indicator
                                                      setState(() {
                                                        _isLoading = true;
                                                      });
                                                      
                                                      try {
                                                        final authService = Provider.of<AuthService>(context, listen: false);
                                                        await authService.sendPasswordResetEmail(email);
                                                        
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('Password reset link sent to $email'),
                                                    backgroundColor: SeeAppTheme.calmColor,
                                                              duration: const Duration(seconds: 4),
                                                            ),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('Error sending reset link: ${e is FirebaseAuthException ? e.message : e.toString()}'),
                                                    backgroundColor: SeeAppTheme.alertHigh,
                                                              duration: const Duration(seconds: 4),
                                                            ),
                                                          );
                                                        }
                                                      } finally {
                                                        if (mounted) {
                                                          setState(() {
                                                            _isLoading = false;
                                                          });
                                                        }
                                                      }
                                                    },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: SeeAppTheme.primaryColor,
                                          ),
                                                    child: const Text('Send Reset Link'),
                                                  ),
                                                ],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                              ),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                            ),
                                          ),
                                          child: Text(
                                            'Forgot Password?',
                                            style: TextStyle(
                                    color: SeeAppTheme.primaryColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                            const SizedBox(height: 32),
                                      
                                      // Login Button
                                      SizedBox(
                                        width: double.infinity,
                              height: 56,
                                        child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                          style: ElevatedButton.styleFrom(
                                  backgroundColor: SeeAppTheme.primaryColor,
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor: Colors.grey.shade300,
                                  elevation: 0,
                                            shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: _isLoading
                                    ? const SizedBox(
                                                  height: 24,
                                                  width: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                    : const Text(
                                        'Log In',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      
                            const SizedBox(height: 24),
                                      
                            // Sign Up Link
                            Center(
                              child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Don\'t have an account? ',
                                            style: TextStyle(
                                      color: SeeAppTheme.textSecondary,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                      HapticFeedback.lightImpact();
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => SignupScreen(
                                            initialUserType: _emailController.text.contains('therapist') ? 'therapist' : 'parent',
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              'Sign Up',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                        color: SeeAppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                        
                            // Test Account Button (debug only)
                            if (!kReleaseMode)
                              Padding(
                                padding: const EdgeInsets.only(top: 32),
                                child: Center(
                                  child: OutlinedButton(
                            onPressed: _isLoading ? null : _createTestAccounts,
                            style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                              ),
                              side: BorderSide(
                                        color: SeeAppTheme.primaryColor.withOpacity(0.6),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Create Test Accounts'),
                              ),
                            ),
                          ),
                        
                            // Diagnostics Button (debug only)
                            if (kDebugMode)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Center(
                                  child: TextButton(
                            onPressed: _navigateToDiagnostics,
                            style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey.shade600,
                                    ),
                                    child: const Text('System Diagnostics'),
                                  ),
                            ),
                          ),
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (_) => _resetError(),
      style: TextStyle(
        fontSize: 16,
        color: SeeAppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: SeeAppTheme.primaryColor, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: SeeAppTheme.cardBackground,
        labelStyle: TextStyle(
          color: SeeAppTheme.textSecondary,
        ),
        floatingLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: SeeAppTheme.primaryColor,
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
            color: SeeAppTheme.primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: SeeAppTheme.alertHigh,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: SeeAppTheme.alertHigh,
            width: 1.5,
          ),
        ),
        errorStyle: TextStyle(
          fontSize: 12,
          color: SeeAppTheme.alertHigh,
        ),
      ),
    );
  }
}