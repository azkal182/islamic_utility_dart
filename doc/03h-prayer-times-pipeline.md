# 03h — PrayerTimes Pipeline (Detail Lengkap)

Dokumen ini menjelaskan urutan lengkap perhitungan di `PrayerTimes` constructor — dari input hingga output akhir. Setiap langkah harus diimplementasikan **persis** sesuai urutan ini untuk hasil identik.

## Input

| Parameter | Tipe | Keterangan |
|---|---|---|
| `date` | DateTime | Tanggal target (komponen year/month/day saja) |
| `coordinates` | Coordinates | latitude, longitude dalam degrees |
| `calculationParameters` | CalculationParameters | method, angles, adjustments |
| `precision` | bool | true = detik-level, false = bulatkan ke menit |

## Output

8 `DateTime` dalam UTC: `fajr`, `sunrise`, `dhuhr`, `asr`, `maghrib`, `isha`, `ishaBefore`, `fajrAfter`.

---

## Langkah-langkah

### Langkah 1: Siapkan 3 Hari

```
dateBefore = date - 1 hari
dateAfter  = date + 1 hari
```

### Langkah 2: Hitung SolarTime untuk 3 Hari

```
solarTime       = SolarTime(date, coordinates)
solarTimeBefore = SolarTime(dateBefore, coordinates)
solarTimeAfter  = SolarTime(dateAfter, coordinates)
```

Masing-masing menghitung `transit`, `sunrise`, `sunset` dalam **jam desimal UTC**.

### Langkah 3: Konversi Waktu Dasar ke DateTime

```
dhuhrTime   = TimeComponents(solarTime.transit).utcDate(year, month, day)
sunriseTime = TimeComponents(solarTime.sunrise).utcDate(year, month, day)
sunsetTime  = TimeComponents(solarTime.sunset).utcDate(year, month, day)

sunriseAfterTime  = TimeComponents(solarTimeAfter.sunrise)
                    .utcDate(dateAfter.year, dateAfter.month, dateAfter.day)
sunsetBeforeTime  = TimeComponents(solarTimeBefore.sunset)
                    .utcDate(dateBefore.year, dateBefore.month, dateBefore.day)
```

### Langkah 4: Hitung Asr

```
shadowLen = shadowLength(madhab)  // 1 untuk Shafi, 2 untuk Hanafi
asrTime = TimeComponents(solarTime.afternoon(shadowLen.toDouble()))
          .utcDate(year, month, day)
```

### Langkah 5: Hitung Night Duration

```
tomorrow = date + 1 hari
tomorrowSolarTime = SolarTime(tomorrow, coordinates)
tomorrowSunrise = TimeComponents(tomorrowSolarTime.sunrise)
                  .utcDate(tomorrow.year, tomorrow.month, tomorrow.day)

night = tomorrowSunrise - sunsetTime  (dalam detik)
```

### Langkah 6: Hitung Fajr

```
fajrTime = TimeComponents(
  solarTime.hourAngle(-1 × fajrAngle, false)
).utcDate(year, month, day)

fajrAfterTime = TimeComponents(
  solarTimeAfter.hourAngle(-1 × fajrAngle, false)
).utcDate(dateAfter.year, dateAfter.month, dateAfter.day)
```

#### Special case: Moonsighting Committee + latitude >= 55
```
if method == moonsightingCommittee AND latitude >= 55:
  nightFraction = night / 7
  fajrTime = sunriseTime - nightFraction
  fajrAfterTime = sunriseAfterTime - nightFraction
```

#### Safe Fajr (fallback)
```
safeFajr():
  if method == moonsightingCommittee:
    return seasonAdjustedMorningTwilight(lat, dayOfYear, year, sunriseTime)
  else:
    portion = nightPortions()[Prayer.fajr]
    nightFraction = portion × night
    return sunriseTime - nightFraction

if fajrTime is NaN OR safeFajr > fajrTime:
  fajrTime = safeFajr
```

> Logika yang sama berlaku untuk `fajrAfterTime`.

### Langkah 7: Hitung Isha

#### Jika ishaInterval > 0 (misal: Qatar, Umm Al-Qura)
```
ishaTime = sunsetTime + ishaInterval menit
ishaBeforeTime = sunsetBeforeTime + ishaInterval menit
```

#### Jika tidak (angle-based)
```
ishaTime = TimeComponents(
  solarTime.hourAngle(-1 × ishaAngle, true)
).utcDate(year, month, day)

ishaBeforeTime = TimeComponents(
  solarTimeBefore.hourAngle(-1 × ishaAngle, true)
).utcDate(dateBefore.year, dateBefore.month, dateBefore.day)
```

##### Special case: Moonsighting Committee + latitude >= 55
```
if method == moonsightingCommittee AND latitude >= 55:
  nightFraction = night / 7
  ishaTime = sunsetTime + nightFraction
  ishaBeforeTime = sunsetBeforeTime + nightFraction
```

##### Safe Isha (fallback)
```
safeIsha():
  if method == moonsightingCommittee:
    return seasonAdjustedEveningTwilight(lat, dayOfYear, year, sunsetTime, shafaq)
  else:
    portion = nightPortions()[Prayer.isha]
    nightFraction = portion × night
    return sunsetTime + nightFraction

if ishaTime is NaN OR safeIsha < ishaTime:
  ishaTime = safeIsha
```

> Logika yang sama berlaku untuk `ishaBeforeTime`.

### Langkah 8: Hitung Maghrib

```
maghribTime = sunsetTime  (default)

if maghribAngle != null:
  angleBasedMaghrib = TimeComponents(
    solarTime.hourAngle(-1 × maghribAngle, true)
  ).utcDate(year, month, day)

  if sunsetTime < angleBasedMaghrib AND ishaTime > angleBasedMaghrib:
    maghribTime = angleBasedMaghrib
```

### Langkah 9: Terapkan Adjustments

Untuk setiap waktu sholat:
```
totalAdjustment = adjustments[prayer] + methodAdjustments[prayer]
```

```
fajr    = roundedMinute(fajrTime    + fajrAdj,    precision)
sunrise = roundedMinute(sunriseTime + sunriseAdj, precision)
dhuhr   = roundedMinute(dhuhrTime   + dhuhrAdj,   precision)
asr     = roundedMinute(asrTime     + asrAdj,     precision)
maghrib = roundedMinute(maghribTime + maghribAdj, precision)
isha    = roundedMinute(ishaTime    + ishaAdj,    precision)

fajrAfter  = roundedMinute(fajrAfterTime  + fajrAdj, precision)
ishaBefore = roundedMinute(ishaBeforeTime + ishaAdj, precision)
```

---

## Night Portions (High Latitude Rules)

```
nightPortions():
  switch highLatitudeRule:
    middleOfTheNight:
      fajr = 1/2, isha = 1/2
    seventhOfTheNight:
      fajr = 1/7, isha = 1/7
    twilightAngle:
      fajr = fajrAngle/60, isha = ishaAngle/60
```

---

## Diagram Alur Lengkap

```
                    ┌─────────────┐
                    │   Input     │
                    │ date, coords│
                    │ params      │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        SolarTime      SolarTime    SolarTime
        (before)       (target)     (after)
              │            │            │
              │     ┌──────┴──────┐     │
              │     │             │     │
              │  transit  sunrise/sunset│
              │     │             │     │
              │     ▼             ▼     │
              │   dhuhr     sunset→maghrib
              │              │         │
              │          nightDuration  │
              │              │         │
              ├──────────────┼─────────┤
              │              │         │
     hourAngle(-fajr)    afternoon  hourAngle(-isha)
              │              │         │
              ▼              ▼         ▼
         fajrTime        asrTime   ishaTime
              │              │         │
              ├── safeFajr   │    safeIsha ──┤
              │              │         │
              ▼              ▼         ▼
         + adjustments  + adjustments  + adjustments
              │              │         │
              ▼              ▼         ▼
         roundedMinute  roundedMinute  roundedMinute
              │              │         │
              ▼              ▼         ▼
           fajr            asr       isha
```

---

## Kontrak Kritis

1. **Urutan operasi**: astronomi → fallback → adjustment → rounding. Jangan ubah.
2. **Semua waktu internal dalam UTC**. Konversi timezone adalah tanggung jawab caller.
3. **`hourAngle()` menerima angle negatif** untuk fajr/isha (`-1 × fajrAngle`).
4. **`afternoon()` menerima shadowLength sebagai double** (1.0 atau 2.0).
5. **`TimeComponents` mengkonversi jam desimal ke DateTime**. Ini adalah bridge antara SolarTime (jam desimal) dan PrayerTimes (DateTime).
6. **Safe fajr/isha**: fajr tidak boleh lebih awal dari safe limit, isha tidak boleh lebih lambat dari safe limit.
