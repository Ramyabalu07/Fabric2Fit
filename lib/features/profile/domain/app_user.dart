class AppUser {
  const AppUser({required this.id, required this.displayName, this.email, this.isGuest = true});
  final String id;
  final String displayName;
  final String? email;
  final bool isGuest;
}

abstract interface class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> authStateChanges();
  Future<AppUser> continueAsGuest();
  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> signUpWithEmail(String name, String email, String password);
  Future<void> updateDisplayName(String name);
  Future<void> signOut();
}
