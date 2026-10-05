import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../designs/domain/garment_design.dart';
import 'garment_shapes.dart';

/// Renders a garment design. When [fabric] is set, the user's fabric is
/// tiled into every panel and shaded to suggest drape and folds; otherwise
/// the design's preview colour is used.
class GarmentPainter extends CustomPainter {
  GarmentPainter({
    required this.silhouette,
    required this.baseColor,
    this.fabric,
    this.patternScale = 1,
    this.patternRotation = 0,
    this.showShading = true,
  }) : _shape = shapeFor(silhouette);

  final GarmentSilhouette silhouette;
  final Color baseColor;
  final ui.Image? fabric;
  final double patternScale;

  /// Degrees.
  final double patternRotation;
  final bool showShading;
  final GarmentShape _shape;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / GarmentShape.canvas.width, size.height / GarmentShape.canvas.height);
    final dx = (size.width - GarmentShape.canvas.width * s) / 2;
    final dy = (size.height - GarmentShape.canvas.height * s) / 2;
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(s);

    final outline = _shape.outline;

    // Soft drop shadow under the garment.
    canvas.drawPath(
      outline.shift(const Offset(0, 4)),
      Paint()
        ..color = AppColors.deepPurple.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final fill = _fillPaint(s);
    for (final p in _shape.shadedPanels) {
      canvas.drawPath(p, fill);
      canvas.drawPath(p, Paint()..color = Colors.black.withValues(alpha: 0.12));
    }
    for (final p in _shape.panels) {
      canvas.drawPath(p, fill);
    }

    if (showShading) _drawShading(canvas, outline);

    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = AppColors.charcoal.withValues(alpha: 0.28);
    for (final p in _shape.seams) {
      canvas.drawPath(p, seam);
    }
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.charcoal.withValues(alpha: 0.35),
    );
    canvas.restore();
  }

  Paint _fillPaint(double canvasScale) {
    final img = fabric;
    if (img == null) return Paint()..color = baseColor;
    // Target: the fabric's shorter side spans ~70 canvas units at scale 1.
    final unit = 70 * patternScale / math.min(img.width, img.height);
    final rad = patternRotation * math.pi / 180;
    final m = Matrix4.identity()
      ..rotateZ(rad)
      ..scaleByDouble(unit, unit, 1, 1);
    return Paint()
      ..shader = ImageShader(img, TileMode.repeated, TileMode.repeated, m.storage)
      ..filterQuality = FilterQuality.medium;
  }

  void _drawShading(Canvas canvas, Path outline) {
    final bounds = outline.getBounds();
    canvas.save();
    canvas.clipPath(outline);
    // Body curvature: darker at the sides, highlight down the centre.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.centerLeft,
          bounds.centerRight,
          [
            Colors.black.withValues(alpha: 0.28),
            Colors.black.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.10),
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.28),
          ],
          [0, 0.28, 0.5, 0.72, 1],
        ),
    );
    // Soft vertical folds.
    final fold = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..strokeWidth = 5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final rnd = math.Random(silhouette.index);
    for (var i = 0; i < 5; i++) {
      final x = bounds.left + bounds.width * (0.18 + 0.16 * i) + rnd.nextDouble() * 4;
      final top = bounds.top + bounds.height * (0.35 + rnd.nextDouble() * 0.1);
      canvas.drawLine(Offset(x, top), Offset(x + (x - bounds.center.dx) * 0.15, bounds.bottom), fold);
    }
    // Light from above.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.topCenter,
          bounds.bottomCenter,
          [Colors.white.withValues(alpha: 0.12), Colors.transparent, Colors.black.withValues(alpha: 0.12)],
          [0, 0.4, 1],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(GarmentPainter old) =>
      old.silhouette != silhouette ||
      old.fabric != fabric ||
      old.baseColor != baseColor ||
      old.patternScale != patternScale ||
      old.patternRotation != patternRotation ||
      old.showShading != showShading;
}

/// Convenience widget: decodes [fabricBytes] once and paints the garment.
class GarmentView extends StatefulWidget {
  const GarmentView({
    super.key,
    required this.design,
    this.fabricBytes,
    this.patternScale = 1,
    this.patternRotation = 0,
    this.showShading = true,
  });

  final GarmentDesign design;
  final List<int>? fabricBytes;
  final double patternScale;
  final double patternRotation;
  final bool showShading;

  @override
  State<GarmentView> createState() => _GarmentViewState();
}

class _GarmentViewState extends State<GarmentView> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(GarmentView old) {
    super.didUpdateWidget(old);
    if (!identical(old.fabricBytes, widget.fabricBytes)) _decode();
  }

  Future<void> _decode() async {
    final bytes = widget.fabricBytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() => _image = null);
      return;
    }
    final img = await FabricImageCache.decode(bytes);
    if (mounted) setState(() => _image = img);
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: GarmentPainter(
          silhouette: widget.design.silhouette,
          baseColor: Color(widget.design.previewColor),
          fabric: _image,
          patternScale: widget.patternScale,
          patternRotation: widget.patternRotation,
          showShading: widget.showShading,
        ),
        child: const SizedBox.expand(),
      );
}

abstract final class FabricImageCache {
  static final _cache = Expando<Future<ui.Image>>();

  static Future<ui.Image> decode(List<int> bytes) {
    return _cache[bytes] ??= () async {
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      return (await codec.getNextFrame()).image;
    }();
  }
}
