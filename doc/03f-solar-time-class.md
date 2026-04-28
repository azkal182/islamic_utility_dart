# 03f — SolarTime Class & Afternoon Shadow

Class `SolarTime` menggabungkan semua perhitungan astronomi menjadi satu objek per tanggal. Ini adalah class yang langsung digunakan oleh `PrayerTimes`.

## Constructor: `SolarTime(date, coordinates)`

```
Input:
  date = DateTime (hanya komponen year, month, day yang dipakai)
  coordinates = Coordinates(latitude, longitude)

Langkah:

1. julianDay = Astronomical.julianDay(date.year, date.month, date.day, 0)

2. Hitung SolarCoordinates untuk 3 hari:
   solar     = SolarCoordinates(julianDay)       ← hari target
   prevSolar = SolarCoordinates(julianDay - 1)   ← hari sebelumnya
   nextSolar = SolarCoordinates(julianDay + 1)   ← hari sesudahnya

3. Approximate transit:
   m₀ = approximateTransit(
     coordinates.longitude,
     solar.apparentSiderealTime,
     solar.rightAscension
   )

4. Solar altitude untuk sunrise/sunset:
   solarAltitude = -50.0 / 60.0  = -0.8333°

5. Transit (jam desimal UTC):
   transit = correctedTransit(
     m₀,
     coordinates.longitude,
     solar.apparentSiderealTime,
     solar.rightAscension,
     prevSolar.rightAscension,
     nextSolar.rightAscension
   )

6. Sunrise (jam desimal UTC):
   sunrise = correctedHourAngle(
     m₀, solarAltitude, coordinates,
     false,  ← sebelum transit
     solar.apparentSiderealTime,
     solar.rightAscension,
     prevSolar.rightAscension,
     nextSolar.rightAscension,
     solar.declination,
     prevSolar.declination,
     nextSolar.declination
   )

7. Sunset (jam desimal UTC):
   sunset = correctedHourAngle(
     m₀, solarAltitude, coordinates,
     true,   ← setelah transit
     ... (parameter sama dengan sunrise)
   )
```

## Fields

| Field | Tipe | Keterangan |
|---|---|---|
| `observer` | Coordinates | Koordinat observer |
| `solar` | SolarCoordinates | Data hari target |
| `prevSolar` | SolarCoordinates | Data hari sebelumnya |
| `nextSolar` | SolarCoordinates | Data hari sesudahnya |
| `approxTransit` | double? | Approximate transit (fraksi hari) |
| `transit` | double | Transit time (jam desimal UTC) |
| `sunrise` | double | Sunrise time (jam desimal UTC) |
| `sunset` | double | Sunset time (jam desimal UTC) |

---

## Method: `hourAngle(angle, afterTransit) → double`

Menghitung jam desimal UTC saat matahari mencapai altitude `angle`.

```
return correctedHourAngle(
  approxTransit,
  angle,
  observer,
  afterTransit,
  solar.apparentSiderealTime,
  solar.rightAscension,
  prevSolar.rightAscension,
  nextSolar.rightAscension,
  solar.declination,
  prevSolar.declination,
  nextSolar.declination
)
```

Digunakan untuk:
- **Fajr**: `hourAngle(-fajrAngle, false)` — sebelum transit, angle negatif
- **Isha**: `hourAngle(-ishaAngle, true)` — setelah transit, angle negatif
- **Maghrib angle-based**: `hourAngle(-maghribAngle, true)`

---

## Method: `afternoon(shadowLength) → double`

Menghitung waktu Asr berdasarkan panjang bayangan.

### Teori Shadow Length

Waktu Asr ditentukan saat panjang bayangan sebuah benda = panjang bayangan saat transit + (1× atau 2× panjang benda):
- **Shafi'i**: shadow = 1 × panjang benda + bayangan transit
- **Hanafi**: shadow = 2 × panjang benda + bayangan transit

### Algoritma

```
Input:
  shadowLength = 1 (Shafi) atau 2 (Hanafi), sebagai double

1. tangent = |observer.latitude - solar.declination|
   ← keduanya dalam DEGREES

2. inverse = shadowLength + tan(degreesToRadians(tangent))

3. angle = radiansToDegrees(atan(1.0 / inverse))

4. return hourAngle(angle, true)
```

> **KRITIS**: `solar.declination` di sini harus dalam **degrees** (dari pipeline Meeus). Jika menggunakan model Spencer yang return radian, hasilnya akan SALAH.

### Referensi Implementasi

```dart
double afternoon(double shadowLength) {
  double tangent = (observer.latitude - solar.declination!).abs();
  double inverse = shadowLength + tan(degreesToRadians(tangent));
  double angle = radiansToDegrees(atan(1.0 / inverse));
  return hourAngle(angle, true);
}
```

---

## Date Utilities yang Dibutuhkan

### `dateByAddingDays(date, days) → DateTime`
```dart
return date.add(Duration(days: days));
```

### `dateByAddingMinutes(date, minutes) → DateTime`
```dart
return dateByAddingSeconds(date, minutes * 60);
```

### `dateByAddingSeconds(date, seconds) → DateTime`
```dart
return date.add(Duration(seconds: seconds));
```

### `dayOfYear(date) → int`
```dart
Duration diff = date.difference(DateTime(date.year, 1, 1, 0, 0));
return diff.inDays + 1;
```

### `roundedMinute(date, {precision}) → DateTime`
```dart
int seconds = date.toUtc().second % 60;
int offset = seconds >= 30 ? 60 - seconds : -1 * seconds;
if (precision) return date;
return dateByAddingSeconds(date, offset);
```

> **Catatan**: Saat `precision = true`, waktu dikembalikan apa adanya (termasuk detik). Saat `precision = false`, dibulatkan ke menit terdekat.
