# 03e — Transit & Hour Angle

Dokumen ini menjelaskan algoritma untuk menghitung **transit** (kulminasi matahari / dhuhr), **sunrise/sunset**, dan **hour angle** untuk sudut arbitrary (fajr, isha, asr).

Semua fungsi ini berasal dari **Astronomical Algorithms halaman 102**.

## Konsep Kunci

- **Transit (m₀)**: saat matahari berada di titik tertinggi (meridian passage). Ini menentukan waktu Dhuhr.
- **Hour Angle (H)**: sudut antara matahari dan meridian lokal. Digunakan untuk menghitung kapan matahari mencapai altitude tertentu (sunrise/sunset/fajr/isha).
- **Interpolasi 3-hari**: menggunakan data dari hari sebelumnya, hari ini, dan hari sesudahnya untuk koreksi iteratif.

---

## `altitudeOfCelestialBody(φ, δ, H) → altitude`

**Halaman 93**. Altitude (ketinggian) benda langit di atas horizon.

```
Input:
  φ = observer latitude (degrees)
  δ = declination (degrees)
  H = local hour angle (degrees)

altitude = radiansToDegrees(
  asin(
    sin(deg2rad(φ)) × sin(deg2rad(δ)) +
    cos(deg2rad(φ)) × cos(deg2rad(δ)) × cos(deg2rad(H))
  )
)
```

---

## `approximateTransit(L, θ₀, α₂) → m₀`

**Halaman 102**. Approximate transit time sebagai fraksi hari.

```
Input:
  L  = longitude observer (degrees)
  θ₀ = apparent sidereal time at Greenwich (degrees)
  α₂ = right ascension hari target (degrees)

Lw = -L  (note: longitude barat = positif dalam konvensi ini)

m₀ = normalizeToScale((α₂ + Lw - θ₀) / 360, 1)
```

Output: fraksi hari (0.0 – 1.0), misalnya 0.5 = tengah hari UTC.

---

## `correctedTransit(m₀, L, θ₀, α₂, α₁, α₃) → jam desimal UTC`

**Halaman 102**. Koreksi transit menggunakan interpolasi 3-hari.

```
Input:
  m₀ = approximate transit (fraksi hari)
  L  = longitude observer (degrees)
  θ₀ = apparent sidereal time (degrees)
  α₂ = right ascension hari target (degrees)
  α₁ = right ascension hari sebelumnya (degrees, nullable)
  α₃ = right ascension hari sesudahnya (degrees)

Lw = -L

1. θ  = unwindAngle(θ₀ + 360.985647 × m₀)

2. α  = unwindAngle(interpolateAngles(α₂, α₁, α₃, m₀))

3. H  = quadrantShiftAngle(θ - Lw - α)

4. Δm = H / -360

5. return (m₀ + Δm) × 24
```

Output: **jam desimal UTC** (misalnya 12.084 = 12:05:02 UTC).

---

## `correctedHourAngle(...) → jam desimal UTC`

**Halaman 102**. Ini adalah fungsi **paling kritis** — menghitung kapan matahari mencapai altitude tertentu (untuk sunrise, sunset, fajr, isha).

```
Input:
  m₀   = approximate transit (fraksi hari)
  h₀   = target altitude / angle (degrees)
         → sunrise/sunset: -50/60 = -0.8333°
         → fajr: -fajrAngle (negatif, misal -18°)
         → isha: -ishaAngle (negatif, misal -17°)
  coordinates = {latitude, longitude}
  afterTransit = true untuk sunset/isha, false untuk sunrise/fajr
  θ₀   = apparent sidereal time (degrees)
  α₂   = right ascension hari target (degrees)
  α₁   = right ascension hari sebelumnya (degrees, nullable)
  α₃   = right ascension hari sesudahnya (degrees)
  δ₂   = declination hari target (degrees)
  δ₁   = declination hari sebelumnya (degrees, nullable)
  δ₃   = declination hari sesudahnya (degrees)

Algoritma:

1. Lw = -coordinates.longitude

2. Hitung cosH₀ untuk approximate hour angle:
   term1 = sin(deg2rad(h₀)) - sin(deg2rad(lat)) × sin(deg2rad(δ₂))
   term2 = cos(deg2rad(lat)) × cos(deg2rad(δ₂))

   Jika |term1/term2| > 1:
     H₀ = 1.0  (clamp — matahari tidak pernah mencapai altitude h₀)
   Jika tidak:
     H₀ = radiansToDegrees(acos(term1 / term2))

3. Hitung approximate time:
   Jika afterTransit:
     m = m₀ + H₀ / 360
   Jika tidak:
     m = m₀ - H₀ / 360

4. Hitung corrected sidereal time:
   θ = unwindAngle(θ₀ + 360.985647 × m)

5. Interpolasi right ascension:
   α = unwindAngle(interpolateAngles(α₂, α₁, α₃, m))

6. Interpolasi declination:
   δ = interpolate(δ₂, δ₁, δ₃, m)

7. Hitung local hour angle:
   H = θ - Lw - α

8. Hitung actual altitude:
   h = altitudeOfCelestialBody(latitude, δ, H)

9. Koreksi:
   term3 = h - h₀
   term4 = 360 × cos(deg2rad(δ)) × cos(deg2rad(lat)) × sin(deg2rad(H))
   Δm = term3 / term4

10. return (m + Δm) × 24
```

Output: **jam desimal UTC**.

---

## Interpolation Functions

### `interpolate(y₂, y₁, y₃, n) → double`

**Halaman 24**. Interpolasi standar untuk nilai (bukan sudut).

```
a = y₂ - y₁     (y₁ nullable, default 0)
b = y₃ - y₂
c = b - a

return y₂ + (n/2) × (a + b + n × c)
```

Digunakan untuk interpolasi **declination**.

### `interpolateAngles(y₂, y₁, y₃, n) → double`

**Halaman 24**. Interpolasi untuk sudut (dengan unwinding untuk menghindari wrap-around 360°).

```
a = unwindAngle(y₂ - y₁)    (y₁ nullable, default 0)
b = unwindAngle(y₃ - y₂)
c = b - a

return y₂ + (n/2) × (a + b + n × c)
```

Digunakan untuk interpolasi **right ascension**.

---

## Konstanta Penting

| Konstanta | Nilai | Digunakan Untuk |
|---|---|---|
| Solar altitude sunrise/sunset | `-50/60` = `-0.8333°` | Memperhitungkan refraksi atmosfer (~34') + semi-diameter matahari (~16') |
| Sidereal rate | `360.985647` °/hari | Faktor koreksi sidereal time terhadap waktu sipil |

---

## Referensi Implementasi

```dart
static double approximateTransit(double L, double theta0, double a2) {
  double lw = L * -1;
  return normalizeToScale((a2 + lw - theta0) / 360, 1);
}

static double correctedTransit(double m0, double L, double theta0,
    double a2, double? a1, double a3) {
  double lw = L * -1;
  double theta = unwindAngle(theta0 + (360.985647 * m0));
  double a = unwindAngle(interpolateAngles(a2, a1, a3, m0)!);
  double H = quadrantShiftAngle(theta - lw - a);
  double dm = H / -360;
  return (m0 + dm) * 24;
}

static double correctedHourAngle(
    double? m0, double h0, dynamic coordinates, bool afterTransit,
    double theta0, double a2, double? a1, double a3,
    double d2, double? d1, double d3) {
  double lw = coordinates.longitude * -1;
  double term1 = sin(degreesToRadians(h0)) -
      (sin(degreesToRadians(coordinates.latitude)) *
       sin(degreesToRadians(d2)));
  double term2 = cos(degreesToRadians(coordinates.latitude)) *
      cos(degreesToRadians(d2));

  double H0 = (term1 / term2).abs() > 1
      ? 1.0
      : radiansToDegrees(acos(term1 / term2));

  double m = afterTransit ? m0! + (H0 / 360) : m0! - (H0 / 360);
  double theta = unwindAngle(theta0 + (360.985647 * m));
  double a = unwindAngle(interpolateAngles(a2, a1, a3, m)!);
  double delta = interpolate(d2, d1, d3, m)!;
  double H = theta - lw - a;
  double h = altitudeOfCelestialBody(coordinates.latitude, delta, H);
  double term3 = h - h0;
  double term4 = 360 * cos(degreesToRadians(delta)) *
      cos(degreesToRadians(coordinates.latitude)) *
      sin(degreesToRadians(H));
  double dm = term3 / term4;
  return (m + dm) * 24;
}
```
