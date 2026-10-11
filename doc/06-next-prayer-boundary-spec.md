# Next Prayer Boundary Specification

Dokumen ini mengunci behavior lintas hari untuk `currentPrayer` dan `nextPrayer`.

## Definisi Boundary

- Window A: `date < fajr`
- Window B: `fajr <= date < sunrise`
- Window C: `sunrise <= date < dhuhr`
- Window D: `dhuhr <= date < asr`
- Window E: `asr <= date < maghrib`
- Window F: `maghrib <= date < isha`
- Window G: `date >= isha`

## Behavior Wajib

- Window A:
  - `currentPrayer = ishaBefore`
  - `nextPrayer = imsak` before Imsak, otherwise `fajr` (unless skipped)
- Window B:
  - `currentPrayer = fajr`
  - `nextPrayer = sunrise` by default
- Window C:
  - `currentPrayer = sunrise`
  - `nextPrayer = dhuha` by default
- Between Dhuha and Dhuhr:
  - `nextPrayer = dhuhr`
- Window D:
  - `currentPrayer = dhuhr`
  - `nextPrayer = asr`
- Window E:
  - `currentPrayer = asr`
  - `nextPrayer = maghrib`
- Window F:
  - `currentPrayer = maghrib`
  - `nextPrayer = isha`
- Window G:
  - `currentPrayer = isha`
  - `nextPrayer = imsak` on the next local date by default

## Isu Referensi Saat Ini

Pada implementasi referensi, potensi invalid terjadi bila `nextPrayer()` dipanggil tanpa `date` eksplisit dan konteks timezone/tanggal tidak sinkron dengan objek jadwal. Ini menghasilkan kesan next prayer tidak valid setelah Isya atau lewat midnight.

## Kontrak Perbaikan yang Disarankan

- Jangan bergantung pada `DateTime.now()` implicit untuk production flow lintas timezone.
- Tambahkan API eksplisit (`nextPrayerAt(DateTime at)` atau wajibkan argumen `date`).
- Jika `at` berada di tanggal lain dari jadwal object, lakukan rekalkulasi jadwal untuk tanggal `at`.

## API Detail Hari Berikutnya

`PrayerTimes.nextPrayerDetails(at: ..., locationDate: ...)` mengembalikan
`prayer`, `time`, dan `isNextDay`. `locationDate` harus memuat tanggal kalender
di lokasi target untuk instant `at` (misalnya komponen tanggal dari
`TZDateTime`). Penanda `isNextDay` mengikuti tanggal lokal lokasi, bukan tanggal
UTC pada waktu hasil. Ini membedakan Fajr yang masih akan datang hari ini setelah
tengah malam dari Fajr besok setelah Isya.

`nextPrayer()` lama tetap tersedia. Ia menggunakan jadwal pada object, lalu
beralih ke jadwal hari berikutnya setelah `fajrAfter` terlewati. Untuk hasil
yang akurat pada zona waktu lokasi yang berbeda dari perangkat, gunakan
`nextPrayerDetails` dan isi `locationDate` dari timezone-aware date aplikasi.

Kandidat event default adalah Imsak, Fajr, Sunrise, Dhuha, Dhuhr, Asr,
Maghrib, dan Isha. `NextPrayerOptions.skip` dapat melewati event tertentu:
melewati Sunrise membuat Dhuha menjadi kandidat berikutnya; melewati Sunrise
dan Dhuha membuat Dhuhr menjadi kandidat berikutnya. Imsak secara default
berlaku setiap hari. `ImsakPolicy.ramadanOnly` membatasi Imsak ke tanggal yang
ditandai Ramadan oleh callback `isRamadanOn`; `ImsakPolicy.never` menghilangkan
Imsak sepenuhnya. Callback memeriksa tanggal lokasi hari ini dan besok sesuai
kebutuhan.

## Test Cases Wajib

- Tepat sebelum/tepat saat/tepat sesudah `fajr`.
- Tepat sebelum/tepat saat/tepat sesudah `isha`.
- `23:59:59`, `00:00:00`, `00:30:00`.
- Device timezone berbeda dengan timezone lokasi jadwal.
- Setelah Isya: Imsak berikutnya `isNextDay == true` by default; skip Imsak to
  select Fajr instead.
- Setelah tengah malam sebelum Fajr: Fajr berikutnya `isNextDay == false`.
- Objek jadwal kemarin yang ditanya pada tanggal hari ini menghitung ulang jadwal.
