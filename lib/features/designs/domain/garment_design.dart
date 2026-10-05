import '../../fabric/domain/fabric_attributes.dart';

enum GarmentSilhouette {
  kurti('Kurti'),
  anarkali('Anarkali'),
  aLineDress('A-Line Dress'),
  maxiGown('Maxi Gown'),
  peplumTop('Peplum Top'),
  shirt('Shirt'),
  lehenga('Lehenga Set'),
  kaftan('Kaftan');

  const GarmentSilhouette(this.label);
  final String label;
}

enum Difficulty {
  easy('Easy'),
  medium('Medium'),
  advanced('Advanced');

  const Difficulty(this.label);
  final String label;
}

class GarmentDesign {
  const GarmentDesign({
    required this.id,
    required this.name,
    required this.description,
    required this.silhouette,
    required this.category,
    required this.colorFamilies,
    required this.patterns,
    required this.textures,
    required this.fabricTypes,
    required this.occasions,
    required this.styles,
    required this.fabricMeters,
    required this.difficulty,
    required this.features,
    required this.previewColor,
  });

  final String id;
  final String name;
  final String description;
  final GarmentSilhouette silhouette;
  final GarmentCategory category;

  /// Colour families that suit this design. Empty means any colour works.
  final Set<ColorFamily> colorFamilies;
  final Set<FabricPattern> patterns;
  final Set<FabricTexture> textures;
  final Set<FabricType> fabricTypes;
  final Set<Occasion> occasions;
  final Set<StyleTag> styles;
  final double fabricMeters;
  final Difficulty difficulty;
  final List<String> features;

  /// ARGB tone used when rendering the design without a user fabric.
  final int previewColor;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'silhouette': silhouette.name,
        'category': category.name,
        'colorFamilies': colorFamilies.map((e) => e.name).toList(),
        'patterns': patterns.map((e) => e.name).toList(),
        'textures': textures.map((e) => e.name).toList(),
        'fabricTypes': fabricTypes.map((e) => e.name).toList(),
        'occasions': occasions.map((e) => e.name).toList(),
        'styles': styles.map((e) => e.name).toList(),
        'fabricMeters': fabricMeters,
        'difficulty': difficulty.name,
        'features': features,
        'previewColor': previewColor,
      };

  factory GarmentDesign.fromJson(Map<String, dynamic> json) => GarmentDesign(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        silhouette: enumByName(GarmentSilhouette.values, json['silhouette'] as String?, GarmentSilhouette.kurti),
        category: enumByName(GarmentCategory.values, json['category'] as String?, GarmentCategory.ethnic),
        colorFamilies: enumSetByNames(ColorFamily.values, json['colorFamilies'] as List?),
        patterns: enumSetByNames(FabricPattern.values, json['patterns'] as List?),
        textures: enumSetByNames(FabricTexture.values, json['textures'] as List?),
        fabricTypes: enumSetByNames(FabricType.values, json['fabricTypes'] as List?),
        occasions: enumSetByNames(Occasion.values, json['occasions'] as List?),
        styles: enumSetByNames(StyleTag.values, json['styles'] as List?),
        fabricMeters: (json['fabricMeters'] as num?)?.toDouble() ?? 2.5,
        difficulty: enumByName(Difficulty.values, json['difficulty'] as String?, Difficulty.medium),
        features: List<String>.from(json['features'] as List? ?? const []),
        previewColor: json['previewColor'] as int? ?? 0xFFB9A7E0,
      );
}

abstract interface class DesignRepository {
  Future<List<GarmentDesign>> fetchAll();
  Future<GarmentDesign?> byId(String id);
}
