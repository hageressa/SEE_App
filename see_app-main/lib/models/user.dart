import 'package:cloud_firestore/cloud_firestore.dart';

/// Available user roles in the application
enum UserRole {
  parent,
  therapist,
  admin,
}

/// User model representing an authenticated user in the system
class AppUser {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? profileImage;
  final List<String>? childrenIds; // For parents and therapists
  final bool isActive;
  final DateTime createdAt;
  final Map<String, dynamic>? additionalInfo;
  
  bool get isTherapist => role == UserRole.therapist;
  bool get isParent => role == UserRole.parent;
  
  // Additional properties for UI compatibility
  String get displayName => name;
  String? get photoUrl => profileImage;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.profileImage,
    this.childrenIds = const [],
    this.isActive = true,
    required this.createdAt,
    this.additionalInfo,
  });

  /// Create an AppUser from Firebase Auth and Firestore data
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Robust role parsing
    UserRole role;
    final roleString = data['role']?.toString().toLowerCase();
    
    if (roleString == 'therapist') {
      role = UserRole.therapist;
    } else if (roleString == 'parent') {
      role = UserRole.parent;
    } else if (roleString == 'admin') {
      role = UserRole.admin;
    } else {
      role = UserRole.parent; // Default to parent for safety
    }

    return AppUser(
      id: doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: role,
      profileImage: data['profileImage'],
      childrenIds: List<String>.from(data['childrenIds'] as List<dynamic>? ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      additionalInfo: data['additionalInfo'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert AppUser to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.toString().split('.').last, // 'parent' or 'therapist'
      'childrenIds': childrenIds,
      'createdAt': createdAt,
      'additionalInfo': additionalInfo,
    };
  }

  /// Get a human-readable role name
  String get roleName {
    switch (role) {
      case UserRole.parent:
        return 'Parent';
      case UserRole.therapist:
        return 'Therapist';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  /// Create a copy of this AppUser with modified properties
  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? profileImage,
    List<String>? childrenIds,
    bool? isActive,
    DateTime? createdAt,
    Map<String, dynamic>? additionalInfo,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      childrenIds: childrenIds ?? this.childrenIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  /// Create an empty AppUser instance
  factory AppUser.empty() {
    return AppUser(
      id: '',
      email: '',
      name: '',
      role: UserRole.parent,
      createdAt: DateTime.now(),
    );
  }
}