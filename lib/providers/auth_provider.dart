import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _userModel;
  User? _firebaseUser;
  String? _error;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get userModel => _userModel;
  User? get firebaseUser => _firebaseUser;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String get userId => _firebaseUser?.uid ?? '';
  String get userName => _userModel?.name ?? _firebaseUser?.displayName ?? 'User';

  AppAuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        _status = AuthStatus.authenticated;
        await _loadUserData(user.uid);
      } else {
        _status = AuthStatus.unauthenticated;
        _userModel = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      _userModel = await _authService.getUserData(uid);
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String phone = '',
    String location = '',
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        phone: phone,
        location: location,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _authService.signInWithGoogle();
      return result != null;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      return false;
    } catch (e) {
      _setError('Google sign-in failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
    } catch (e) {
      _setError('Failed to sign out.');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? location,
    String? profileImage,
  }) async {
    if (_firebaseUser == null) return false;
    _setLoading(true);
    _clearError();
    try {
      await _authService.updateUserProfile(
        uid: _firebaseUser!.uid,
        name: name,
        phone: phone,
        location: location,
        profileImage: profileImage,
      );
      await _loadUserData(_firebaseUser!.uid);
      return true;
    } catch (e) {
      _setError('Failed to update profile.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void refreshUserData() {
    if (_firebaseUser != null) {
      _loadUserData(_firebaseUser!.uid);
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
