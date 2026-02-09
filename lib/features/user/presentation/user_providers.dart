import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/user_model.dart';

// Provider to get MY profile
final currentUserProfileProvider = FutureProvider.autoDispose<AppUser?>((ref) async {
  final authUser = ref.watch(authRepositoryProvider).currentUser;
  if (authUser == null) return null;

  final doc = await FirebaseFirestore.instance.collection('users').doc(authUser.uid).get();
  if (doc.exists) {
    return AppUser.fromMap(doc.data()!, authUser.uid);
  }
  return null;
});

// Provider to get ANY profile by ID
final userProfileProvider = FutureProvider.family.autoDispose<AppUser?, String>((ref, userId) async {
  if (userId.isEmpty) return null;
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  if (doc.exists) {
    return AppUser.fromMap(doc.data()!, userId);
  }
  return null;
});
