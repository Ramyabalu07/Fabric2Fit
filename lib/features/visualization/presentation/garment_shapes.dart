import 'dart:ui';

import '../../designs/domain/garment_design.dart';

/// Garment outlines in a 200x300 canvas. Every shape is split into fabric
/// panels (filled with the user's fabric) and seam/detail lines.
class GarmentShape {
  const GarmentShape({required this.panels, required this.seams, this.shadedPanels = const []});

  final List<Path> panels;

  /// Panels drawn slightly darker (sleeves, inner layers) for depth.
  final List<Path> shadedPanels;
  final List<Path> seams;

  static const canvas = Size(200, 300);

  Path get outline {
    final p = Path();
    for (final panel in [...shadedPanels, ...panels]) {
      p.addPath(panel, Offset.zero);
    }
    return p;
  }
}

GarmentShape shapeFor(GarmentSilhouette s) => switch (s) {
      GarmentSilhouette.kurti => _kurti(),
      GarmentSilhouette.anarkali => _anarkali(),
      GarmentSilhouette.aLineDress => _aLineDress(),
      GarmentSilhouette.maxiGown => _maxiGown(),
      GarmentSilhouette.peplumTop => _peplum(),
      GarmentSilhouette.shirt => _shirt(),
      GarmentSilhouette.lehenga => _lehenga(),
      GarmentSilhouette.kaftan => _kaftan(),
    };

Path _neck(Path p, {double depth = 18, double half = 16}) {
  p.moveTo(100 - half, 30);
  p.quadraticBezierTo(100, 30 + depth * 2, 100 + half, 30);
  return p;
}

Path _sleeve({required bool left, required double length, double width = 22, double flare = 0}) {
  final dir = left ? -1.0 : 1.0;
  final sx = 100 + dir * 42;
  final p = Path()
    ..moveTo(sx, 36)
    ..lineTo(sx + dir * (10 + length * 0.22 + flare), 36 + length)
    ..lineTo(sx + dir * (10 + length * 0.22 + flare) - dir * (width + flare), 40 + length)
    ..lineTo(sx - dir * 8, 82)
    ..close();
  return p;
}

Path _bodice({double waistY = 110, double waistHalf = 30, double shoulderHalf = 42}) => Path()
  ..moveTo(100 - shoulderHalf, 36)
  ..lineTo(100 - 16, 30)
  ..quadraticBezierTo(100, 66, 100 + 16, 30)
  ..lineTo(100 + shoulderHalf, 36)
  ..quadraticBezierTo(100 + shoulderHalf - 4, 70, 100 + waistHalf, waistY)
  ..lineTo(100 - waistHalf, waistY)
  ..quadraticBezierTo(100 - shoulderHalf + 4, 70, 100 - shoulderHalf, 36)
  ..close();

Path _skirt({required double topY, required double topHalf, required double hemY, required double hemHalf, double curve = 10}) =>
    Path()
      ..moveTo(100 - topHalf, topY)
      ..lineTo(100 + topHalf, topY)
      ..quadraticBezierTo(100 + hemHalf - 6, (topY + hemY) / 2, 100 + hemHalf, hemY)
      ..quadraticBezierTo(100, hemY + curve, 100 - hemHalf, hemY)
      ..quadraticBezierTo(100 - hemHalf + 6, (topY + hemY) / 2, 100 - topHalf, topY)
      ..close();

Path _line(List<Offset> pts) {
  final p = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final o in pts.skip(1)) {
    p.lineTo(o.dx, o.dy);
  }
  return p;
}

GarmentShape _kurti() {
  final body = Path()
    ..moveTo(58, 36)
    ..lineTo(84, 30)
    ..quadraticBezierTo(100, 62, 116, 30)
    ..lineTo(142, 36)
    ..quadraticBezierTo(136, 80, 134, 110)
    ..lineTo(146, 250)
    ..quadraticBezierTo(100, 256, 54, 250)
    ..lineTo(66, 110)
    ..quadraticBezierTo(64, 80, 58, 36)
    ..close();
  return GarmentShape(
    panels: [body],
    shadedPanels: [_sleeve(left: true, length: 70), _sleeve(left: false, length: 70)],
    seams: [
      _neck(Path(), depth: 16),
      _line([const Offset(56, 200), const Offset(60, 250)]),
      _line([const Offset(144, 200), const Offset(140, 250)]),
      _line([const Offset(100, 62), const Offset(100, 92)]),
    ],
  );
}

GarmentShape _anarkali() => GarmentShape(
      panels: [
        _bodice(waistY: 100, waistHalf: 28),
        _skirt(topY: 100, topHalf: 28, hemY: 285, hemHalf: 92, curve: 14),
      ],
      shadedPanels: [_sleeve(left: true, length: 100, width: 18), _sleeve(left: false, length: 100, width: 18)],
      seams: [
        _line([const Offset(72, 100), const Offset(128, 100)]),
        for (var i = -3; i <= 3; i++) _line([Offset(100 + i * 7, 102), Offset(100 + i * 26, 282)]),
      ],
    );

GarmentShape _aLineDress() => GarmentShape(
      panels: [
        _bodice(waistY: 112, waistHalf: 30),
        _skirt(topY: 112, topHalf: 30, hemY: 225, hemHalf: 66, curve: 8),
      ],
      shadedPanels: [_sleeve(left: true, length: 26, width: 24), _sleeve(left: false, length: 26, width: 24)],
      seams: [
        _line([const Offset(70, 112), const Offset(130, 112)]),
        _line([const Offset(86, 114), const Offset(78, 224)]),
        _line([const Offset(114, 114), const Offset(122, 224)]),
      ],
    );

GarmentShape _maxiGown() {
  final bodice = Path()
    ..moveTo(70, 52)
    ..quadraticBezierTo(84, 40, 100, 54)
    ..quadraticBezierTo(116, 40, 130, 52)
    ..lineTo(128, 108)
    ..lineTo(72, 108)
    ..close();
  final straps = Path()
    ..addRect(const Rect.fromLTWH(74, 26, 5, 26))
    ..addRect(const Rect.fromLTWH(121, 26, 5, 26));
  return GarmentShape(
    panels: [bodice, _skirt(topY: 108, topHalf: 28, hemY: 288, hemHalf: 76, curve: 10)],
    shadedPanels: [straps],
    seams: [
      _line([const Offset(72, 108), const Offset(128, 108)]),
      _line([const Offset(100, 110), const Offset(100, 288)]),
      _line([const Offset(88, 110), const Offset(70, 286)]),
      _line([const Offset(112, 110), const Offset(130, 286)]),
    ],
  );
}

GarmentShape _peplum() => GarmentShape(
      panels: [
        _bodice(waistY: 128, waistHalf: 32),
        _skirt(topY: 128, topHalf: 32, hemY: 168, hemHalf: 58, curve: 10),
      ],
      shadedPanels: [_sleeve(left: true, length: 30, width: 24, flare: 6), _sleeve(left: false, length: 30, width: 24, flare: 6)],
      seams: [
        _line([const Offset(68, 128), const Offset(132, 128)]),
        _line([const Offset(84, 130), const Offset(70, 166)]),
        _line([const Offset(100, 130), const Offset(100, 172)]),
        _line([const Offset(116, 130), const Offset(130, 166)]),
      ],
    );

GarmentShape _shirt() {
  final body = Path()
    ..moveTo(58, 36)
    ..lineTo(86, 28)
    ..lineTo(100, 50)
    ..lineTo(114, 28)
    ..lineTo(142, 36)
    ..quadraticBezierTo(138, 90, 140, 196)
    ..quadraticBezierTo(100, 210, 60, 196)
    ..quadraticBezierTo(62, 90, 58, 36)
    ..close();
  final collar = Path()
    ..moveTo(86, 28)
    ..lineTo(100, 24)
    ..lineTo(114, 28)
    ..lineTo(108, 46)
    ..lineTo(100, 36)
    ..lineTo(92, 46)
    ..close();
  return GarmentShape(
    panels: [body],
    shadedPanels: [_sleeve(left: true, length: 110, width: 18), _sleeve(left: false, length: 110, width: 18), collar],
    seams: [
      _line([const Offset(100, 50), const Offset(100, 204)]),
      for (var y = 66.0; y < 200; y += 26) Path()..addOval(Rect.fromCircle(center: Offset(104, y), radius: 2)),
      _line([const Offset(68, 70), const Offset(88, 70), const Offset(88, 86), const Offset(68, 86)]),
    ],
  );
}

GarmentShape _lehenga() => GarmentShape(
      panels: [
        _bodice(waistY: 92, waistHalf: 30),
        _skirt(topY: 112, topHalf: 30, hemY: 290, hemHalf: 98, curve: 12),
      ],
      shadedPanels: [_sleeve(left: true, length: 30, width: 22), _sleeve(left: false, length: 30, width: 22)],
      seams: [
        _line([const Offset(70, 116), const Offset(130, 116)]),
        for (var i = -4; i <= 4; i++) _line([Offset(100 + i * 6, 118), Offset(100 + i * 21, 288)]),
        _line([const Offset(6, 276), const Offset(194, 276)]),
      ],
    );

GarmentShape _kaftan() {
  final body = Path()
    ..moveTo(84, 30)
    ..quadraticBezierTo(100, 50, 116, 30)
    ..lineTo(180, 60)
    ..lineTo(184, 130)
    ..quadraticBezierTo(150, 140, 136, 150)
    ..lineTo(138, 250)
    ..quadraticBezierTo(100, 258, 62, 250)
    ..lineTo(64, 150)
    ..quadraticBezierTo(50, 140, 16, 130)
    ..lineTo(20, 60)
    ..close();
  return GarmentShape(
    panels: [body],
    seams: [
      _line([const Offset(100, 40), const Offset(100, 72)]),
      _line([const Offset(70, 120), const Offset(130, 120)]),
      _line([const Offset(64, 150), const Offset(136, 150)]),
    ],
  );
}
