class HijriAnchorRecord {
  const HijriAnchorRecord({
    required this.officialGregorianDate,
    required this.hijriYear,
    required this.hijriMonth,
    this.hijriDay = 1,
    required this.revision,
    required this.publishedAt,
    this.authority = 'kemenag_ri',
    this.regionScope = 'national',
    this.notes,
  }) : assert(hijriDay == 1);

  final DateTime officialGregorianDate;
  final int hijriYear;
  final int hijriMonth;
  final int hijriDay;
  final int revision;
  final DateTime publishedAt;
  final String authority;
  final String regionScope;
  final String? notes;
}
