# 03b — Julian Date Utilities

Julian Date adalah sistem penanggalan kontinu yang digunakan dalam astronomi. Semua perhitungan posisi matahari dimulai dari sini.

## `julianDay(year, month, day, hours) → double`

Mengkonversi tanggal Gregorian ke Julian Day Number.

**Sumber**: Astronomical Algorithms, halaman 60.

### Algoritma

```
Input: year (int), month (int), day (int), hours (double, default 0)

1. Jika month <= 2:
     Y = year - 1
     M = month + 12
   Jika tidak:
     Y = year
     M = month

2. D = day + (hours / 24)

3. A = truncate(Y / 100)

4. B = 2 - A + truncate(A / 4)

5. i0 = truncate(365.25 × (Y + 4716))

6. i1 = truncate(30.6001 × (M + 1))

7. JD = i0 + i1 + D + B - 1524.5
```

> **PENTING**: `truncate` di sini berarti pembulatan ke arah nol (bukan floor). Untuk bilangan positif hasilnya sama dengan floor, tapi untuk negatif berbeda.

### Contoh Verifikasi

| Input | Julian Day |
|---|---|
| 2000-01-01 12:00 | 2451545.0 |
| 2026-04-28 00:00 | 2461492.5 |
| 1999-12-31 00:00 | 2451543.5 |

### Referensi Implementasi

```dart
static double julianDay(int year, int month, int day, double? hours) {
  hours ??= 0;
  trunc(val) => val.truncate();

  int Y = trunc(month > 2 ? year : year - 1);
  int M = trunc(month > 2 ? month : month + 12);
  double D = day + (hours / 24);

  int A = trunc(Y / 100);
  int B = trunc(2 - A + trunc(A / 4));

  int i0 = trunc(365.25 * (Y + 4716));
  int i1 = trunc(30.6001 * (M + 1));

  return i0 + i1 + D + B - 1524.5;
}
```

---

## `julianCentury(julianDay) → double`

Mengkonversi Julian Day ke Julian Century relatif terhadap epoch J2000.0.

**Sumber**: Astronomical Algorithms, halaman 163.

```
T = (JD - 2451545.0) / 36525
```

- `2451545.0` = Julian Day untuk 1 Januari 2000, 12:00 UT (epoch J2000.0)
- `36525` = jumlah hari dalam satu Julian Century

### Contoh

| Julian Day | Julian Century (T) |
|---|---|
| 2451545.0 | 0.0 |
| 2451545.0 + 36525 | 1.0 |
| 2461492.5 | ≈ 0.2633 |

---

## `TimeComponents(number: double)`

Mengkonversi jam desimal UTC ke komponen jam-menit-detik.

```
Input: number = jam desimal (misal: 12.5088)

hours   = floor(number)                           → 12
minutes = floor((number - hours) × 60)            → 30
seconds = floor((number - hours - minutes/60) × 3600) → 31
```

### Method: `utcDate(year, month, day) → DateTime`

```
return DateTime.utc(year, month, day, hours, minutes, seconds)
```

### Referensi Implementasi

```dart
class TimeComponents {
  late int hours;
  late int minutes;
  late int seconds;

  TimeComponents(double number) {
    hours = (number).floor();
    minutes = ((number - hours) * 60).floor();
    seconds = ((number - (hours + minutes / 60)) * 60 * 60).floor();
  }

  DateTime utcDate(int year, int month, int date) {
    return DateTime.utc(year, month, date, hours, minutes, seconds);
  }
}
```

> **PENTING**: Output dari `SolarTime.transit`, `SolarTime.sunrise`, `SolarTime.sunset`, dan `SolarTime.hourAngle()` adalah dalam **jam desimal UTC**. Semua harus melalui `TimeComponents` untuk dikonversi ke `DateTime`.
