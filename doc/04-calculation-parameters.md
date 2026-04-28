# Calculation Parameters Specification

Dokumen ini mendefinisikan semua parameter yang memengaruhi hasil kalkulasi.

## Parameter Inti

- `method`: preset metode perhitungan.
- `fajrAngle`: sudut matahari untuk Fajr.
- `ishaAngle`: sudut matahari untuk Isha (jika `ishaInterval == 0`).
- `ishaInterval`: menit setelah Maghrib untuk Isha (override angle).
- `maghribAngle`: sudut opsional untuk Maghrib (metode tertentu).
- `madhab`: menentukan panjang bayangan Asr.
- `highLatitudeRule`: aturan porsi malam lintang tinggi.
- `shafaq`: tipe twilight untuk moonsighting evening adjustment.
- `adjustments`: offset menit custom per prayer.
- `methodAdjustments`: offset menit bawaan metode.

## Preset `CalculationMethod`

- `muslimWorldLeague`: fajr 18, isha 17, dhuhr +1
- `egyptian`: fajr 19.5, isha 17.5, dhuhr +1
- `indonesian`: fajr 20, isha 18, dhuhr +1
- `karachi`: fajr 18, isha 18, dhuhr +1
- `ummAlQura`: fajr 18.5, ishaInterval 90
- `qatar`: fajr 18, ishaInterval 90
- `dubai`: fajr/isha 18.2, sunrise -3, dhuhr/asr/maghrib +3
- `kuwait`: fajr 18, isha 17.5
- `moonsightingCommittee`: fajr 18, isha 18, dhuhr +5, maghrib +3
- `singapore`: fajr 20, isha 18, dhuhr +1
- `turkiye`: fajr 18, isha 17, sunrise -7, dhuhr +5, asr +4, maghrib +7
- `tehran`: fajr 17.7, isha 14, maghribAngle 4.5
- `northAmerica`: fajr 15, isha 15, dhuhr +1
- `morocco`: fajr 19, isha 17, sunrise -3, dhuhr +5, maghrib +5
- `other`: custom (0, 0)

## `Madhab` dan Asr

- `shafi` => shadow length 1
- `hanafi` => shadow length 2

Semakin besar shadow length, Asr lebih lambat.

## `HighLatitudeRule`

- `middleOfTheNight`: 1/2 malam
- `seventhOfTheNight`: 1/7 malam
- `twilightAngle`: `fajrAngle/60` dan `ishaAngle/60`

## Night Portions

`nightPortions()` harus mengembalikan:

- `Prayer.fajr -> fraction`
- `Prayer.isha -> fraction`

Fraction dipakai untuk fallback waktu aman saat hour angle tidak stabil.

## Adjustments

Offset akhir tiap prayer:

`finalOffset = adjustments[prayer] + methodAdjustments[prayer]`

Offset diterapkan setelah waktu dasar dihitung, sebelum pembulatan.

## Validasi Parameter (disarankan)

- `fajrAngle >= 0`
- `ishaAngle >= 0`
- `ishaInterval >= 0`
- map adjustments memuat key prayer wajib (`fajr`, `sunrise`, `dhuhr`, `asr`, `maghrib`, `isha`).
