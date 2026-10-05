
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Downscales a picked photo to at most [maxSide]px JPEG so it is cheap to
/// analyse, store and upload.
Future<Uint8List> prepareFabricImage(Uint8List raw, {int maxSide = 768}) =>
    compute(_prepare, (raw, maxSide));

Uint8List _prepare((Uint8List, int) args) {
  final (raw, maxSide) = args;
  final decoded = img.decodeImage(raw);
  if (decoded == null) return raw;
  final oriented = img.bakeOrientation(decoded);
  final longest = oriented.width > oriented.height ? oriented.width : oriented.height;
  final resized = longest <= maxSide
      ? oriented
      : img.copyResize(
          oriented,
          width: oriented.width >= oriented.height ? maxSide : null,
          height: oriented.height > oriented.width ? maxSide : null,
          interpolation: img.Interpolation.average,
        );
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}
