class AdjustmentRecord {
  const AdjustmentRecord({
    required this.effectiveFrom,
    required this.adjustmentDays,
    required this.revision,
    required this.publishedAt,
    this.effectiveTo,
    this.authority = 'kemenag_ri',
    this.regionScope = 'national',
  });

  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final int adjustmentDays;
  final int revision;
  final DateTime publishedAt;
  final String authority;
  final String regionScope;

  bool appliesTo(DateTime date) {
    final d = DateTime.utc(date.year, date.month, date.day);
    final from = DateTime.utc(
      effectiveFrom.year,
      effectiveFrom.month,
      effectiveFrom.day,
    );
    final toDate = effectiveTo == null
        ? from
        : DateTime.utc(effectiveTo!.year, effectiveTo!.month, effectiveTo!.day);
    return !d.isBefore(from) && !d.isAfter(toDate);
  }
}
