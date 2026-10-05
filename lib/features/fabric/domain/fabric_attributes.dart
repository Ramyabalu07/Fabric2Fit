enum ColorFamily {
  red('Red'),
  pink('Pink'),
  orange('Orange'),
  yellow('Yellow'),
  green('Green'),
  blue('Blue'),
  purple('Purple'),
  brown('Brown'),
  beige('Beige'),
  white('White'),
  black('Black'),
  grey('Grey'),
  multicolor('Multicolor');

  const ColorFamily(this.label);
  final String label;
}

enum FabricPattern {
  solid('Solid'),
  floral('Floral'),
  geometric('Geometric'),
  stripes('Stripes'),
  checks('Checks'),
  polka('Polka dots'),
  abstract('Abstract'),
  ethnic('Ethnic print');

  const FabricPattern(this.label);
  final String label;
}

enum FabricTexture {
  smooth('Smooth'),
  textured('Textured'),
  sheer('Sheer'),
  heavy('Heavy');

  const FabricTexture(this.label);
  final String label;
}

enum FabricType {
  cotton('Cotton'),
  silk('Silk'),
  linen('Linen'),
  georgette('Georgette'),
  chiffon('Chiffon'),
  rayon('Rayon'),
  crepe('Crepe'),
  velvet('Velvet'),
  denim('Denim'),
  brocade('Brocade');

  const FabricType(this.label);
  final String label;
}

enum Occasion {
  casual('Casual'),
  office('Office'),
  festive('Festive'),
  wedding('Wedding'),
  party('Party');

  const Occasion(this.label);
  final String label;
}

enum GarmentCategory {
  ethnic('Ethnic'),
  western('Western'),
  fusion('Fusion');

  const GarmentCategory(this.label);
  final String label;
}

enum StyleTag {
  classic('Classic'),
  modern('Modern'),
  boho('Boho'),
  minimal('Minimal'),
  elegant('Elegant');

  const StyleTag(this.label);
  final String label;
}

T enumByName<T extends Enum>(List<T> values, String? name, T fallback) =>
    values.firstWhere((v) => v.name == name, orElse: () => fallback);

Set<T> enumSetByNames<T extends Enum>(List<T> values, Iterable<dynamic>? names) =>
    {
      for (final n in names ?? const [])
        ...values.where((v) => v.name == n),
    };
