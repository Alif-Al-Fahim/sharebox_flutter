import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
  required String email,
  required String password,
  required String name,
  String phone = '',
  String location = '',
}) async {
  try {
    final UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(name);

    await _createUserDocument(
      uid: credential.user!.uid,
      name: name,
      email: email,
      phone: phone,
      location: location,
    );

    return credential;

  } on FirebaseAuthException catch (e) {
    print("SIGNUP ERROR CODE: ${e.code}");
    print("SIGNUP ERROR MESSAGE: ${e.message}");
    rethrow;
  }
}

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    // Create or update user document in Firestore
    final userDoc = await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();

    if (!userDoc.exists) {
      await _createUserDocument(
        uid: userCredential.user!.uid,
        name: userCredential.user!.displayName ?? 'User',
        email: userCredential.user!.email ?? '',
        profileImage: userCredential.user!.photoURL,
      );
    }

    return userCredential;
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Reset password
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Create user document in Firestore
  Future<void> _createUserDocument({
    required String uid,
    required String name,
    required String email,
    String phone = '',
    String location = '',
    String? profileImage,
  }) async {
    final user = UserModel(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      location: location,
      profileImage: profileImage,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set(user.toMap());
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? location,
    String? profileImage,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (location != null) updates['location'] = location;
    if (profileImage != null) updates['profileImage'] = profileImage;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
      if (name != null) {
        await currentUser?.updateDisplayName(name);
      }
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  // Stream user data
  Stream<UserModel?> streamUserData(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Delete account
  Future<void> deleteAccount() async {
    final uid = currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).delete();
      await currentUser?.delete();
    }
  }
}
