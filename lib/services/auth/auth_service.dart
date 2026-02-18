import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  // instance of auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // get curret user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // sign in
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // tring to signining first
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // save user info in a separate doc
      _firestore
      .collection("Users")
      .doc(userCredential.user!.uid)
      .set({
        "uid": userCredential.user!.uid,
        "email": email,
        "username": userCredential.user!.displayName,
      }, SetOptions(merge: true));

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  //sign up / creating user
  Future<UserCredential> signUpWithUserNameEmailPassword(
    String username,
    String email,
    String password,
  ) async {
    try {
      // creating user account first
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      // then after user creation, update the user's profile with the username (display name)
      await userCredential.user?.updateDisplayName(username);

      // save user info in a separate doc
      _firestore.collection("Users").doc(userCredential.user!.uid).set({
        "uid": userCredential.user!.uid,
        "email": email,
        "username": username,
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // sign out
  Future<void> signOut() async {
    final currentUser = _auth.currentUser;
    final token = await FirebaseMessaging.instance.getToken();

    if (currentUser != null && token != null && token.isNotEmpty) {
      await _firestore.collection("Users").doc(currentUser.uid).set({
        "fcmTokens": FieldValue.arrayRemove([token]),
        "fcmUpdatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return await _auth.signOut();
  }

  // reset password email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // errors
}
