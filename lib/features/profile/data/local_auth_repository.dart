import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/app_user.dart';

/// Device-only account used until Firebase is configured.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._prefs) {
    final id = _prefs.getString(_idKey);
    if (id != null) {
      _user = AppUser(
        id: id,
        displayName: _prefs.getString(_nameKey) ?? 'Guest',
        email: _prefs.getString(_emailKey),
        isGuest: _prefs.getString(_emailKey) == null,
      );
    }
  }

  final SharedPreferences _prefs;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  static const _idKey = 'user_id';
  static const _nameKey = 'user_name';
  static const _emailKey = 'user_email';

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  Future<AppUser> _set(String name, String? email) async {
    final id = _user?.id ?? const Uuid().v4();
    await _prefs.setString(_idKey, id);
    await _prefs.setString(_nameKey, name);
    if (email != null) await _prefs.setString(_emailKey, email);
    _user = AppUser(id: id, displayName: name, email: email ?? _user?.email, isGuest: (email ?? _user?.email) == null);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<AppUser> continueAsGuest() => _set(_user?.displayName ?? 'Guest', null);

  @override
  Future<AppUser> signInWithEmail(String email, String password) => _set(email.split('@').first, email);

  @override
  Future<AppUser> signUpWithEmail(String name, String email, String password) => _set(name, email);

  @override
  Future<void> updateDisplayName(String name) async => _set(name, null);

  @override
  Future<void> signOut() async {
    await _prefs.remove(_idKey);
    await _prefs.remove(_nameKey);
    await _prefs.remove(_emailKey);
    _user = null;
    _controller.add(null);
  }
}
