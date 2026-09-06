class HijriResultMeta {
  const HijriResultMeta({
    required this.source,
    this.isAdjusted = false,
    this.adjustmentDays = 0,
    this.isProvisional = false,
    this.anchorDate,
    this.nextAnchorDate,
    this.authority,
    this.revision,
  });

  final String source;
  final bool isAdjusted;
  final int adjustmentDays;
  final bool isProvisional;
  final DateTime? anchorDate;
  final DateTime? nextAnchorDate;
  final String? authority;
  final int? revision;
}
