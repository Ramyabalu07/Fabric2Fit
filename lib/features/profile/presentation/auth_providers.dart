import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../data/firebase_auth_repository.dart';
import '../data/local_auth_repository.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useFirebase) return FirebaseAuthRepository(FirebaseAuth.instance);
  return LocalAuthRepository(ref.watch(sharedPreferencesProvider));
});

final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);
