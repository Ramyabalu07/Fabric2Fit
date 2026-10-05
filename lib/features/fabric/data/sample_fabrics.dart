import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Procedurally generated swatches so the full flow can be tried without
/// a camera (e.g. on web or emulators).
class SampleFabric {
  const SampleFabric(this.name, this.builder);
  final String name;
  final img.Image Function() builder;

  Uint8List encode() => Uint8List.fromList(img.encodeJpg(builder(), quality: 90));
}

const _size = 256;

img.ColorRgb8 _c(int argb) => img.ColorRgb8((argb >> 16) & 0xFF, (argb >> 8) & 0xFF, argb & 0xFF);

final sampleFabrics = <SampleFabric>[
  SampleFabric('Lavender Stripes', () {
    final im = img.Image(width: _size, height: _size);
    for (var y = 0; y < _size; y++) {
      for (var x = 0; x < _size; x++) {
        final band = (x ~/ 16) % 3;
        im.setPixel(x, y, _c(band == 0 ? 0xFF5B477A : band == 1 ? 0xFFB9A7E0 : 0xFFFFF9F5));
      }
    }
    return im;
  }),
  SampleFabric('Rose Gingham', () {
    final im = img.Image(width: _size, height: _size);
    for (var y = 0; y < _size; y++) {
      for (var x = 0; x < _size; x++) {
        final a = (x ~/ 20).isEven, b = (y ~/ 20).isEven;
        final col = a && b ? 0xFFB55A75 : (a || b ? 0xFFD98FA3 : 0xFFFBEFF2);
        im.setPixel(x, y, _c(col));
      }
    }
    return im;
  }),
  SampleFabric('Midnight Polka', () {
    final im = img.Image(width: _size, height: _size);
    img.fill(im, color: _c(0xFF1F2A44));
    for (var gy = 0; gy < _size; gy += 32) {
      for (var gx = 0; gx < _size; gx += 32) {
        final off = (gy ~/ 32).isOdd ? 16 : 0;
        img.fillCircle(im, x: gx + off + 8, y: gy + 16, radius: 6, color: _c(0xFFF4E9D8));
      }
    }
    return im;
  }),
  SampleFabric('Emerald Silk', () {
    final im = img.Image(width: _size, height: _size);
    for (var y = 0; y < _size; y++) {
      for (var x = 0; x < _size; x++) {
        final sheen = (math.sin((x + y) / 40) * 14).round();
        im.setPixel(x, y, img.ColorRgb8(18 + sheen ~/ 2, 120 + sheen, 88 + sheen));
      }
    }
    return im;
  }),
  SampleFabric('Marigold Floral', () {
    final im = img.Image(width: _size, height: _size);
    img.fill(im, color: _c(0xFFFFF4DC));
    final rnd = math.Random(3);
    const petals = [0xFFE8A33D, 0xFFD9534F, 0xFF6B8E4E, 0xFFB9A7E0];
    for (var i = 0; i < 42; i++) {
      final cx = rnd.nextInt(_size), cy = rnd.nextInt(_size);
      final col = petals[i % petals.length];
      for (var k = 0; k < 5; k++) {
        final ang = k * 2 * math.pi / 5;
        img.fillCircle(im,
            x: cx + (math.cos(ang) * 8).round(), y: cy + (math.sin(ang) * 8).round(), radius: 6, color: _c(col));
      }
      img.fillCircle(im, x: cx, y: cy, radius: 4, color: _c(0xFF7A4B2A));
    }
    return im;
  }),
];
