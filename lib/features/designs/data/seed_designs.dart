import '../../fabric/domain/fabric_attributes.dart';
import '../domain/garment_design.dart';

/// Starter catalogue: 8 silhouettes x 8 style variants (minus a few that
/// don't make sense) = 60 designs. The same schema is stored in Firestore,
/// so the catalogue can grow to 500+ without code changes.
List<GarmentDesign> buildSeedDesigns() {
  final designs = <GarmentDesign>[];
  for (final base in _bases) {
    for (final v in _variants) {
      if (_skip.contains('${base.silhouette.name}/${v.key}')) continue;
      designs.add(
        GarmentDesign(
          id: '${base.silhouette.name}-${v.key}',
          name: '${v.name} ${base.silhouette.label}',
          description: '${base.description} ${v.description}',
          silhouette: base.silhouette,
          category: base.category,
          colorFamilies: v.colors,
          patterns: v.patterns,
          textures: v.textures,
          fabricTypes: {...base.fabrics.take(2), ...v.fabrics.intersection(base.fabrics), ...v.fabrics.take(2)},
          occasions: _occasionsFor(base, v),
          styles: v.styles,
          fabricMeters: base.meters + v.extraMeters,
          difficulty: v.extraMeters >= 1 && base.difficulty == Difficulty.medium ? Difficulty.advanced : base.difficulty,
          features: [...base.features, v.detail],
          previewColor: v.tone,
        ),
      );
    }
  }
  return designs;
}

Set<Occasion> _occasionsFor(_Base base, _Variant v) {
  final shared = base.occasions.intersection(v.occasions);
  return shared.isNotEmpty ? shared : {...v.occasions, base.occasions.first};
}

const _skip = {
  'shirt/royal',
  'kaftan/royal',
  'lehenga/everyday',
  'lehenga/minimal',
};

class _Base {
  const _Base(this.silhouette, this.category, this.description, this.fabrics, this.occasions, this.meters,
      this.difficulty, this.features);
  final GarmentSilhouette silhouette;
  final GarmentCategory category;
  final String description;
  final Set<FabricType> fabrics;
  final Set<Occasion> occasions;
  final double meters;
  final Difficulty difficulty;
  final List<String> features;
}

class _Variant {
  const _Variant({
    required this.key,
    required this.name,
    required this.description,
    required this.colors,
    required this.patterns,
    required this.textures,
    required this.fabrics,
    required this.occasions,
    required this.styles,
    required this.detail,
    required this.tone,
    this.extraMeters = 0,
  });
  final String key;
  final String name;
  final String description;
  final Set<ColorFamily> colors;
  final Set<FabricPattern> patterns;
  final Set<FabricTexture> textures;
  final Set<FabricType> fabrics;
  final Set<Occasion> occasions;
  final Set<StyleTag> styles;
  final String detail;
  final int tone;
  final double extraMeters;
}

const _bases = [
  _Base(GarmentSilhouette.kurti, GarmentCategory.ethnic, 'A straight, knee-length kurti with side slits.',
      {FabricType.cotton, FabricType.rayon, FabricType.linen, FabricType.silk},
      {Occasion.casual, Occasion.office, Occasion.festive}, 2.5, Difficulty.easy,
      ['Round neckline', 'Three-quarter sleeves', 'Knee length']),
  _Base(GarmentSilhouette.anarkali, GarmentCategory.ethnic, 'A flowing, floor-sweeping anarkali with a fitted bodice.',
      {FabricType.georgette, FabricType.silk, FabricType.chiffon, FabricType.velvet},
      {Occasion.festive, Occasion.wedding, Occasion.party}, 4.5, Difficulty.medium,
      ['Fitted bodice', 'Full flare', 'Full sleeves']),
  _Base(GarmentSilhouette.aLineDress, GarmentCategory.western, 'A flattering A-line dress that skims the body.',
      {FabricType.cotton, FabricType.crepe, FabricType.linen, FabricType.rayon},
      {Occasion.casual, Occasion.office, Occasion.party}, 2.2, Difficulty.easy,
      ['Boat neckline', 'Short sleeves', 'Midi length']),
  _Base(GarmentSilhouette.maxiGown, GarmentCategory.western, 'A floor-length gown with a defined waist.',
      {FabricType.chiffon, FabricType.georgette, FabricType.silk, FabricType.crepe},
      {Occasion.party, Occasion.wedding}, 3.8, Difficulty.medium,
      ['Sweetheart neckline', 'Sleeveless', 'Floor length']),
  _Base(GarmentSilhouette.peplumTop, GarmentCategory.fusion, 'A structured top with a flared peplum at the waist.',
      {FabricType.cotton, FabricType.crepe, FabricType.brocade, FabricType.silk},
      {Occasion.office, Occasion.party, Occasion.festive}, 1.6, Difficulty.medium,
      ['V neckline', 'Short sleeves', 'Peplum waist']),
  _Base(GarmentSilhouette.shirt, GarmentCategory.western, 'A relaxed button-down shirt with a classic collar.',
      {FabricType.cotton, FabricType.linen, FabricType.denim, FabricType.rayon},
      {Occasion.casual, Occasion.office}, 1.8, Difficulty.medium,
      ['Collared neckline', 'Full sleeves', 'Hip length']),
  _Base(GarmentSilhouette.lehenga, GarmentCategory.ethnic, 'A cropped blouse paired with a voluminous lehenga skirt.',
      {FabricType.silk, FabricType.brocade, FabricType.velvet, FabricType.georgette},
      {Occasion.wedding, Occasion.festive}, 5.5, Difficulty.advanced,
      ['Cropped blouse', 'Circular skirt', 'Floor length']),
  _Base(GarmentSilhouette.kaftan, GarmentCategory.fusion, 'An airy, easy kaftan with wide batwing sleeves.',
      {FabricType.chiffon, FabricType.georgette, FabricType.cotton, FabricType.rayon},
      {Occasion.casual, Occasion.party}, 2.6, Difficulty.easy,
      ['Keyhole neckline', 'Batwing sleeves', 'Relaxed fit']),
];

const _variants = [
  _Variant(
    key: 'classic', name: 'Classic', description: 'Timeless proportions that let the fabric speak.',
    colors: {}, patterns: {FabricPattern.solid, FabricPattern.ethnic, FabricPattern.floral},
    textures: {FabricTexture.smooth, FabricTexture.textured},
    fabrics: {FabricType.cotton, FabricType.silk, FabricType.rayon, FabricType.linen},
    occasions: {Occasion.office, Occasion.festive, Occasion.casual}, styles: {StyleTag.classic},
    detail: 'Clean piping at neckline', tone: 0xFFB9A7E0),
  _Variant(
    key: 'modern', name: 'Modern', description: 'Sharp lines and a contemporary finish.',
    colors: {}, patterns: {FabricPattern.geometric, FabricPattern.abstract, FabricPattern.stripes, FabricPattern.solid},
    textures: {FabricTexture.smooth},
    fabrics: {FabricType.crepe, FabricType.cotton, FabricType.rayon, FabricType.linen},
    occasions: {Occasion.office, Occasion.party}, styles: {StyleTag.modern, StyleTag.minimal},
    detail: 'Asymmetric hemline', tone: 0xFF5B477A),
  _Variant(
    key: 'boho', name: 'Boho', description: 'Free-spirited and relaxed with soft gathers.',
    colors: {ColorFamily.orange, ColorFamily.brown, ColorFamily.beige, ColorFamily.green, ColorFamily.yellow, ColorFamily.multicolor, ColorFamily.red},
    patterns: {FabricPattern.floral, FabricPattern.ethnic, FabricPattern.abstract, FabricPattern.polka},
    textures: {FabricTexture.textured, FabricTexture.sheer},
    fabrics: {FabricType.cotton, FabricType.rayon, FabricType.linen, FabricType.chiffon},
    occasions: {Occasion.casual}, styles: {StyleTag.boho},
    detail: 'Tassel tie-ups', tone: 0xFFD98FA3),
  _Variant(
    key: 'minimal', name: 'Minimal', description: 'Pared-back tailoring for everyday polish.',
    colors: {ColorFamily.white, ColorFamily.beige, ColorFamily.grey, ColorFamily.black, ColorFamily.blue, ColorFamily.brown, ColorFamily.green},
    patterns: {FabricPattern.solid, FabricPattern.stripes, FabricPattern.checks},
    textures: {FabricTexture.smooth},
    fabrics: {FabricType.linen, FabricType.cotton, FabricType.crepe},
    occasions: {Occasion.casual, Occasion.office}, styles: {StyleTag.minimal},
    detail: 'Hidden placket', tone: 0xFFE8DCCF),
  _Variant(
    key: 'royal', name: 'Royal', description: 'Rich, regal styling for grand celebrations.',
    colors: {ColorFamily.red, ColorFamily.pink, ColorFamily.purple, ColorFamily.green, ColorFamily.yellow, ColorFamily.blue},
    patterns: {FabricPattern.solid, FabricPattern.ethnic, FabricPattern.floral},
    textures: {FabricTexture.heavy, FabricTexture.textured, FabricTexture.smooth},
    fabrics: {FabricType.silk, FabricType.brocade, FabricType.velvet, FabricType.georgette},
    occasions: {Occasion.wedding, Occasion.festive}, styles: {StyleTag.elegant, StyleTag.classic},
    detail: 'Zari border detail', tone: 0xFF8E3B5E, extraMeters: 1),
  _Variant(
    key: 'garden', name: 'Garden Party', description: 'Light and romantic with a soft, airy drape.',
    colors: {ColorFamily.pink, ColorFamily.yellow, ColorFamily.white, ColorFamily.green, ColorFamily.blue, ColorFamily.beige, ColorFamily.purple},
    patterns: {FabricPattern.floral, FabricPattern.polka, FabricPattern.solid},
    textures: {FabricTexture.sheer, FabricTexture.smooth},
    fabrics: {FabricType.chiffon, FabricType.georgette, FabricType.cotton},
    occasions: {Occasion.party, Occasion.casual}, styles: {StyleTag.elegant, StyleTag.boho},
    detail: 'Ruffle trim', tone: 0xFFF2C6D2, extraMeters: 0.5),
  _Variant(
    key: 'everyday', name: 'Everyday', description: 'Comfortable, breathable and easy to wear all day.',
    colors: {}, patterns: {FabricPattern.checks, FabricPattern.stripes, FabricPattern.polka, FabricPattern.solid, FabricPattern.floral},
    textures: {FabricTexture.smooth, FabricTexture.textured},
    fabrics: {FabricType.cotton, FabricType.rayon, FabricType.denim, FabricType.linen},
    occasions: {Occasion.casual}, styles: {StyleTag.classic, StyleTag.minimal},
    detail: 'Side pockets', tone: 0xFF9DB7C9),
  _Variant(
    key: 'statement', name: 'Statement', description: 'Bold cuts made to stand out after dark.',
    colors: {ColorFamily.black, ColorFamily.red, ColorFamily.blue, ColorFamily.multicolor, ColorFamily.purple, ColorFamily.orange, ColorFamily.green},
    patterns: {FabricPattern.abstract, FabricPattern.geometric, FabricPattern.solid},
    textures: {FabricTexture.smooth, FabricTexture.heavy},
    fabrics: {FabricType.crepe, FabricType.velvet, FabricType.silk, FabricType.georgette},
    occasions: {Occasion.party}, styles: {StyleTag.modern, StyleTag.elegant},
    detail: 'Dramatic puff shoulders', tone: 0xFF29252D, extraMeters: 0.5),
];
