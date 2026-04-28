# Calculation Core Specification

Dokumen ini menjelaskan urutan algoritma inti yang menghasilkan waktu sholat.

## Input Utama

- `date` (Gregorian date; waktu lokal boleh, namun dipakai hanya komponen tanggal saat konstruksi)
- `coordinates` (`latitude`, `longitude`)
- `calculationParameters`
- `precision`

## Output Utama

- `fajr`, `sunrise`, `dhuhr`, `asr`, `maghrib`, `isha`
- `ishaBefore` (Isha hari sebelumnya)
- `fajrAfter` (Fajr hari berikutnya)

## Pipeline Perhitungan

1. Hitung tiga tanggal:
   - `dateBefore = date - 1 hari`
   - `date` (hari target)
   - `dateAfter = date + 1 hari`
2. Bentuk `SolarTime` untuk ketiga tanggal.
3. Hitung waktu dasar hari target:
   - `dhuhr` dari `solar.transit`
   - `sunrise` dari `solar.sunrise`
   - `sunset` dari `solar.sunset`
   - `asr` dari `solar.afternoon(shadowLength(madhab))`
4. Hitung panjang malam:
   - `night = tomorrowSunrise - sunset`
5. Hitung `fajr` dan `fajrAfter` dengan hour angle (sebelum transit).
6. Terapkan fallback aman `fajr` (high-lat rules/seasonal adjustment).
7. Hitung `isha` dan `ishaBefore`:
   - Jika `ishaInterval > 0`: `isha = sunset + interval`
   - Jika tidak: gunakan hour angle (setelah transit) lalu fallback aman.
8. Tentukan `maghrib`:
   - default: `sunset`
   - jika `maghribAngle` ada dan berada antara sunset dan isha, gunakan angle-based maghrib.
9. Terapkan total adjustment tiap prayer:
   - `total = adjustments[prayer] + methodAdjustments[prayer]`
10. Terapkan pembulatan `roundedMinute` tergantung `precision`.

## High Latitude & Safety Rules

- Metode `moonsightingCommittee` + latitude >= 55:
  - Fajr/Isha pakai fraksi 1/7 malam.
- Metode lain:
  - Gunakan `highLatitudeRule` untuk night portion.
  - Fajr aman: tidak lebih awal dari batas aman.
  - Isha aman: tidak lebih lambat dari batas aman.

## Urutan Aturan yang Wajib Sama

- Hitung astronomi dahulu, baru fallback, baru adjustments, lalu rounding.
- Jangan ubah urutan karena dapat menggeser hasil menit/detik.

## Kontrak Deterministik

- Untuk input identik, output harus identik.
- Tidak boleh ada dependensi ke state global selain input parameter.
- `DateTime.now()` tidak boleh dipakai dalam constructor perhitungan (kecuali default field yang tidak terpakai dalam kalkulasi final).
