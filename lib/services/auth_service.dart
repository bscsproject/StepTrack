import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:step_track/model/user_model.dart';

class AuthService {
  static const String _boxName = 'steptrack_auth_box';
  static const String _currentUserKey = 'current_user_json';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isGoogleInitialized = false;

  User? get currentUser => _auth.currentUser;

  Box<dynamic> get _box {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    throw StateError(
      'Hive box "$_boxName" open nahi hai. main.dart mein await Hive.openBox("$_boxName") call karein.',
    );
  }

  Future<void> _ensureGoogleInitialized() async {
    if (!_isGoogleInitialized) {
      await _googleSignIn.initialize();
      _isGoogleInitialized = true;
    }
  }

  // -------------------- Local Storage Helpers --------------------

  Future<void> saveUserToLocalStorage(UserModel user) async {
    await _box.put(_currentUserKey, jsonEncode(user.toMap()));
    await _box.put('user_${user.uid}', jsonEncode(user.toMap()));
  }

  UserModel? getCachedUser() {
    final raw = _box.get(_currentUserKey);
    if (raw == null || raw is! String || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromMap(decoded);
    } catch (_) {
      return null;
    }
  }

  UserModel? getCachedUserByUid(String uid) {
    final raw = _box.get('user_$uid');
    if (raw == null || raw is! String || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromMap(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCurrentUserCache() async {
    await _box.delete(_currentUserKey);
  }

  // -------------------- Setup Metrics Helpers --------------------

  Future<void> saveUserSetupMetrics({
    required String gender,
    required int yearOfBirth,
    required double weightKg,
    required double heightCm,
  }) async {
    final currentAuthUser = _auth.currentUser;
    final existing = (currentAuthUser != null
            ? getCachedUserByUid(currentAuthUser.uid)
            : null) ??
        getCachedUser();

    final uid = currentAuthUser?.uid ?? existing?.uid ?? 'guest_user';
    final existingMap = existing?.toMap() ?? <String, dynamic>{};

    final updatedMap = <String, dynamic>{
      ...existingMap,
      'uid': uid,
      'name': existing?.name ?? currentAuthUser?.displayName ?? 'StepTrack User',
      'email': existing?.email ?? currentAuthUser?.email ?? '',
      'createdAt': existing?.createdAt.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'gender': gender,
      'yearOfBirth': yearOfBirth,
      'weightKg': weightKg,
      'heightCm': heightCm,
    };

    await _box.put(_currentUserKey, jsonEncode(updatedMap));
    await _box.put('user_$uid', jsonEncode(updatedMap));

    if (currentAuthUser != null) {
      await _firestore.collection('users').doc(currentAuthUser.uid).set({
        'gender': gender,
        'yearOfBirth': yearOfBirth,
        'weightKg': weightKg,
        'heightCm': heightCm,
      }, SetOptions(merge: true));
    }
  }

  Map<String, dynamic>? getCachedSetupMetrics() {
    final currentUid = _auth.currentUser?.uid;
    final raw = (currentUid != null ? _box.get('user_$currentUid') : null) ??
        _box.get(_currentUserKey);
    if (raw == null || raw is! String || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // -------------------- Main Goal Helpers --------------------

  Future<void> saveUserMainGoal(String mainGoal) async {
    final currentAuthUser = _auth.currentUser;
    final existing = (currentAuthUser != null
            ? getCachedUserByUid(currentAuthUser.uid)
            : null) ??
        getCachedUser();

    final uid = currentAuthUser?.uid ?? existing?.uid ?? 'guest_user';
    final existingMap = existing?.toMap() ?? <String, dynamic>{};

    final updatedMap = <String, dynamic>{
      ...existingMap,
      'uid': uid,
      'name': existing?.name ?? currentAuthUser?.displayName ?? 'StepTrack User',
      'email': existing?.email ?? currentAuthUser?.email ?? '',
      'createdAt': existing?.createdAt.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'mainGoal': mainGoal,
    };

    await _box.put(_currentUserKey, jsonEncode(updatedMap));
    await _box.put('user_$uid', jsonEncode(updatedMap));

    if (currentAuthUser != null) {
      await _firestore.collection('users').doc(currentAuthUser.uid).set({
        'mainGoal': mainGoal,
      }, SetOptions(merge: true));
    }
  }

  String? getCachedMainGoal() {
    final currentUid = _auth.currentUser?.uid;
    final raw = (currentUid != null ? _box.get('user_$currentUid') : null) ??
        _box.get(_currentUserKey);
    if (raw == null || raw is! String || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final goal = decoded['mainGoal'];
      return goal is String && goal.isNotEmpty ? goal : null;
    } catch (_) {
      return null;
    }
  }

  // -------------------- Goal Reminder Permission Helpers --------------------

  Future<void> saveGoalReminderPermission({
    required bool reminderEnabled,
    required String permissionStatus,
  }) async {
    final currentAuthUser = _auth.currentUser;
    final existing = (currentAuthUser != null
            ? getCachedUserByUid(currentAuthUser.uid)
            : null) ??
        getCachedUser();

    final uid = currentAuthUser?.uid ?? existing?.uid ?? 'guest_user';
    final existingMap = existing?.toMap() ?? <String, dynamic>{};

    final updatedMap = <String, dynamic>{
      ...existingMap,
      'uid': uid,
      'name': existing?.name ?? currentAuthUser?.displayName ?? 'StepTrack User',
      'email': existing?.email ?? currentAuthUser?.email ?? '',
      'createdAt': existing?.createdAt.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'goalReminderEnabled': reminderEnabled,
      'notificationPermissionStatus': permissionStatus,
    };

    await _box.put(_currentUserKey, jsonEncode(updatedMap));
    await _box.put('user_$uid', jsonEncode(updatedMap));

    if (currentAuthUser != null) {
      await _firestore.collection('users').doc(currentAuthUser.uid).set({
        'goalReminderEnabled': reminderEnabled,
        'notificationPermissionStatus': permissionStatus,
      }, SetOptions(merge: true));
    }
  }

  // -------------------- Invited Friends Helpers --------------------

  Future<void> saveInvitedFriends(List<String> invitedFriends) async {
    final currentAuthUser = _auth.currentUser;
    final existing = (currentAuthUser != null
            ? getCachedUserByUid(currentAuthUser.uid)
            : null) ??
        getCachedUser();

    final uid = currentAuthUser?.uid ?? existing?.uid ?? 'guest_user';
    final existingMap = existing?.toMap() ?? <String, dynamic>{};

    final updatedMap = <String, dynamic>{
      ...existingMap,
      'uid': uid,
      'name': existing?.name ?? currentAuthUser?.displayName ?? 'StepTrack User',
      'email': existing?.email ?? currentAuthUser?.email ?? '',
      'createdAt': existing?.createdAt.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'invitedFriends': invitedFriends,
    };

    await _box.put(_currentUserKey, jsonEncode(updatedMap));
    await _box.put('user_$uid', jsonEncode(updatedMap));

    if (currentAuthUser != null) {
      await _firestore.collection('users').doc(currentAuthUser.uid).set({
        'invitedFriends': invitedFriends,
      }, SetOptions(merge: true));
    }
  }

  List<String> getCachedInvitedFriends() {
    final currentUid = _auth.currentUser?.uid;
    final raw = (currentUid != null ? _box.get('user_$currentUid') : null) ??
        _box.get(_currentUserKey);
    if (raw == null || raw is! String || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final list = decoded['invitedFriends'];
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // -------------------- Battery Optimisation Helpers --------------------

  Future<void> saveBatteryOptimisationStatus({
    required bool isIgnoringBatteryOptimisations,
    required String permissionStatus,
  }) async {
    final currentAuthUser = _auth.currentUser;
    final existing = (currentAuthUser != null
            ? getCachedUserByUid(currentAuthUser.uid)
            : null) ??
        getCachedUser();

    final uid = currentAuthUser?.uid ?? existing?.uid ?? 'guest_user';
    final existingMap = existing?.toMap() ?? <String, dynamic>{};

    final updatedMap = <String, dynamic>{
      ...existingMap,
      'uid': uid,
      'name': existing?.name ?? currentAuthUser?.displayName ?? 'StepTrack User',
      'email': existing?.email ?? currentAuthUser?.email ?? '',
      'createdAt': existing?.createdAt.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'batteryOptimisationDisabled': isIgnoringBatteryOptimisations,
      'batteryPermissionStatus': permissionStatus,
    };

    await _box.put(_currentUserKey, jsonEncode(updatedMap));
    await _box.put('user_$uid', jsonEncode(updatedMap));

    if (currentAuthUser != null) {
      await _firestore.collection('users').doc(currentAuthUser.uid).set({
        'batteryOptimisationDisabled': isIgnoringBatteryOptimisations,
        'batteryPermissionStatus': permissionStatus,
      }, SetOptions(merge: true));
    }
  }

  // -------------------- Autostart Helpers --------------------

  Future<void> saveAutostartStatus({
    required bool autostartSettingsOpened,
    required String actionSource,
  }) async {
    final currentAuthUser = _auth.currentUser;
    final existing = (currentAuthUser != null
            ? getCachedUserByUid(currentAuthUser.uid)
            : null) ??
        getCachedUser();

    final uid = currentAuthUser?.uid ?? existing?.uid ?? 'guest_user';
    final existingMap = existing?.toMap() ?? <String, dynamic>{};

    final updatedMap = <String, dynamic>{
      ...existingMap,
      'uid': uid,
      'name': existing?.name ?? currentAuthUser?.displayName ?? 'StepTrack User',
      'email': existing?.email ?? currentAuthUser?.email ?? '',
      'createdAt': existing?.createdAt.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'autostartSettingsOpened': autostartSettingsOpened,
      'autostartActionSource': actionSource,
    };

    await _box.put(_currentUserKey, jsonEncode(updatedMap));
    await _box.put('user_$uid', jsonEncode(updatedMap));

    if (currentAuthUser != null) {
      await _firestore.collection('users').doc(currentAuthUser.uid).set({
        'autostartSettingsOpened': autostartSettingsOpened,
        'autostartActionSource': actionSource,
      }, SetOptions(merge: true));
    }
  }

  // -------------------- Auth Methods --------------------

  // 1. Sign Up with Email & Password -> Firestore + Local Storage
  Future<UserModel?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final firebaseUser = cred.user;
    if (firebaseUser == null) return null;

    final cleanName = name.trim();
    final cleanEmail = email.trim();
    await firebaseUser.updateDisplayName(cleanName);

    final UserModel newUser = UserModel(
      uid: firebaseUser.uid,
      name: cleanName,
      email: cleanEmail,
      photoUrl: firebaseUser.photoURL,
      description: '',
      avatarColorValue: null,
      subscribeNewsletter: true,
      isOnboardingCompleted: false,
      createdAt: DateTime.now(),
    );

    await saveUserToLocalStorage(newUser);
    await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set(newUser.toMap());

    return newUser;
  }

  // 2. Login with Email & Password -> Fetch/Sync Firestore + Local Storage
  Future<UserModel?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final UserCredential cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final firebaseUser = cred.user;
    if (firebaseUser == null) return null;

    try {
      final docSnap =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (docSnap.exists && docSnap.data() != null) {
        final userModel = UserModel.fromMap(docSnap.data()!);
        await saveUserToLocalStorage(userModel);
        return userModel;
      }
    } catch (_) {
      final cached = getCachedUserByUid(firebaseUser.uid);
      if (cached != null) {
        await saveUserToLocalStorage(cached);
        return cached;
      }
    }

    final fallbackUser = UserModel(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'StepTrack User',
      email: firebaseUser.email ?? email.trim(),
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
    );
    await saveUserToLocalStorage(fallbackUser);
    return fallbackUser;
  }

  // 3. Continue with Google (google_sign_in ^7.2.0) -> Firestore + Local Storage
  Future<UserModel?> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final UserCredential cred = await _auth.signInWithCredential(credential);
    final firebaseUser = cred.user;
    if (firebaseUser == null) return null;

    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final docSnap = await docRef.get();

    UserModel resolvedUser;
    if (!docSnap.exists || docSnap.data() == null) {
      resolvedUser = UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'StepTrack User',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
        description: '',
        avatarColorValue: null,
        subscribeNewsletter: true,
        isOnboardingCompleted: false,
        createdAt: DateTime.now(),
      );
      await docRef.set(resolvedUser.toMap());
    } else {
      resolvedUser = UserModel.fromMap(docSnap.data()!);
    }

    await saveUserToLocalStorage(resolvedUser);
    return resolvedUser;
  }

  // 4. Create Profile Screen Data Save -> Local Storage + Firestore
  Future<UserModel> saveProfileDetails({
    required String name,
    required String description,
    required int avatarColorValue,
  }) async {
    final currentAuthUser = _auth.currentUser;
    final existing = (currentAuthUser != null
            ? getCachedUserByUid(currentAuthUser.uid)
            : null) ??
        getCachedUser() ??
        UserModel(
          uid: currentAuthUser?.uid ?? 'guest_user',
          name: name,
          email: currentAuthUser?.email ?? '',
          photoUrl: currentAuthUser?.photoURL,
          createdAt: DateTime.now(),
        );

    final updatedUser = existing.copyWith(
      uid: currentAuthUser?.uid ?? existing.uid,
      name: name,
      email: currentAuthUser?.email ?? existing.email,
      description: description,
      avatarColorValue: avatarColorValue,
    );

    await saveUserToLocalStorage(updatedUser);

    if (currentAuthUser != null) {
      try {
        await currentAuthUser.updateDisplayName(name);
      } catch (_) {}

      await _firestore.collection('users').doc(currentAuthUser.uid).set({
        'name': name,
        'description': description,
        'avatarColorValue': avatarColorValue,
      }, SetOptions(merge: true));
    }

    return updatedUser;
  }

  // 5. Welcome Screen Preferences Save -> Local Storage + Firestore
  Future<UserModel> saveWelcomePreferences({
    required bool subscribeNewsletter,
    required bool isOnboardingCompleted,
  }) async {
    final currentAuthUser = _auth.currentUser;
    final existing = (currentAuthUser != null
            ? getCachedUserByUid(currentAuthUser.uid)
            : null) ??
        getCachedUser() ??
        UserModel(
          uid: currentAuthUser?.uid ?? 'guest_user',
          name: currentAuthUser?.displayName ?? 'StepTrack User',
          email: currentAuthUser?.email ?? '',
          createdAt: DateTime.now(),
        );

    final updatedUser = existing.copyWith(
      subscribeNewsletter: subscribeNewsletter,
      isOnboardingCompleted: isOnboardingCompleted,
    );

    await saveUserToLocalStorage(updatedUser);

    if (currentAuthUser != null) {
      await _firestore.collection('users').doc(currentAuthUser.uid).set({
        'subscribeNewsletter': subscribeNewsletter,
        'isOnboardingCompleted': isOnboardingCompleted,
      }, SetOptions(merge: true));
    }

    return updatedUser;
  }

  // 6. Forgot Password
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // 7. Logout
  Future<void> signOut() async {
    if (_isGoogleInitialized) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
    await clearCurrentUserCache();
  }
}