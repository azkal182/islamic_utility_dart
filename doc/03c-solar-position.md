# 03c — Solar Position Pipeline

Dokumen ini menjelaskan pipeline lengkap untuk menghitung posisi matahari. Pipeline ini menghasilkan **declination**, **right ascension**, dan **apparent sidereal time** yang menjadi input utama perhitungan transit dan hour angle.

## Overview Pipeline

```
Julian Day (JD)
    │
    ▼
Julian Century (T)
    │
    ├──► meanSolarLongitude(T)         → L₀
    ├──► meanSolarAnomaly(T)           → M
    ├──► meanLunarLongitude(T)         → Lp
    ├──► ascendingLunarNodeLongitude(T) → Ω
    │
    ▼
solarEquationOfTheCenter(T, M)         → C
    │
    ▼
apparentSolarLongitude(T, L₀)          → λ  (menggunakan C & Ω)
    │
    ├──► nutationInLongitude(T, L₀, Lp, Ω)      → Δψ
    ├──► nutationInObliquity(T, L₀, Lp, Ω)      → Δε
    ├──► meanObliquityOfTheEcliptic(T)            → ε₀
    ├──► apparentObliquityOfTheEcliptic(T, ε₀)   → ε (apparent)
    ├──► meanSiderealTime(T)                      → θ₀
    │
    ▼
SolarCoordinates:
    declination      = asin(sin(ε) × sin(λ))
    rightAscension   = unwindAngle(atan2(cos(ε) × sin(λ), cos(λ)))
    apparentSiderealTime = θ₀ + ((Δψ × 3600 × cos(ε₀ + Δε)) / 3600)
```

---

## Fungsi Detail

### 1. `meanSolarLongitude(T) → L₀`

**Halaman 163**. Geometric mean longitude of the sun.

```
L₀ = 280.4664567 + 36000.76983 × T + 0.0003032 × T²
return unwindAngle(L₀)
```

### 2. `meanLunarLongitude(T) → Lp`

**Halaman 144**. Geometric mean longitude of the moon.

```
Lp = 218.3165 + 481267.8813 × T
return unwindAngle(Lp)
```

### 3. `ascendingLunarNodeLongitude(T) → Ω`

**Halaman 144**. Longitude of the ascending node of the moon.

```
Ω = 125.04452 - 1934.136261 × T + 0.0020708 × T² + T³ / 450000
return unwindAngle(Ω)
```

### 4. `meanSolarAnomaly(T) → M`

**Halaman 163**. Mean anomaly of the sun.

```
M = 357.52911 + 35999.05029 × T - 0.0001537 × T²
return unwindAngle(M)
```

### 5. `solarEquationOfTheCenter(T, M) → C`

**Halaman 164**. Koreksi posisi matahari akibat orbit elips.

```
Mrad = degreesToRadians(M)

term1 = (1.914602 - 0.004817 × T - 0.000014 × T²) × sin(Mrad)
term2 = (0.019993 - 0.000101 × T) × sin(2 × Mrad)
term3 = 0.000289 × sin(3 × Mrad)

C = term1 + term2 + term3
```

### 6. `apparentSolarLongitude(T, L₀) → λ`

**Halaman 164**. Apparent longitude of the sun (true equinox of the date).

```
longitude = L₀ + solarEquationOfTheCenter(T, meanSolarAnomaly(T))
Ω = 125.04 - 1934.136 × T
λ = longitude - 0.00569 - 0.00478 × sin(degreesToRadians(Ω))
return unwindAngle(λ)
```

> **Catatan**: Ini menggunakan versi sederhana dari Ω (bukan fungsi `ascendingLunarNodeLongitude`), yang cukup akurat untuk koreksi apparent longitude.

### 7. `meanObliquityOfTheEcliptic(T) → ε₀`

**Halaman 147**. Mean obliquity of the ecliptic.

```
ε₀ = 23.439291 - 0.013004167 × T - 0.0000001639 × T² + 0.0000005036 × T³
```

### 8. `apparentObliquityOfTheEcliptic(T, ε₀) → ε`

**Halaman 165**. Corrected obliquity for apparent sun position.

```
O = 125.04 - 1934.136 × T
ε = ε₀ + 0.00256 × cos(degreesToRadians(O))
```

### 9. `meanSiderealTime(T) → θ₀`

**Halaman 165**. Mean sidereal time (hour angle of the vernal equinox).

```
JD = (T × 36525) + 2451545.0

θ₀ = 280.46061837
   + 360.98564736629 × (JD - 2451545)
   + 0.000387933 × T²
   - T³ / 38710000

return unwindAngle(θ₀)
```

---

## `SolarCoordinates` — Menggabungkan Semuanya

Class ini dihitung **per Julian Day** — yaitu, untuk hari target, hari sebelumnya, dan hari sesudahnya (total 3 instance).

```
Input: julianDay (double)

1. T = julianCentury(julianDay)

2. L₀ = meanSolarLongitude(T)
   Lp = meanLunarLongitude(T)
   Ω  = ascendingLunarNodeLongitude(T)

3. λ (radian) = degreesToRadians(apparentSolarLongitude(T, L₀))

4. θ₀ = meanSiderealTime(T)

5. Δψ = nutationInLongitude(T, L₀, Lp, Ω)
   Δε = nutationInObliquity(T, L₀, Lp, Ω)

6. ε₀ = meanObliquityOfTheEcliptic(T)
   εApparent (radian) = degreesToRadians(apparentObliquityOfTheEcliptic(T, ε₀))

7. declination = radiansToDegrees(asin(sin(εApparent) × sin(λ)))

8. rightAscension = unwindAngle(radiansToDegrees(atan2(cos(εApparent) × sin(λ), cos(λ))))

9. apparentSiderealTime = θ₀ + ((Δψ × 3600 × cos(degreesToRadians(ε₀ + Δε))) / 3600)
```

### Output

| Field | Unit | Keterangan |
|---|---|---|
| `declination` | degrees | Sudut antara sinar matahari dan bidang ekuator bumi |
| `rightAscension` | degrees (0–360) | Jarak angular pada equator celestial dari vernal equinox |
| `apparentSiderealTime` | degrees | Hour angle vernal equinox, dikoreksi nutation |

### Referensi Implementasi

```dart
class SolarCoordinates {
  double? declination;
  double? rightAscension;
  late double apparentSiderealTime;

  SolarCoordinates(double julianDay) {
    double T = Astronomical.julianCentury(julianDay);
    double l0 = Astronomical.meanSolarLongitude(T);
    double lp = Astronomical.meanLunarLongitude(T);
    double omega = Astronomical.ascendingLunarNodeLongitude(T);
    double lambda = degreesToRadians(
        Astronomical.apparentSolarLongitude(T, l0));
    double theta0 = Astronomical.meanSiderealTime(T);
    double dPsi = Astronomical.nutationInLongitude(T, l0, lp, omega);
    double dEpsilon = Astronomical.nutationInObliquity(T, l0, lp, omega);
    double epsilon0 = Astronomical.meanObliquityOfTheEcliptic(T);
    double epsilonApparent = degreesToRadians(
        Astronomical.apparentObliquityOfTheEcliptic(T, epsilon0));

    declination = radiansToDegrees(
        asin(sin(epsilonApparent) * sin(lambda)));
    rightAscension = unwindAngle(radiansToDegrees(
        atan2(cos(epsilonApparent) * sin(lambda), cos(lambda))));
    apparentSiderealTime = theta0 +
        (((dPsi * 3600) * cos(degreesToRadians(epsilon0 + dEpsilon))) / 3600);
  }
}
```
