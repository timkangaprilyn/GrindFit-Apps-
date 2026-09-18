import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  Future<void> createUserProfile({
    required String userId,
    required String fullName,
    required String email,
  }) async {
    try {
      await _usersRef.doc(userId).set({
        'userId': userId,
        'fullName': fullName.trim(),
        'email': email.trim(),
        'height': null,
        'weight': null,
        'fitnessLevel': null,
        'activityFrequency': null,
        'fitnessGoal': null,
        'environment': 'indoor',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw _mapFirestoreError(e);
    }
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (!doc.exists) return null;
      return UserProfile.fromSnapshot(doc);
    } catch (e) {
      throw _mapFirestoreError(e);
    }
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return getUserProfile(uid);
  }

  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _usersRef.doc(userId).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw _mapFirestoreError(e);
    }
  }

  Future<void> updateFitnessGoal({
    required String userId,
    required String fitnessGoal,
  }) {
    return updateUserProfile(userId: userId, data: {'fitnessGoal': fitnessGoal});
  }

  Future<bool> isProfileComplete(String userId) async {
    final profile = await getUserProfile(userId);
    if (profile == null) return false;
    return profile.isComplete;
  }

  Future<void> saveUserWorkoutPlan(String userId, Map<String, dynamic> planData) async {
    try {
      final environment = planData['environment'] ?? 'indoor';
      await _usersRef.doc(userId).collection('workout_plan').doc(environment).set({
        ...planData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await _usersRef.doc(userId).collection('workout_plan').doc('current').set({
        ...planData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw _mapFirestoreError(e);
    }
  }

  Future<Map<String, dynamic>?> getUserWorkoutPlan(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).collection('workout_plan').doc('current').get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw _mapFirestoreError(e);
    }
  }

  Future<Map<String, dynamic>?> getEnvironmentWorkoutPlan(String userId) async {
    try {
      final userDoc = await _usersRef.doc(userId).get();
      final environment = userDoc.data()?['environment'] ?? 'indoor';

      final doc = await _usersRef.doc(userId).collection('workout_plan').doc(environment).get();
      if (doc.exists) {
        return doc.data();
      }
      return getUserWorkoutPlan(userId);
    } catch (e) {
      throw _mapFirestoreError(e);
    }
  }

  Future<void> logCompletedWorkout(String userId, Map<String, dynamic> workoutLog) async {
    try {
      await _usersRef.doc(userId).collection('workout_history').add({
        ...workoutLog,
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw _mapFirestoreError(e);
    }
  }

  String _mapFirestoreError(Object e) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return 'You don\'t have permission to do that. Please log in again.';
        case 'unavailable':
          return 'Unable to reach the server. Please check your internet connection and try again.';
        case 'not-found':
          return 'We couldn\'t find your profile. Please try again.';
        case 'deadline-exceeded':
          return 'The request timed out. Please try again.';
        case 'cancelled':
          return 'The request was cancelled. Please try again.';
        default:
          return 'Unable to save your profile. Please check your internet connection and try again.';
      }
    }
    return 'Unable to save your profile. Please check your internet connection and try again.';
  }
}