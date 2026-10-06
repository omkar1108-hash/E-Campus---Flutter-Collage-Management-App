import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

enum SessionStatus { loading, signedOut, needsProfile, ready, error }

/// Tracks who is signed in and their Firestore profile (which holds the role).
class SessionProvider extends ChangeNotifier {
  SessionProvider(this._auth, this._store) {
    _authSub = _auth.authState.listen(_onAuth, onError: _onError);
  }

  final AuthService _auth;
  final FirestoreService _store;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  SessionStatus status = SessionStatus.loading;
  AppUser? user;
  String? errorMessage;

  void _onAuth(User? firebaseUser) {
    _profileSub?.cancel();
    user = null;
    errorMessage = null;
    if (firebaseUser == null) {
      status = SessionStatus.signedOut;
      notifyListeners();
      return;
    }
    status = SessionStatus.loading;
    notifyListeners();
    _profileSub = _store.watchUser(firebaseUser.uid).listen((profile) {
      user = profile;
      status = profile == null ? SessionStatus.needsProfile : SessionStatus.ready;
      notifyListeners();
    }, onError: _onError);
  }

  void _onError(Object e) {
    status = SessionStatus.error;
    errorMessage = e.toString();
    notifyListeners();
  }

  String? get uid => _auth.currentUser?.uid;

  Future<void> createProfile(
          {required String name, required String department, required int year}) =>
      _store.createProfile(
        uid: uid!,
        name: name,
        department: department,
        year: year,
      );

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
