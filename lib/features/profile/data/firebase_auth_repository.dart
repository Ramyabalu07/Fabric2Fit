import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_user.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  AppUser? _map(User? u) => u == null
      ? null
      : AppUser(
          id: u.uid,
          displayName: u.displayName ?? (u.isAnonymous ? 'Guest' : (u.email?.split('@').first ?? 'You')),
          email: u.email,
          isGuest: u.isAnonymous,
        );

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() => _auth.userChanges().map(_map);

  @override
  Future<AppUser> continueAsGuest() async => _map((await _auth.signInAnonymously()).user)!;

  @override
  Future<AppUser> signInWithEmail(String email, String password) async =>
      _map((await _auth.signInWithEmailAndPassword(email: email, password: password)).user)!;

  @override
  Future<AppUser> signUpWithEmail(String name, String email, String password) async {
    final current = _auth.currentUser;
    final credential = EmailAuthProvider.credential(email: email, password: password);
    // Upgrade a guest account in place so saved looks are kept.
    final result = current != null && current.isAnonymous
        ? await current.linkWithCredential(credential)
        : await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await result.user!.updateDisplayName(name);
    await result.user!.reload();
    return _map(_auth.currentUser)!;
  }

  @override
  Future<void> updateDisplayName(String name) async => _auth.currentUser?.updateDisplayName(name);

  @override
  Future<void> signOut() => _auth.signOut();
}
