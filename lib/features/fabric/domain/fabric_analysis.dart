import 'dart:typed_data';

import 'fabric_attributes.dart';

/// Result of analysing a fabric photo. Every field is user-editable; the
/// analyzer only provides a best first guess.
class FabricAnalysis {
  const FabricAnalysis({
    required this.palette,
    required this.colorFamily,
    required this.pattern,
    required this.texture,
    required this.fabricType,
    this.occasions = const {},
    this.styles = const {},
    this.category,
    this.patternConfidence = 0.5,
  });

  /// Dominant colours as ARGB ints, most dominant first.
  final List<int> palette;
  final ColorFamily colorFamily;
  final FabricPattern pattern;
  final FabricTexture texture;
  final FabricType fabricType;
  final Set<Occasion> occasions;
  final Set<StyleTag> styles;
  final GarmentCategory? category;
  final double patternConfidence;

  FabricAnalysis copyWith({
    List<int>? palette,
    ColorFamily? colorFamily,
    FabricPattern? pattern,
    FabricTexture? texture,
    FabricType? fabricType,
    Set<Occasion>? occasions,
    Set<StyleTag>? styles,
    GarmentCategory? category,
    bool clearCategory = false,
  }) =>
      FabricAnalysis(
        palette: palette ?? this.palette,
        colorFamily: colorFamily ?? this.colorFamily,
        pattern: pattern ?? this.pattern,
        texture: texture ?? this.texture,
        fabricType: fabricType ?? this.fabricType,
        occasions: occasions ?? this.occasions,
        styles: styles ?? this.styles,
        category: clearCategory ? null : (category ?? this.category),
        patternConfidence: patternConfidence,
      );

  Map<String, dynamic> toJson() => {
        'palette': palette,
        'colorFamily': colorFamily.name,
        'pattern': pattern.name,
        'texture': texture.name,
        'fabricType': fabricType.name,
        'occasions': occasions.map((e) => e.name).toList(),
        'styles': styles.map((e) => e.name).toList(),
        'category': category?.name,
        'patternConfidence': patternConfidence,
      };

  factory FabricAnalysis.fromJson(Map<String, dynamic> json) => FabricAnalysis(
        palette: List<int>.from(json['palette'] as List? ?? const []),
        colorFamily: enumByName(ColorFamily.values, json['colorFamily'] as String?, ColorFamily.multicolor),
        pattern: enumByName(FabricPattern.values, json['pattern'] as String?, FabricPattern.solid),
        texture: enumByName(FabricTexture.values, json['texture'] as String?, FabricTexture.smooth),
        fabricType: enumByName(FabricType.values, json['fabricType'] as String?, FabricType.cotton),
        occasions: enumSetByNames(Occasion.values, json['occasions'] as List?),
        styles: enumSetByNames(StyleTag.values, json['styles'] as List?),
        category: json['category'] == null
            ? null
            : enumByName(GarmentCategory.values, json['category'] as String?, GarmentCategory.ethnic),
        patternConfidence: (json['patternConfidence'] as num?)?.toDouble() ?? 0.5,
      );
}

/// A fabric photo selected by the user, downscaled to JPEG bytes.
class FabricPhoto {
  const FabricPhoto({required this.bytes, this.label});
  final Uint8List bytes;
  final String? label;
}

abstract interface class FabricAnalyzer {
  Future<FabricAnalysis> analyze(Uint8List imageBytes);
}
