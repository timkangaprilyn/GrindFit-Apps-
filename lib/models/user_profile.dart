import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a GrindFit user's fitness profile, stored in Firestore
/// at `users/{userId}`.
class UserProfile {
  final String userId;
  final String fullName;
  final String email;
  final String role; // 'member' or 'admin'
  final double? height; // cm
  final double? weight; // kg
  final String? fitnessLevel; // Beginner / Intermediate / Advanced
  final String? activityFrequency;
  final String? fitnessGoal;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    this.role = 'member',
    this.height,
    this.weight,
    this.fitnessLevel,
    this.activityFrequency,
    this.fitnessGoal,
    this.createdAt,
    this.updatedAt,
  });

  /// Required fields that must all be present for the profile to be
  /// considered "complete" (see Phase 2 spec, Section 14).
  bool get isComplete {
    return fullName.trim().isNotEmpty &&
        height != null &&
        weight != null &&
        fitnessLevel != null &&
        fitnessLevel!.isNotEmpty &&
        activityFrequency != null &&
        activityFrequency!.isNotEmpty &&
        fitnessGoal != null &&
        fitnessGoal!.isNotEmpty;
  }

  factory UserProfile.fromMap(String userId, Map<String, dynamic> map) {
    return UserProfile(
      userId: userId,
      fullName: (map['fullName'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      role: (map['role'] as String?) ?? 'member',
      height: (map['height'] as num?)?.toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
      fitnessLevel: map['fitnessLevel'] as String?,
      activityFrequency: map['activityFrequency'] as String?,
      fitnessGoal: map['fitnessGoal'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  /// Helper to parse both Firestore Timestamp and String dates safely
  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  factory UserProfile.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserProfile.fromMap(doc.id, doc.data() ?? {});
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'role': role,
      'height': height,
      'weight': weight,
      'fitnessLevel': fitnessLevel,
      'activityFrequency': activityFrequency,
      'fitnessGoal': fitnessGoal,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? role,
    double? height,
    double? weight,
    String? fitnessLevel,
    String? activityFrequency,
    String? fitnessGoal,
  }) {
    return UserProfile(
      userId: userId,
      fullName: fullName ?? this.fullName,
      email: email,
      role: role ?? this.role,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      activityFrequency: activityFrequency ?? this.activityFrequency,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}