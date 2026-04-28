# Timezone and DateTime Contract

Dokumen ini wajib dipatuhi agar hasil tidak meleset karena mismatch timezone/tanggal.

## Prinsip Utama

- Engine menyimpan output sebagai `DateTime` UTC.
- Layer presentasi yang mengubah ke local timezone (`TZDateTime.from(...)`).
- Input `date` merepresentasikan tanggal lokal lokasi target perhitungan.

## Aturan Operasional

- Saat menghitung jadwal harian, gunakan date yang sudah dikaitkan timezone lokasi (misalnya `tz.TZDateTime(location, yyyy, mm, dd)`).
- Jangan campur `DateTime.now()` sistem dengan jadwal untuk timezone berbeda tanpa konversi.
- `currentPrayer(date: ...)` dan `nextPrayer(date: ...)` harus menerima waktu referensi yang konsisten timezone-nya dengan konteks jadwal.

## Anti-Pattern

- Membuat `PrayerTimes` untuk lokasi A, lalu memanggil `nextPrayer()` tanpa argumen ketika device berada di timezone B.
- Memakai UTC date untuk konstruksi, tapi membandingkan current/next dengan local time mentah.

## Rounding Contract

- `precision: true` -> tidak rounding menit.
- `precision: false` -> dibulatkan ke menit terdekat (`>=30 detik` naik, `<30` turun).

## Checklist Integrasi Aplikasi

- Pastikan timezone lokasi diketahui.
- Bangun `PrayerTimes` untuk tanggal di timezone lokasi.
- Untuk current/next real-time, selalu kirim `date` eksplisit ke fungsi utility.
