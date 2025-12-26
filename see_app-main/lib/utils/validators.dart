import 'package:flutter/material.dart';

/// Form validation utilities used throughout the app.
/// Provides standardized validation for common fields.
class FormValidators {
  /// Validates that a field is not empty
  static String? requiredField(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }
  
  /// Validates an email address format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  /// Validates a password meets minimum requirements
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
  
  /// Validates that two passwords match
  static String? validatePasswordMatch(String? value, String? confirmValue) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != confirmValue) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  /// Validates an age value
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid number';
    }
    
    if (age <= 0 || age > 100) {
      return 'Please enter a valid age between 1 and 100';
    }
    
    return null;
  }
  
  /// Validates a phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    
    final phoneRegex = RegExp(r'^\d{10,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'\D'), ''))) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }
  
  /// Validates years of experience
  static String? validateExperience(String? value) {
    if (value == null || value.isEmpty) {
      return 'Experience is required';
    }
    
    final years = int.tryParse(value);
    if (years == null) {
      return 'Please enter a valid number';
    }
    
    if (years < 0 || years > 99) {
      return 'Please enter a valid number of years';
    }
    
    return null;
  }
  
  /// Validates a required selection (e.g., dropdown)
  static String? validateSelection(dynamic value) {
    if (value == null) {
      return 'Please make a selection';
    }
    
    return null;
  }
  
  /// Validates a text field has a minimum length
  static String? validateMinLength(String? value, int minLength) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    
    if (value.length < minLength) {
      return 'Please enter at least $minLength characters';
    }
    
    return null;
  }
}