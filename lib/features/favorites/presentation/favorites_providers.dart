import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../designs/domain/garment_design.dart';
import '../../fabric/domain/fabric_analysis.dart';
import '../../profile/presentation/auth_providers.dart';
import '../data/firebase_favorites_repository.dart';
import '../data/local_favorites_repository.dart';
import '../domain/saved_look.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final uid = ref.watch(authStateProvider.select((u) => u.value?.id));
  if (AppConfig.useFirebase && uid != null) {
    return FirebaseFavoritesRepository(FirebaseFirestore.instance, FirebaseStorage.instance, uid);
  }
  return LocalFavoritesRepository(ref.watch(sharedPreferencesProvider));
});

class FavoritesNotifier extends AsyncNotifier<List<SavedLook>> {
  @override
  Future<List<SavedLook>> build() => ref.watch(favoritesRepositoryProvider).fetchAll();

  Future<SavedLook> saveLook({
    required GarmentDesign design,
    required Uint8List fabricBytes,
    required FabricAnalysis analysis,
    required double scale,
    required double rotation,
  }) async {
    final look = SavedLook(
      id: const Uuid().v4(),
      designId: design.id,
      designName: design.name,
      fabricBytes: fabricBytes,
      analysis: analysis,
      patternScale: scale,
      patternRotation: rotation,
      createdAt: DateTime.now(),
    );
    final saved = await ref.read(favoritesRepositoryProvider).save(look);
    state = AsyncData([saved, ...?state.value]);
    return saved;
  }

  Future<void> remove(String id) async {
    await ref.read(favoritesRepositoryProvider).delete(id);
    state = AsyncData([...?state.value?.where((l) => l.id != id)]);
  }
}

final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, List<SavedLook>>(FavoritesNotifier.new);
