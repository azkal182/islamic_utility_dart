# Astronomical Engine Reference (Meeus-Based)

Dokumen ini adalah **indeks utama** spesifikasi engine astronomi yang harus diimplementasikan agar hasil perhitungan waktu sholat **identik** dengan package referensi `adhan_dart`.

> **Sumber algoritma**: Jean Meeus, *Astronomical Algorithms*, 2nd Edition (1998).
> Semua referensi halaman merujuk ke buku tersebut.

## Prinsip Kunci

1. **Semua sudut internal dalam satuan derajat (degree)**, kecuali saat masuk ke fungsi trigonometri `sin`/`cos`/`tan` yang membutuhkan radian.
2. **Waktu transit & hour angle dalam jam desimal UTC**, lalu dikonversi ke komponen jam-menit-detik via `TimeComponents`.
3. **Interpolasi 3-hari** digunakan untuk transit dan hour angle — bukan one-shot calculation.
4. **Tidak boleh ada approximation Spencer/Fourier** — semua harus mengikuti pipeline Meeus.

## Sub-Dokumen Detail

| Dokumen | Isi |
|---|---|
| [03a-math-utilities.md](03a-math-utilities.md) | Fungsi matematika dasar & konversi sudut |
| [03b-julian-date.md](03b-julian-date.md) | Julian Day & Julian Century |
| [03c-solar-position.md](03c-solar-position.md) | Pipeline posisi matahari (longitude, anomaly, declination, right ascension) |
| [03d-nutation-obliquity.md](03d-nutation-obliquity.md) | Nutation & obliquity of the ecliptic |
| [03e-transit-hour-angle.md](03e-transit-hour-angle.md) | Transit, sunrise/sunset, dan corrected hour angle |
| [03f-solar-time-class.md](03f-solar-time-class.md) | Class SolarTime & afternoon shadow |
| [03g-seasonal-adjustment.md](03g-seasonal-adjustment.md) | Season-adjusted twilight (Moonsighting Committee) |
| [03h-prayer-times-pipeline.md](03h-prayer-times-pipeline.md) | Pipeline lengkap PrayerTimes dari SolarTime ke output akhir |

## Catatan Stabilitas Numerik

- Rasio pada `acos` harus dijaga dalam domain `[-1, 1]`.
- Normalisasi sudut harus konsisten untuk mencegah diskontinuitas.
- Hindari perubahan urutan operasi floating point kecuali ada justifikasi + regression test parity.
- Gunakan `double` (64-bit IEEE 754) untuk semua kalkulasi.
