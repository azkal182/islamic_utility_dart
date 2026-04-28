# Modular Architecture for V2

Target: menjaga parity engine inti, sambil membuka jalan untuk fitur baru.

## Prinsip Arsitektur

- Core perhitungan sholat harus terisolasi dan stabil.
- Fitur tambahan tidak boleh mengubah hasil core kecuali melalui konfigurasi eksplisit.
- Public API dibagi per domain, bukan per file formula.

## Usulan Modul

1. `core_astronomy`
- Rumus astronomi murni, utilitas sudut/waktu.

2. `prayer_engine`
- `PrayerTimes`, parameter methods, boundary logic.

3. `sunnah_engine`
- `SunnahTimes`.

4. `qibla_engine`
- `Qibla`.

5. `calendar_hijri` (fase berikutnya)
- Konversi Gregorian-Hijri dan metadata tanggal hijri.

6. `calendar_javanese` (fase berikutnya)
- Pasaran Jawa dan weton info.

7. `integration_facade`
- API gabungan agar aplikasi cukup pakai satu entry.

## Dependency Direction

- `core_astronomy` tidak boleh depend ke modul lain.
- `prayer_engine` depend ke `core_astronomy`.
- `sunnah_engine` depend ke `prayer_engine`.
- `qibla_engine` hanya depend ke utilitas math/coords.
- `calendar_*` independen dari prayer core, kecuali untuk agregasi output.

## Extension Points

- `PrayerMethodProvider` untuk method preset custom.
- `TimeAdjustmentPolicy` untuk offset lokal/organisasi.
- `BoundaryPolicy` untuk current/next strategy (tetap default kompatibel).

## Risk Control

- Snapshot parity test wajib di setiap refactor modular.
- Tidak mengubah formula core tanpa bukti ilmiah + regression safety.
