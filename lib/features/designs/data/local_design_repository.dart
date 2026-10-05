import '../domain/garment_design.dart';
import 'seed_designs.dart';

class LocalDesignRepository implements DesignRepository {
  LocalDesignRepository() : _designs = buildSeedDesigns();

  final List<GarmentDesign> _designs;

  @override
  Future<List<GarmentDesign>> fetchAll() async => _designs;

  @override
  Future<GarmentDesign?> byId(String id) async {
    for (final d in _designs) {
      if (d.id == id) return d;
    }
    return null;
  }
}
