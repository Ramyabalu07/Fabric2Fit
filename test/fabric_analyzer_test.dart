import 'package:fabric2fit/features/fabric/data/local_fabric_analyzer.dart';
import 'package:fabric2fit/features/fabric/data/sample_fabrics.dart';
import 'package:fabric2fit/features/fabric/domain/fabric_analysis.dart';
import 'package:fabric2fit/features/fabric/domain/fabric_attributes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FabricAnalysis analyse(String name) =>
      analyzeFabricBytes(sampleFabrics.firstWhere((s) => s.name == name).encode());

  test('every sample fabric produces a palette and occasions', () {
    for (final s in sampleFabrics) {
      final a = analyzeFabricBytes(s.encode());
      expect(a.palette, isNotEmpty, reason: s.name);
      expect(a.occasions, isNotEmpty, reason: s.name);
    }
  });

  test('detects key attributes of sample swatches', () {
    final results = {for (final s in sampleFabrics) s.name: analyse(s.name)};
    // ignore: avoid_print
    results.forEach((k, v) => print('$k → ${v.colorFamily.label}, ${v.pattern.label}, ${v.texture.label}, ${v.fabricType.label}'));
    expect(results['Emerald Silk']!.colorFamily, ColorFamily.green);
    expect(results['Lavender Stripes']!.pattern, FabricPattern.stripes);
    expect(results['Rose Gingham']!.pattern, FabricPattern.checks);
    expect(results['Midnight Polka']!.pattern, FabricPattern.polka);
    expect(results['Emerald Silk']!.pattern, FabricPattern.solid);
    expect(results['Marigold Floral']!.pattern, FabricPattern.floral);
    expect(results['Marigold Floral']!.colorFamily, ColorFamily.multicolor);
  });

  test('analysis JSON round-trips', () {
    final a = analyse('Marigold Floral');
    expect(FabricAnalysis.fromJson(a.toJson()).toJson(), a.toJson());
  });
}
