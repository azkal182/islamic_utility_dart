class HijriResultMeta {
  const HijriResultMeta({
    required this.source,
    this.isAdjusted = false,
    this.adjustmentDays = 0,
    this.authority,
    this.revision,
  });

  final String source;
  final bool isAdjusted;
  final int adjustmentDays;
  final String? authority;
  final int? revision;
}
