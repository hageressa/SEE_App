import 'package:cloud_firestore/cloud_firestore.dart';

class Child {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String? avatar;
  final String parentId;
  final List<String> concerns;
  final Map<String, dynamic> additionalInfo;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final String? therapistId;
  final num? therapistFee;

  Child({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.parentId,
    this.avatar,
    required this.concerns,
    Map<String, dynamic>? additionalInfo,
    DateTime? createdAt,
    DateTime? lastUpdated,
    this.therapistId,
    this.therapistFee,
  }) : 
    this.additionalInfo = additionalInfo ?? {},
    this.createdAt = createdAt ?? DateTime.now(),
    this.lastUpdated = lastUpdated ?? DateTime.now();

  /// Create a Child object from Firestore document
  factory Child.fromJson(Map<String, dynamic> json) {
    return Child.fromMap(json['id'] as String, json);
  }
  
  /// Create a Child object from a Map (for both Firestore and SharedPreferences)
  factory Child.fromMap(String childId, Map<String, dynamic> map) {
    // Handle dates that might be stored as string, Timestamp, or DateTime
    DateTime? createdAt;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        createdAt = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        try {
          createdAt = DateTime.parse(map['createdAt'] as String);
        } catch (_) {
          createdAt = DateTime.now();
        }
      }
    }

    DateTime? lastUpdated;
    if (map['lastUpdated'] != null) {
      if (map['lastUpdated'] is Timestamp) {
        lastUpdated = (map['lastUpdated'] as Timestamp).toDate();
      } else if (map['lastUpdated'] is String) {
        try {
          lastUpdated = DateTime.parse(map['lastUpdated'] as String);
        } catch (_) {
          lastUpdated = DateTime.now();
        }
      }
    }
    
    return Child(
      id: childId,
      name: map['name'] as String? ?? 'Unknown Child',
      age: map['age'] as int? ?? 0,
      gender: map['gender'] as String? ?? 'Unknown',
      parentId: map['parentId'] as String? ?? '',
      avatar: map['avatar'] as String?,
      concerns: List<String>.from(map['concerns'] as List? ?? []),
      additionalInfo: Map<String, dynamic>.from(map['additionalInfo'] as Map? ?? {}),
      createdAt: createdAt,
      lastUpdated: lastUpdated,
      therapistId: map['therapistId'] as String?,
      therapistFee: map['therapistFee'] as num?,
    );
  }

  /// Create a Child from Firestore data
  static Child fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return Child(
        id: doc.id,
        name: 'Unknown Child',
        age: 0,
        gender: 'Unknown',
        parentId: '',
        avatar: null,
        concerns: [],
        additionalInfo: {},
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        therapistId: null,
        therapistFee: null,
      );
    }
    
    return Child(
      id: doc.id,
      name: data['name'] ?? 'Unknown Child',
      age: data['age'] ?? 0,
      gender: data['gender'] as String? ?? 'Unknown',
      parentId: data['parentId'] as String? ?? '',
      avatar: data['avatar'] as String?,
      concerns: List<String>.from(data['concerns'] as List? ?? []),
      additionalInfo: Map<String, dynamic>.from(data['additionalInfo'] as Map? ?? {}),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] is Timestamp 
              ? (data['createdAt'] as Timestamp).toDate() 
              : (data['createdAt'] is String 
                  ? DateTime.parse(data['createdAt'] as String) 
                  : DateTime.now()))
          : DateTime.now(),
      lastUpdated: data['lastUpdated'] != null 
          ? (data['lastUpdated'] is Timestamp 
              ? (data['lastUpdated'] as Timestamp).toDate() 
              : (data['lastUpdated'] is String 
                  ? DateTime.parse(data['lastUpdated'] as String) 
                  : DateTime.now()))
          : DateTime.now(),
      therapistId: data['therapistId'] as String?,
      therapistFee: data['therapistFee'] as num?,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return toMap();
  }
  
  /// Convert to Map for both Firestore and SharedPreferences
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'parentId': parentId,
      'avatar': avatar,
      'concerns': concerns,
      'additionalInfo': additionalInfo,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'therapistId': therapistId,
      'therapistFee': therapistFee,
    };
  }
  
  /// Create a copy of this Child with modified fields
  Child copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? parentId,
    String? avatar,
    List<String>? concerns,
    Map<String, dynamic>? additionalInfo,
    DateTime? createdAt,
    DateTime? lastUpdated,
    String? therapistId,
    num? therapistFee,
  }) {
    return Child(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      parentId: parentId ?? this.parentId,
      avatar: avatar ?? this.avatar,
      concerns: concerns ?? this.concerns,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      therapistId: therapistId ?? this.therapistId,
      therapistFee: therapistFee ?? this.therapistFee,
    );
  }
  
  @override
  String toString() {
    return 'Child(id: $id, name: $name, age: $age, gender: $gender, concerns: $concerns)';
  }
}