# 03g — Seasonal Adjustment (Moonsighting Committee)

Metode Moonsighting Committee menggunakan **season-adjusted twilight** sebagai fallback untuk Fajr dan Isha, terutama di latitude tinggi di mana twilight berbasis sudut bisa menghasilkan waktu yang tidak wajar.

## `daysSinceSolstice(dayOfYear, year, latitude) → int`

Menghitung jumlah hari sejak solstice terdekat.

```
Input:
  dayOfYear = hari ke-N dalam tahun (1-365/366)
  year      = tahun (untuk menentukan leap year)
  latitude  = latitude observer (degrees)

northernOffset = 10
southernOffset = 173 (atau 172 jika bukan leap year... SALAH)
                 → sebenarnya: 173 jika leap year, 172 jika bukan
daysInYear     = 366 jika leap year, 365 jika bukan

Jika latitude >= 0 (belahan utara):
  daysSinceSolstice = dayOfYear + northernOffset
  Jika daysSinceSolstice >= daysInYear:
    daysSinceSolstice -= daysInYear

Jika latitude < 0 (belahan selatan):
  daysSinceSolstice = dayOfYear - southernOffset
  Jika daysSinceSolstice < 0:
    daysSinceSolstice += daysInYear
```

> **Catatan**: Belahan utara menggunakan offset dari winter solstice (~21 Desember, hari ke-355 + 10 = 365 → wrap ke 0). Belahan selatan menggunakan offset dari summer solstice (~22 Juni, hari ke-173).

---

## `seasonAdjustedMorningTwilight(latitude, dayOfYear, year, sunrise) → DateTime`

Menghitung waktu Fajr berdasarkan penyesuaian musiman.

```
Input:
  latitude  = degrees (diambil nilai absolut)
  dayOfYear = hari ke-N
  year      = tahun
  sunrise   = DateTime sunrise hari itu

1. Hitung koefisien berdasarkan latitude:
   a = 75 + (28.65 / 55.0) × |latitude|
   b = 75 + (19.44 / 55.0) × |latitude|
   c = 75 + (32.74 / 55.0) × |latitude|
   d = 75 + (48.10 / 55.0) × |latitude|

2. Hitung hari sejak solstice:
   dyy = daysSinceSolstice(dayOfYear, year, latitude)

3. Hitung adjustment (menit):
   Jika dyy < 91:
     adj = a + (b - a) / 91.0 × dyy
   Jika dyy < 137:
     adj = b + (c - b) / 46.0 × (dyy - 91)
   Jika dyy < 183:
     adj = c + (d - c) / 46.0 × (dyy - 137)
   Jika dyy < 229:
     adj = d + (c - d) / 46.0 × (dyy - 183)
   Jika dyy < 275:
     adj = c + (b - c) / 46.0 × (dyy - 229)
   Jika tidak:
     adj = b + (a - b) / 91.0 × (dyy - 275)

4. return dateByAddingSeconds(sunrise, round(adj × -60.0))
```

> Adjustment adalah jumlah menit **sebelum** sunrise (karena dikali -60).

---

## `seasonAdjustedEveningTwilight(latitude, dayOfYear, year, sunset, {shafaq}) → DateTime`

Menghitung waktu Isha berdasarkan penyesuaian musiman. Koefisien bergantung pada parameter `Shafaq`.

```
Input:
  latitude  = degrees
  dayOfYear = hari ke-N
  year      = tahun
  sunset    = DateTime sunset hari itu
  shafaq    = Shafaq.general (default) | Shafaq.ahmer | Shafaq.abyad

1. Hitung koefisien berdasarkan shafaq DAN latitude:

   Jika shafaq == ahmer:
     a = 62 + (17.4  / 55.0) × |latitude|
     b = 62 - ( 7.16 / 55.0) × |latitude|
     c = 62 + ( 5.12 / 55.0) × |latitude|
     d = 62 + (19.44 / 55.0) × |latitude|

   Jika shafaq == abyad:
     a = 75 + (25.60 / 55.0) × |latitude|
     b = 75 + ( 7.16 / 55.0) × |latitude|
     c = 75 + (36.84 / 55.0) × |latitude|
     d = 75 + (81.84 / 55.0) × |latitude|

   Jika shafaq == general (default):
     a = 75 + (25.60 / 55.0) × |latitude|
     b = 75 + ( 2.050 / 55.0) × |latitude|
     c = 75 - ( 9.210 / 55.0) × |latitude|
     d = 75 + ( 6.140 / 55.0) × |latitude|

2. Hitung adjustment dengan formula seasonal yang SAMA (6 segmen, sama dengan morning twilight)

3. return dateByAddingSeconds(sunset, round(adj × 60.0))
```

> Adjustment adalah jumlah menit **setelah** sunset (dikali +60).

---

## Kapan Seasonal Adjustment Digunakan

Dalam `PrayerTimes`, seasonal adjustment **hanya** digunakan oleh metode `moonsightingCommittee`:

### Untuk Fajr (sebagai `safeFajr()`)
```
if method == moonsightingCommittee:
  safeFajr = seasonAdjustedMorningTwilight(lat, dayOfYear, year, sunrise)
else:
  portion = nightPortions()[Prayer.fajr]
  safeFajr = sunrise - (portion × nightDuration)
```

### Untuk Isha (sebagai `safeIsha()`)
```
if method == moonsightingCommittee:
  safeIsha = seasonAdjustedEveningTwilight(lat, dayOfYear, year, sunset, shafaq)
else:
  portion = nightPortions()[Prayer.isha]
  safeIsha = sunset + (portion × nightDuration)
```

### Latitude >= 55 (Moonsighting Committee special case)
```
if method == moonsightingCommittee AND latitude >= 55:
  nightFraction = nightDuration / 7
  fajr  = sunrise - nightFraction
  isha  = sunset + nightFraction
```

---

## Referensi Implementasi

```dart
static DateTime seasonAdjustedMorningTwilight(
    double latitude, int dayOfYear, int year, DateTime sunrise) {
  double a = 75 + ((28.65 / 55.0) * (latitude).abs());
  double b = 75 + ((19.44 / 55.0) * (latitude).abs());
  double c = 75 + ((32.74 / 55.0) * (latitude).abs());
  double d = 75 + ((48.10 / 55.0) * (latitude).abs());

  double adjustment() {
    int dyy = daysSinceSolstice(dayOfYear, year, latitude);
    if (dyy < 91)  return a + (b - a) / 91.0 * dyy;
    if (dyy < 137) return b + (c - b) / 46.0 * (dyy - 91);
    if (dyy < 183) return c + (d - c) / 46.0 * (dyy - 137);
    if (dyy < 229) return d + (c - d) / 46.0 * (dyy - 183);
    if (dyy < 275) return c + (b - c) / 46.0 * (dyy - 229);
    return b + (a - b) / 91.0 * (dyy - 275);
  }

  return dateByAddingSeconds(sunrise, (adjustment() * -60.0).round());
}

static DateTime seasonAdjustedEveningTwilight(
    double latitude, int dayOfYear, int year, DateTime sunset,
    {Shafaq shafaq = Shafaq.general}) {
  double a, b, c, d;

  if (shafaq == Shafaq.ahmer) {
    a = 62 + ((17.4 / 55.0) * (latitude).abs());
    b = 62 - ((7.16 / 55.0) * (latitude).abs());
    c = 62 + ((5.12 / 55.0) * (latitude).abs());
    d = 62 + ((19.44 / 55.0) * (latitude).abs());
  } else if (shafaq == Shafaq.abyad) {
    a = 75 + ((25.60 / 55.0) * (latitude).abs());
    b = 75 + ((7.16 / 55.0) * (latitude).abs());
    c = 75 + ((36.84 / 55.0) * (latitude).abs());
    d = 75 + ((81.84 / 55.0) * (latitude).abs());
  } else {
    a = 75 + ((25.60 / 55.0) * (latitude).abs());
    b = 75 + ((2.050 / 55.0) * (latitude).abs());
    c = 75 - ((9.210 / 55.0) * (latitude).abs());
    d = 75 + ((6.140 / 55.0) * (latitude).abs());
  }

  double adjustment() {
    int dyy = daysSinceSolstice(dayOfYear, year, latitude);
    if (dyy < 91)  return a + (b - a) / 91.0 * dyy;
    if (dyy < 137) return b + (c - b) / 46.0 * (dyy - 91);
    if (dyy < 183) return c + (d - c) / 46.0 * (dyy - 137);
    if (dyy < 229) return d + (c - d) / 46.0 * (dyy - 183);
    if (dyy < 275) return c + (b - c) / 46.0 * (dyy - 229);
    return b + (a - b) / 91.0 * (dyy - 275);
  }

  return dateByAddingSeconds(sunset, (adjustment() * 60.0).round());
}
```
