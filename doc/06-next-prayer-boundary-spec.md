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
  - `nextPrayer = fajr`
- Window B:
  - `currentPrayer = fajr`
  - `nextPrayer = sunrise`
- Window C:
  - `currentPrayer = sunrise`
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
  - `nextPrayer = fajrAfter`

## Isu Referensi Saat Ini

Pada implementasi referensi, potensi invalid terjadi bila `nextPrayer()` dipanggil tanpa `date` eksplisit dan konteks timezone/tanggal tidak sinkron dengan objek jadwal. Ini menghasilkan kesan next prayer tidak valid setelah Isya atau lewat midnight.

## Kontrak Perbaikan yang Disarankan

- Jangan bergantung pada `DateTime.now()` implicit untuk production flow lintas timezone.
- Tambahkan API eksplisit (`nextPrayerAt(DateTime at)` atau wajibkan argumen `date`).
- Jika `at` berada di tanggal lain dari jadwal object, lakukan rekalkulasi jadwal untuk tanggal `at`.

## Test Cases Wajib

- Tepat sebelum/tepat saat/tepat sesudah `fajr`.
- Tepat sebelum/tepat saat/tepat sesudah `isha`.
- `23:59:59`, `00:00:00`, `00:30:00`.
- Device timezone berbeda dengan timezone lokasi jadwal.
