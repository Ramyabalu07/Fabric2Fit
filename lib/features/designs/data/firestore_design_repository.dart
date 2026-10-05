import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/garment_design.dart';
import 'seed_designs.dart';

/// Reads the catalogue from the `designs` collection. Seeds it from
/// [buildSeedDesigns] the first time if it is empty.
class FirestoreDesignRepository implements DesignRepository {
  FirestoreDesignRepository(this._db);

  final FirebaseFirestore _db;
  List<GarmentDesign>? _cache;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('designs');

  @override
  Future<List<GarmentDesign>> fetchAll() async {
    if (_cache != null) return _cache!;
    var snap = await _col.get();
    if (snap.docs.isEmpty) {
      await seed();
      snap = await _col.get();
    }
    return _cache = snap.docs.map((d) => GarmentDesign.fromJson({...d.data(), 'id': d.id})).toList();
  }

  @override
  Future<GarmentDesign?> byId(String id) async {
    final all = await fetchAll();
    for (final d in all) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<void> seed() async {
    final batch = _db.batch();
    for (final d in buildSeedDesigns()) {
      batch.set(_col.doc(d.id), d.toJson());
    }
    await batch.commit();
  }
}
