# 03d — Nutation & Obliquity

Nutation adalah gerakan osilasi kecil pada sumbu rotasi bumi yang disebabkan oleh gaya gravitasi bulan dan matahari. Koreksi ini diperlukan agar posisi apparent (tampak) matahari akurat.

## `nutationInLongitude(T, L₀, Lp, Ω) → Δψ`

**Halaman 144**. Nutation in longitude (koreksi pada longitude ekliptika).

```
Input:
  T  = Julian Century
  L₀ = mean solar longitude (degrees)
  Lp = mean lunar longitude (degrees)
  Ω  = ascending lunar node longitude (degrees)

term1 = (-17.2 / 3600) × sin(degreesToRadians(Ω))
term2 = ( 1.32 / 3600) × sin(2 × degreesToRadians(L₀))
term3 = ( 0.23 / 3600) × sin(2 × degreesToRadians(Lp))
term4 = ( 0.21 / 3600) × sin(2 × degreesToRadians(Ω))

Δψ = term1 - term2 - term3 + term4
```

> **Unit output**: degrees (sudut sangat kecil, ~±0.005°)

## `nutationInObliquity(T, L₀, Lp, Ω) → Δε`

**Halaman 144**. Nutation in obliquity (koreksi pada kemiringan ekliptika).

```
term1 = (9.2  / 3600) × cos(degreesToRadians(Ω))
term2 = (0.57 / 3600) × cos(2 × degreesToRadians(L₀))
term3 = (0.10 / 3600) × cos(2 × degreesToRadians(Lp))
term4 = (0.09 / 3600) × cos(2 × degreesToRadians(Ω))

Δε = term1 + term2 + term3 - term4
```

## Penggunaan dalam Pipeline

Kedua nilai nutation digunakan di `SolarCoordinates`:

1. **`Δψ`** → untuk menghitung `apparentSiderealTime`:
   ```
   apparentSiderealTime = θ₀ + ((Δψ × 3600 × cos(deg2rad(ε₀ + Δε))) / 3600)
   ```

2. **`Δε`** → digunakan bersama `ε₀` untuk koreksi obliquity:
   ```
   εCorrected = ε₀ + Δε
   ```
   Nilai `εCorrected` kemudian digunakan sebagai argumen `cos()` dalam koreksi sidereal time.

## Mengapa Ini Penting

Tanpa nutation correction:
- `apparentSiderealTime` bisa salah ~0.005° ≈ ~1.2 detik waktu sidereal
- Kumulatif dengan error lain, ini bisa menggeser waktu sholat hingga **30-60 detik**
- Efek lebih terasa pada Fajr dan Isha karena sudut hour angle yang besar

## Referensi Implementasi

```dart
static double nutationInLongitude(
    double T, double l0, double lp, double omega) {
  double term1 = (-17.2 / 3600) * sin(degreesToRadians(omega));
  double term2 = (1.32 / 3600) * sin(2 * degreesToRadians(l0));
  double term3 = (0.23 / 3600) * sin(2 * degreesToRadians(lp));
  double term4 = (0.21 / 3600) * sin(2 * degreesToRadians(omega));
  return term1 - term2 - term3 + term4;
}

static double nutationInObliquity(
    double T, double l0, double lp, double omega) {
  double term1 = (9.2 / 3600) * cos(degreesToRadians(omega));
  double term2 = (0.57 / 3600) * cos(2 * degreesToRadians(l0));
  double term3 = (0.10 / 3600) * cos(2 * degreesToRadians(lp));
  double term4 = (0.09 / 3600) * cos(2 * degreesToRadians(omega));
  return term1 + term2 + term3 - term4;
}
```
