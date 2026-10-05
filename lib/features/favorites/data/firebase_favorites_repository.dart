import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../domain/saved_look.dart';

/// Stores looks at `users/{uid}/looks/{id}` and fabric images at
/// `users/{uid}/fabrics/{id}.jpg`.
class FirebaseFavoritesRepository implements FavoritesRepository {
  FirebaseFavoritesRepository(this._db, this._storage, this._uid);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final String _uid;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users').doc(_uid).collection('looks');
  Reference _fabricRef(String id) => _storage.ref('users/$_uid/fabrics/$id.jpg');

  @override
  Future<List<SavedLook>> fetchAll() async {
    final snap = await _col.orderBy('createdAt', descending: true).get();
    return Future.wait(snap.docs.map((d) async {
      final data = d.data();
      final url = data['fabricUrl'] as String?;
      final bytes = url == null ? Uint8List(0) : (await http.get(Uri.parse(url))).bodyBytes;
      return SavedLook.fromJson(data, bytes: bytes);
    }));
  }

  @override
  Future<SavedLook> save(SavedLook look) async {
    final ref = _fabricRef(look.id);
    await ref.putData(look.fabricBytes, SettableMetadata(contentType: 'image/jpeg'));
    final saved = look.copyWith(fabricUrl: await ref.getDownloadURL());
    await _col.doc(look.id).set(saved.toJson(includeBytes: false));
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
    await _fabricRef(id).delete().catchError((_) {});
  }
}
