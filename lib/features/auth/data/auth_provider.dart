import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../../../core/constants/app_constants.dart';

// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Auth state changes stream
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Current user data provider
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .snapshots()
          .map((snap) {
        if (snap.exists) {
          return UserModel.fromMap(snap.data()!);
        }
        return null;
      });
    },
    loading: () => Stream.value(null),
    error: (_, _) => Stream.value(null),
  );
});

// Auth service
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = UserModel(
      uid: cred.user!.uid,
      username: username.toLowerCase(),
      displayName: displayName,
      email: email,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(cred.user!.uid)
        .set(user.toMap());

    return user;
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});
