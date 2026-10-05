import 'dart:convert';
import 'dart:typed_data';

import '../../fabric/domain/fabric_analysis.dart';

/// A fabric applied to a design, saved by the user.
class SavedLook {
  const SavedLook({
    required this.id,
    required this.designId,
    required this.designName,
    required this.fabricBytes,
    required this.analysis,
    required this.patternScale,
    required this.patternRotation,
    required this.createdAt,
    this.fabricUrl,
  });

  final String id;
  final String designId;
  final String designName;
  final Uint8List fabricBytes;
  final FabricAnalysis analysis;
  final double patternScale;
  final double patternRotation;
  final DateTime createdAt;

  /// Remote copy of the fabric image (Firebase Storage), when synced.
  final String? fabricUrl;

  SavedLook copyWith({String? fabricUrl}) => SavedLook(
        id: id,
        designId: designId,
        designName: designName,
        fabricBytes: fabricBytes,
        analysis: analysis,
        patternScale: patternScale,
        patternRotation: patternRotation,
        createdAt: createdAt,
        fabricUrl: fabricUrl ?? this.fabricUrl,
      );

  Map<String, dynamic> toJson({bool includeBytes = true}) => {
        'id': id,
        'designId': designId,
        'designName': designName,
        if (includeBytes) 'fabric': base64Encode(fabricBytes),
        'analysis': analysis.toJson(),
        'patternScale': patternScale,
        'patternRotation': patternRotation,
        'createdAt': createdAt.toIso8601String(),
        'fabricUrl': fabricUrl,
      };

  factory SavedLook.fromJson(Map<String, dynamic> json, {Uint8List? bytes}) => SavedLook(
        id: json['id'] as String,
        designId: json['designId'] as String,
        designName: json['designName'] as String? ?? '',
        fabricBytes: bytes ?? base64Decode(json['fabric'] as String? ?? ''),
        analysis: FabricAnalysis.fromJson(Map<String, dynamic>.from(json['analysis'] as Map)),
        patternScale: (json['patternScale'] as num?)?.toDouble() ?? 1,
        patternRotation: (json['patternRotation'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        fabricUrl: json['fabricUrl'] as String?,
      );
}

abstract interface class FavoritesRepository {
  Future<List<SavedLook>> fetchAll();
  Future<SavedLook> save(SavedLook look);
  Future<void> delete(String id);
}
