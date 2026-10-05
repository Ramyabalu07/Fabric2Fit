import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/saved_look.dart';

class LocalFavoritesRepository implements FavoritesRepository {
  LocalFavoritesRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'saved_looks_v1';

  @override
  Future<List<SavedLook>> fetchAll() async {
    final raw = _prefs.getStringList(_key) ?? const [];
    final looks = <SavedLook>[];
    for (final r in raw) {
      try {
        looks.add(SavedLook.fromJson(jsonDecode(r) as Map<String, dynamic>));
      } catch (_) {
        // Skip corrupt entries rather than failing the whole list.
      }
    }
    return looks..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<SavedLook> save(SavedLook look) async {
    final all = await fetchAll();
    final next = [look, ...all.where((l) => l.id != look.id)];
    await _prefs.setStringList(_key, next.map((l) => jsonEncode(l.toJson())).toList());
    return look;
  }

  @override
  Future<void> delete(String id) async {
    final all = await fetchAll();
    await _prefs.setStringList(
      _key,
      all.where((l) => l.id != id).map((l) => jsonEncode(l.toJson())).toList(),
    );
  }
}
