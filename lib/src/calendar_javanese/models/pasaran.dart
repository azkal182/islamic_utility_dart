enum Pasaran {
  legi,
  pahing,
  pon,
  wage,
  kliwon;

  String get label {
    switch (this) {
      case Pasaran.legi:
        return 'Legi';
      case Pasaran.pahing:
        return 'Pahing';
      case Pasaran.pon:
        return 'Pon';
      case Pasaran.wage:
        return 'Wage';
      case Pasaran.kliwon:
        return 'Kliwon';
    }
  }
}
