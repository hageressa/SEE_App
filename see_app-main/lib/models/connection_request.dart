import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionRequest {
  final String id;
  final String parentId;
  final String therapistId;
  final String childId;
  final String parentName;
  final String childName;
  final String status;
  final String? message;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final DateTime? updatedAt;

  ConnectionRequest({
    required this.id,
    required this.parentId,
    required this.therapistId,
    required this.childId,
    required this.parentName,
    required this.childName,
    required this.status,
    this.message,
    required this.createdAt,
    this.acceptedAt,
    this.declinedAt,
    this.updatedAt,
  });

  factory ConnectionRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConnectionRequest(
      id: doc.id,
      parentId: data['parentId'] ?? '',
      therapistId: data['therapistId'] ?? '',
      childId: data['childId'] ?? '',
      parentName: data['parentName'] ?? 'Unknown Parent',
      childName: data['childName'] ?? 'Unknown Child',
      status: data['status'] ?? '',
      message: data['message'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      declinedAt: (data['declinedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'parentId': parentId,
      'therapistId': therapistId,
      'childId': childId,
      'parentName': parentName,
      'childName': childName,
      'status': status,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'declinedAt': declinedAt != null ? Timestamp.fromDate(declinedAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
} 