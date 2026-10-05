import 'package:fabric2fit/features/designs/data/seed_designs.dart';
import 'package:fabric2fit/features/designs/domain/garment_design.dart';
import 'package:fabric2fit/features/designs/domain/recommendation_engine.dart';
import 'package:fabric2fit/features/fabric/domain/fabric_analysis.dart';
import 'package:fabric2fit/features/fabric/domain/fabric_attributes.dart';
import 'package:flutter_test/flutter_test.dart';

FabricAnalysis _fabric({
  FabricType type = FabricType.cotton,
  FabricPattern pattern = FabricPattern.floral,
  Set<Occasion> occasions = const {Occasion.casual},
}) =>
    FabricAnalysis(
      palette: const [0xFFD98FA3],
      colorFamily: ColorFamily.pink,
      pattern: pattern,
      texture: FabricTexture.smooth,
      fabricType: type,
      occasions: occasions,
      styles: const {StyleTag.modern},
    );

void main() {
  final designs = buildSeedDesigns();
  const engine = RecommendationEngine();

  test('seed catalogue has 50–100 unique designs covering every silhouette', () {
    expect(designs.length, inInclusiveRange(50, 100));
    expect(designs.map((d) => d.id).toSet().length, designs.length);
    expect(designs.map((d) => d.silhouette).toSet().length, 8);
  });

  test('recommendations are sorted by score and include reasons', () {
    final matches = engine.recommend(_fabric(), designs);
    expect(matches, isNotEmpty);
    for (var i = 1; i < matches.length; i++) {
      expect(matches[i - 1].score, greaterThanOrEqualTo(matches[i].score));
    }
    expect(matches.first.reasons, isNotEmpty);
    expect(matches.every((m) => m.score >= engine.minScore && m.score <= 100), isTrue);
  });

  test('occasion and category filters are respected', () {
    final matches = engine.recommend(
      _fabric(type: FabricType.silk, occasions: {Occasion.wedding}),
      designs,
      occasion: Occasion.wedding,
      category: GarmentCategory.ethnic,
    );
    expect(matches, isNotEmpty);
    expect(matches.every((m) => m.design.occasions.contains(Occasion.wedding)), isTrue);
    expect(matches.every((m) => m.design.category == GarmentCategory.ethnic), isTrue);
  });

  test('silk wedding fabric ranks festive ethnic wear above casual shirts', () {
    final f = _fabric(type: FabricType.silk, pattern: FabricPattern.ethnic, occasions: {Occasion.wedding});
    final top = engine.recommend(f, designs).take(5).map((m) => m.design.category);
    expect(top, contains(GarmentCategory.ethnic));
  });

  test('design JSON round-trips', () {
    for (final d in designs) {
      expect(GarmentDesign.fromJson(d.toJson()).toJson(), d.toJson());
    }
  });
}
