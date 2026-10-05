import '../../fabric/domain/fabric_analysis.dart';
import '../../fabric/domain/fabric_attributes.dart';
import 'garment_design.dart';

class DesignMatch {
  const DesignMatch({required this.design, required this.score, required this.reasons});
  final GarmentDesign design;

  /// 0–100.
  final int score;
  final List<String> reasons;
}

/// Rule-based matcher. Each attribute contributes a weighted share of the
/// score; designs below [minScore] are dropped.
class RecommendationEngine {
  const RecommendationEngine({this.minScore = 35});

  final int minScore;

  static const _wFabricType = 22;
  static const _wPattern = 20;
  static const _wTexture = 14;
  static const _wColor = 14;
  static const _wOccasion = 12;
  static const _wStyle = 10;
  static const _wCategory = 8;

  List<DesignMatch> recommend(
    FabricAnalysis fabric,
    List<GarmentDesign> designs, {
    Occasion? occasion,
    GarmentCategory? category,
  }) {
    final matches = <DesignMatch>[];
    for (final d in designs) {
      if (occasion != null && !d.occasions.contains(occasion)) continue;
      if (category != null && d.category != category) continue;
      final m = score(fabric, d);
      if (m.score >= minScore) matches.add(m);
    }
    matches.sort((a, b) {
      final c = b.score.compareTo(a.score);
      return c != 0 ? c : a.design.name.compareTo(b.design.name);
    });
    return matches;
  }

  DesignMatch score(FabricAnalysis f, GarmentDesign d) {
    var total = 0.0;
    final reasons = <String>[];

    if (d.fabricTypes.contains(f.fabricType)) {
      total += _wFabricType;
      reasons.add('${f.fabricType.label} drapes well for this cut');
    } else if (_similarFabric(f.fabricType).any(d.fabricTypes.contains)) {
      total += _wFabricType * 0.5;
    }

    if (d.patterns.contains(f.pattern)) {
      total += _wPattern;
      reasons.add('${f.pattern.label} pattern suits the silhouette');
    } else if (f.pattern == FabricPattern.solid) {
      total += _wPattern * 0.4;
    }

    if (d.textures.contains(f.texture)) {
      total += _wTexture;
      reasons.add('${f.texture.label} texture works for this design');
    }

    if (d.colorFamilies.isEmpty || d.colorFamilies.contains(f.colorFamily)) {
      total += _wColor;
      if (d.colorFamilies.isNotEmpty) reasons.add('Great in ${f.colorFamily.label.toLowerCase()} tones');
    } else if (f.colorFamily == ColorFamily.multicolor) {
      total += _wColor * 0.5;
    }

    total += _setScore(f.occasions, d.occasions, _wOccasion, reasons, (s) => 'Perfect for ${s.label.toLowerCase()} wear');
    total += _setScore(f.styles, d.styles, _wStyle, reasons, (s) => '${s.label} style match');

    if (f.category == null) {
      total += _wCategory * 0.5;
    } else if (f.category == d.category) {
      total += _wCategory;
      reasons.add('${d.category.label} wear as you prefer');
    }

    return DesignMatch(design: d, score: total.round().clamp(0, 100), reasons: reasons);
  }

  double _setScore<T extends Enum>(
    Set<T> wanted,
    Set<T> offered,
    int weight,
    List<String> reasons,
    String Function(T) reason,
  ) {
    if (wanted.isEmpty) return weight * 0.5;
    final hit = wanted.where(offered.contains).toList();
    if (hit.isEmpty) return 0;
    reasons.add(reason(hit.first));
    return weight * (0.6 + 0.4 * hit.length / wanted.length);
  }

  Set<FabricType> _similarFabric(FabricType t) => switch (t) {
        FabricType.cotton => {FabricType.linen, FabricType.rayon},
        FabricType.linen => {FabricType.cotton},
        FabricType.rayon => {FabricType.cotton, FabricType.crepe},
        FabricType.silk => {FabricType.brocade, FabricType.crepe},
        FabricType.georgette => {FabricType.chiffon, FabricType.crepe},
        FabricType.chiffon => {FabricType.georgette},
        FabricType.crepe => {FabricType.georgette, FabricType.rayon},
        FabricType.velvet => {FabricType.brocade},
        FabricType.brocade => {FabricType.silk, FabricType.velvet},
        FabricType.denim => {FabricType.cotton},
      };
}
