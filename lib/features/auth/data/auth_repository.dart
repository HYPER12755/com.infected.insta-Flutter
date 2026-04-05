import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    final credentials = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _firestore.collection('users').doc(credentials.user!.uid).set({
      'username': username,
      'email': email,
      'fullName': fullName,
      'followers': <String>[],
      'following': <String>[],
      'posts': 0,
      'bio': '',
      'website': '',
      'profilePic': '',
    });
    return credentials;
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signInWithGoogle() async {
    // Use the new authenticate() method
    try {
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

      // Get idToken from authentication
      final GoogleSignInAuthentication auth = googleUser.authentication;
      final String? idToken = auth.idToken;

      // Get access token via authorizationClient
      final scopes = <String>['email', 'profile'];
      final GoogleSignInClientAuthorization? clientAuth = 
          await googleUser.authorizationClient.authorizationForScopes(scopes);
      final String? accessToken = clientAuth?.accessToken;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      await _auth.signInWithCredential(credential);
    } catch (e) {
      // The user canceled the sign-in or an error occurred
      return;
    }
  }

  Future<void> signInWithGitHub() async {
    final GithubAuthProvider githubProvider = GithubAuthProvider();
    await _auth.signInWithProvider(githubProvider);
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
