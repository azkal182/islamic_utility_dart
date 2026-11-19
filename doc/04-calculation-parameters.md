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
- `lfnu`: fajr 20, isha 18, dhuha at +4.5°, Shafi Asr, dhuhr +1,
  Ramadan Maghrib ihtiyath +1 when enabled by the caller
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

## Elevasi, Dhuha, dan LFNU

`Coordinates` menerima `elevation` dalam meter dan default-nya 0 m. Elevasi
mengoreksi ufuk terbit/terbenam dengan dip ufuk sekitar
`1.76 × sqrt(elevation)` menit busur, ditambahkan ke 50 menit busur untuk
semi-diameter Matahari dan refraksi. Untuk elevasi 64 m, sudutnya sekitar
1°4′ di bawah ufuk, sesuai konfigurasi LFNU yang diberikan.

Preset `lfnu` menghitung Dhuha saat pusat Matahari mencapai +4.5°, bukan
sebagai offset menit dari terbit. `PrayerTimes.isRamadanOn` menerima callback
tanggal (UTC midnight) agar penambahan Maghrib satu menit hanya berlaku pada
hari yang ditandai Ramadan. Tanpa callback, tambahan Ramadan tidak diterapkan.

Preset ini merekam parameter LFNU yang diberikan untuk acuan Bangsri pada
proyek ini; preset tersebut tidak menyatakan bahwa semua jadwal LFNU selalu
memakai konfigurasi identik. FAQ NU Online yang dijadikan acuan perbandingan
menjelaskan ihtiyath bawaan 0 menit dan pembulatan `round up`, sedangkan
konfigurasi Bangsri yang diberikan ke proyek menyebut Maghrib Ramadan +1
menit. Karena itu, sumber dan kebijakan tampilan harus dicatat saat parity
diukur; jangan menganggap preset ini sebagai implementasi menyeluruh dari
setiap aplikasi atau jadwal LFNU.

### Kebijakan tampilan menit di client

`precision: false` membulatkan semua event ke menit terdekat. Untuk mengurangi
selisih terhadap PDF Bangsri 2026, pengujian reference dataset memakai Terbit
ke menit terdekat dan event lain `round up`; hasilnya 35 perbedaan event-harian
dari 2.920 nilai (365 hari × 8 event). Round-up untuk semua event menghasilkan
216 perbedaan; nearest-minute untuk semua event menghasilkan 1.191. Ini hanya
aturan tampilan yang cocok terhadap PDF pembanding ini, bukan perubahan rumus
astronomi atau kebijakan umum LFNU. FAQ NU Online menyebut round-up pada semua
event; jika target client adalah perilaku aplikasi tersebut, ikuti round-up
untuk semua event, termasuk Terbit: <https://app.nu.or.id/faq/jadwal-shalat/seberapa-akurat-jadwal-shalat-di-aplikasi-nu-online>.

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
