import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../domain/fabric_analysis.dart';
import '../domain/fabric_attributes.dart';

/// On-device, rule-based fabric analysis: k-means palette, colour family
/// from HSV, pattern from edge orientation/variance, texture from
/// high-frequency luminance energy. Designed to be swapped for an AI model.
class LocalFabricAnalyzer implements FabricAnalyzer {
  const LocalFabricAnalyzer();

  @override
  Future<FabricAnalysis> analyze(Uint8List imageBytes) => compute(analyzeFabricBytes, imageBytes);
}

FabricAnalysis analyzeFabricBytes(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return const FabricAnalysis(
      palette: [0xFFB9A7E0],
      colorFamily: ColorFamily.multicolor,
      pattern: FabricPattern.solid,
      texture: FabricTexture.smooth,
      fabricType: FabricType.cotton,
      patternConfidence: 0,
    );
  }
  const n = 64;
  final small = img.copyResize(decoded, width: n, height: n, interpolation: img.Interpolation.average);

  final px = <List<double>>[];
  final lum = List.generate(n, (_) => List.filled(n, 0.0));
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      final p = small.getPixel(x, y);
      final r = p.r.toDouble(), g = p.g.toDouble(), b = p.b.toDouble();
      px.add([r, g, b]);
      lum[y][x] = 0.299 * r + 0.587 * g + 0.114 * b;
    }
  }

  final clusters = _kMeans(px, 5);
  final palette = clusters.map((c) => _argb(c.center)).toList();
  final significant = clusters.where((c) => c.share >= 0.08).toList();

  final (pattern, confidence) = _pattern(lum, significant.length, clusters, px);
  var family = _colorFamily(clusters);
  if (pattern == FabricPattern.floral && _neutrals.contains(family)) family = ColorFamily.multicolor;
  final texture = _texture(lum, pattern);
  final fabricType = _guessFabricType(texture, clusters.first.center, pattern);

  return FabricAnalysis(
    palette: palette,
    colorFamily: family,
    pattern: pattern,
    texture: texture,
    fabricType: fabricType,
    occasions: _guessOccasions(family, pattern, fabricType),
    patternConfidence: confidence,
  );
}

class _Cluster {
  _Cluster(this.center, this.share);
  final List<double> center;
  final double share;
}

List<_Cluster> _kMeans(List<List<double>> px, int k) {
  final rnd = math.Random(7);
  var centers = List.generate(k, (i) => List<double>.from(px[(i * px.length ~/ k + rnd.nextInt(16)) % px.length]));
  var assign = List.filled(px.length, 0);
  for (var iter = 0; iter < 12; iter++) {
    for (var i = 0; i < px.length; i++) {
      var best = 0;
      var bestD = double.infinity;
      for (var c = 0; c < k; c++) {
        final d = _dist2(px[i], centers[c]);
        if (d < bestD) {
          bestD = d;
          best = c;
        }
      }
      assign[i] = best;
    }
    final sums = List.generate(k, (_) => [0.0, 0.0, 0.0, 0.0]);
    for (var i = 0; i < px.length; i++) {
      final s = sums[assign[i]];
      s[0] += px[i][0];
      s[1] += px[i][1];
      s[2] += px[i][2];
      s[3] += 1;
    }
    centers = [
      for (var c = 0; c < k; c++)
        sums[c][3] == 0 ? centers[c] : [sums[c][0] / sums[c][3], sums[c][1] / sums[c][3], sums[c][2] / sums[c][3]],
    ];
  }
  final counts = List.filled(k, 0);
  for (final a in assign) {
    counts[a]++;
  }
  final result = [
    for (var c = 0; c < k; c++)
      if (counts[c] > 0) _Cluster(centers[c], counts[c] / px.length),
  ];
  // Merge near-duplicate clusters so a plain fabric reads as one colour.
  final merged = <_Cluster>[];
  for (final c in result..sort((a, b) => b.share.compareTo(a.share))) {
    final i = merged.indexWhere((m) => _dist2(m.center, c.center) < 30 * 30);
    if (i == -1) {
      merged.add(c);
    } else {
      merged[i] = _Cluster(merged[i].center, merged[i].share + c.share);
    }
  }
  return merged..sort((a, b) => b.share.compareTo(a.share));
}

double _dist2(List<double> a, List<double> b) {
  final dr = a[0] - b[0], dg = a[1] - b[1], db = a[2] - b[2];
  return dr * dr + dg * dg + db * db;
}

int _argb(List<double> c) =>
    0xFF000000 | (c[0].round().clamp(0, 255) << 16) | (c[1].round().clamp(0, 255) << 8) | c[2].round().clamp(0, 255);

/// Returns (hue 0-360, saturation 0-1, value 0-1).
(double, double, double) hsv(List<double> c) {
  final r = c[0] / 255, g = c[1] / 255, b = c[2] / 255;
  final mx = math.max(r, math.max(g, b)), mn = math.min(r, math.min(g, b));
  final d = mx - mn;
  var h = 0.0;
  if (d != 0) {
    if (mx == r) {
      h = 60 * (((g - b) / d) % 6);
    } else if (mx == g) {
      h = 60 * (((b - r) / d) + 2);
    } else {
      h = 60 * (((r - g) / d) + 4);
    }
  }
  if (h < 0) h += 360;
  return (h, mx == 0 ? 0 : d / mx, mx);
}

ColorFamily familyOf(List<double> c) {
  final (h, s, v) = hsv(c);
  if (v < 0.2) return ColorFamily.black;
  if (s < 0.12) return v > 0.85 ? ColorFamily.white : ColorFamily.grey;
  if (s < 0.3 && v > 0.7 && (h < 60 || h > 330)) return ColorFamily.beige;
  if (h < 15 || h >= 345) return s < 0.5 && v > 0.7 ? ColorFamily.pink : ColorFamily.red;
  if (h < 40) return v < 0.6 ? ColorFamily.brown : ColorFamily.orange;
  if (h < 70) return v < 0.55 ? ColorFamily.brown : ColorFamily.yellow;
  if (h < 165) return ColorFamily.green;
  if (h < 255) return ColorFamily.blue;
  if (h < 290) return ColorFamily.purple;
  return ColorFamily.pink;
}

ColorFamily _colorFamily(List<_Cluster> clusters) {
  final shares = <ColorFamily, double>{};
  for (final c in clusters) {
    final f = familyOf(c.center);
    shares[f] = (shares[f] ?? 0) + c.share;
  }
  final sorted = shares.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final top = sorted.first;
  final chromatic = sorted.where((e) =>
      e.value >= 0.18 &&
      !{ColorFamily.white, ColorFamily.black, ColorFamily.grey, ColorFamily.beige}.contains(e.key));
  if (top.value < 0.45 && chromatic.length >= 2) return ColorFamily.multicolor;
  // Prefer the main chromatic colour over a white/black background.
  if ({ColorFamily.white, ColorFamily.black, ColorFamily.grey}.contains(top.key) && chromatic.isNotEmpty && top.value < 0.6) {
    return chromatic.first.key;
  }
  return top.key;
}

(FabricPattern, double) _pattern(List<List<double>> lum, int colorCount, List<_Cluster> clusters, List<List<double>> px) {
  final n = lum.length;
  var gx = 0.0, gy = 0.0, mean = 0.0;
  for (var y = 1; y < n - 1; y++) {
    for (var x = 1; x < n - 1; x++) {
      gx += (lum[y][x + 1] - lum[y][x - 1]).abs();
      gy += (lum[y + 1][x] - lum[y - 1][x]).abs();
      mean += lum[y][x];
    }
  }
  final cnt = ((n - 2) * (n - 2)).toDouble();
  gx /= cnt;
  gy /= cnt;
  mean /= cnt;
  var variance = 0.0;
  for (final row in lum) {
    for (final v in row) {
      variance += (v - mean) * (v - mean);
    }
  }
  final std = math.sqrt(variance / (n * n));
  final edge = (gx + gy) / 2;

  if (std < 14 && edge < 9) return (FabricPattern.solid, 0.85);

  final total = std * std + 1e-6;
  final rowMeans = _profile(lum, rows: true);
  final colMeans = _profile(lum, rows: false);
  final rowShare = _variance(rowMeans) / total;
  final colShare = _variance(colMeans) / total;
  // How well luminance separates into row + column terms: ~0 for stripes and
  // checks, high for prints with free-form motifs.
  var resid = 0.0;
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      final r = lum[y][x] - rowMeans[y] - colMeans[x] + mean;
      resid += r * r;
    }
  }
  final residShare = resid / (n * n) / total;

  if (residShare < 0.3) {
    final lo = math.min(rowShare, colShare), hi = math.max(rowShare, colShare);
    if (lo < 0.1 && hi > 0.5) return (FabricPattern.stripes, 0.8);
    if (lo > 0.15) return (FabricPattern.checks, 0.7);
  }
  final aniso = (gx - gy).abs() / (gx + gy + 1e-6);
  if (aniso > 0.5) return (FabricPattern.stripes, 0.5);

  // Count distinct chromatic hue families at pixel level; multi-hue motifs
  // (florals, ethnic prints) light up several families.
  final hueCounts = <ColorFamily, int>{};
  for (final c in px) {
    final f = familyOf(c);
    if (!_neutrals.contains(f)) hueCounts[f] = (hueCounts[f] ?? 0) + 1;
  }
  final hues = hueCounts.values.where((v) => v >= px.length * 0.03).length;
  if (hues >= 3) return (FabricPattern.floral, 0.55);
  final dominant = clusters.first.share;
  if (dominant > 0.55 && colorCount <= 3) return (FabricPattern.polka, 0.5);
  if (edge > 22) return (FabricPattern.geometric, 0.4);
  return (FabricPattern.abstract, 0.35);
}

const _neutrals = {ColorFamily.white, ColorFamily.black, ColorFamily.grey, ColorFamily.beige};

List<double> _profile(List<List<double>> lum, {required bool rows}) {
  final n = lum.length;
  return List.generate(n, (i) {
    var s = 0.0;
    for (var j = 0; j < n; j++) {
      s += rows ? lum[i][j] : lum[j][i];
    }
    return s / n;
  });
}

double _variance(List<double> v) {
  final m = v.reduce((a, b) => a + b) / v.length;
  return v.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / v.length;
}

FabricTexture _texture(List<List<double>> lum, FabricPattern pattern) {
  final n = lum.length;
  var hf = 0.0;
  var bright = 0.0;
  for (var y = 1; y < n - 1; y++) {
    for (var x = 1; x < n - 1; x++) {
      final lap = 4 * lum[y][x] - lum[y - 1][x] - lum[y + 1][x] - lum[y][x - 1] - lum[y][x + 1];
      hf += lap.abs();
      bright += lum[y][x];
    }
  }
  final cnt = ((n - 2) * (n - 2)).toDouble();
  hf /= cnt;
  bright /= cnt;
  if (pattern == FabricPattern.solid) {
    if (hf > 6) return FabricTexture.textured;
    if (bright > 215) return FabricTexture.sheer;
    if (bright < 70) return FabricTexture.heavy;
    return FabricTexture.smooth;
  }
  return hf > 30 ? FabricTexture.textured : FabricTexture.smooth;
}

FabricType _guessFabricType(FabricTexture t, List<double> main, FabricPattern p) {
  final (h, s, v) = hsv(main);
  return switch (t) {
    FabricTexture.sheer => FabricType.chiffon,
    FabricTexture.heavy => s > 0.4 ? FabricType.velvet : FabricType.brocade,
    FabricTexture.textured => (h > 190 && h < 240 && v < 0.6) ? FabricType.denim : FabricType.linen,
    FabricTexture.smooth => p == FabricPattern.solid && s > 0.45 && v > 0.45
        ? FabricType.silk
        : (p == FabricPattern.floral ? FabricType.rayon : FabricType.cotton),
  };
}

Set<Occasion> _guessOccasions(ColorFamily f, FabricPattern p, FabricType t) {
  if ({FabricType.silk, FabricType.brocade, FabricType.velvet}.contains(t)) {
    return {Occasion.festive, Occasion.wedding};
  }
  if ({FabricPattern.checks, FabricPattern.stripes}.contains(p) ||
      {ColorFamily.white, ColorFamily.grey, ColorFamily.beige, ColorFamily.blue}.contains(f)) {
    return {Occasion.casual, Occasion.office};
  }
  if ({FabricType.chiffon, FabricType.georgette}.contains(t)) return {Occasion.party};
  return {Occasion.casual};
}
