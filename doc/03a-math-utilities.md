# 03a — Math Utilities

Fungsi-fungsi dasar yang digunakan di seluruh engine. Harus diimplementasikan **persis** seperti di bawah.

## `degreesToRadians(degrees: double) → double`

```
return degrees × π / 180.0
```

## `radiansToDegrees(radians: double) → double`

```
return radians × 180.0 / π
```

## `normalizeToScale(number: double, max: double) → double`

Normalisasi nilai ke rentang `[0, max)`.

```
return number - (max × floor(number / max))
```

Contoh: `normalizeToScale(725, 360) = 5.0`

## `unwindAngle(angle: double) → double`

Normalisasi sudut ke rentang `[0°, 360°)`.

```
return normalizeToScale(angle, 360.0)
```

## `quadrantShiftAngle(angle: double) → double`

Normalisasi sudut ke rentang `[-180°, 180°]`.

```
if angle >= -180 AND angle <= 180:
    return angle
return angle - (360 × round(angle / 360))
```

> **PENTING**: `round()` di sini adalah pembulatan standar (bukan floor/ceil). Fungsi ini digunakan pada `correctedTransit` untuk menghitung koreksi hour angle.

## Referensi Implementasi

```dart
// adhan_dart/lib/src/MathUtils.dart
double degreesToRadians(double degrees) {
  return (degrees * pi) / 180.0;
}

double radiansToDegrees(double radians) {
  return (radians * 180.0) / pi;
}

double normalizeToScale(double number, double max) {
  return number - (max * ((number / max).floor()));
}

double unwindAngle(double angle) {
  return normalizeToScale(angle, 360.0);
}

double quadrantShiftAngle(double angle) {
  if (angle >= -180 && angle <= 180) {
    return angle;
  }
  return angle - (360 * (angle / 360).round());
}
```
