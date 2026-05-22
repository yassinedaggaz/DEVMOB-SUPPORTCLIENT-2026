import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

const List<Map<String, String>> kAdminAccounts = [
  {
    'email': 'admin1@supportdesk.com',
    'password': 'Admin1234!',
    'name': 'Yassine Daggaz',
    'role': 'admin',
  },
  {
    'email': 'admin2@supportdesk.com',
    'password': 'Admin1234!',
    'name': 'flen ben foulen',
    'role': 'admin',
  },
];

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAdmin =>
      _currentUser?.role == 'support' || _currentUser?.role == 'admin';
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);

    ensureAdminAccountsExist();
  }

  Future<void> ensureAdminAccountsExist() async {
    for (final account in kAdminAccounts) {
      final email = account['email']!.trim();
      final password = account['password']!.trim();

      try {
        final adminCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final admin = UserModel(
          id: adminCredential.user!.uid,
          email: email,
          name: account['name']!.trim(),
          role: 'admin',
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(adminCredential.user!.uid)
            .set(admin.toJson());

        await _auth.signOut();

        debugPrint("Admin $email créé avec succès ✅");
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          debugPrint("Admin $email existe déjà ✔");
        } else {
          debugPrint('Erreur création admin $email: ${e.code}');
        }
      }
    }
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
    } else {
      await _loadUserData(firebaseUser.uid);
    }
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      _currentUser = UserModel.fromJson(doc.data() as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      return;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _loadUserData(credential.user!.uid);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInAsAdmin(String email, String password) async {
    final success = await signIn(email, password);
    if (success && !isAdmin) {
      await signOut();
      _errorMessage =
          'Accès refusé. Ce compte n\'a pas les droits admin/support.';
      notifyListeners();
      return false;
    }
    return success;
  }

  Future<bool> registerClient({
    required String email,
    required String password,
    required String name,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = UserModel(
        id: credential.user!.uid,
        email: email.trim(),
        name: name.trim(),
        role: 'client',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toJson());

      _currentUser = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé par un autre compte.';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères.';
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      default:
        return 'Erreur ($code) : Veuillez réessayer.';
    }
  }
}
