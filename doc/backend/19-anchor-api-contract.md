# 19 - Anchor API Contract

Dokumen ini menjelaskan kontrak endpoint anchor yang dipakai client anchor-only.
Endpoint adjustment tetap tersedia untuk client legacy, tetapi tidak dipakai oleh
mode official default di package Dart.

## Endpoint

```text
GET /v1/hijri/anchors
GET /v1/hijri/anchors/latest
```

Query range menggunakan parameter yang sama dengan endpoint lama:

```text
country=ID
from=YYYY-MM-DD
to=YYYY-MM-DD
authority=kemenag_ri
region_scope=national
```

Contoh:

```http
GET /v1/hijri/anchors?country=ID&from=2026-06-01&to=2026-07-31&authority=kemenag_ri&region_scope=national
Authorization: Bearer <api_key>
If-None-Match: "etag-previous"
```

## Record anchor

```json
{
  "id": "anchor_1448_01_v1",
  "authority": "kemenag_ri",
  "country": "ID",
  "region_scope": "national",
  "official_gregorian_date": "2026-06-16",
  "hijri_year": 1448,
  "hijri_month": 1,
  "hijri_day": 1,
  "revision": 1,
  "published_at": "2026-06-16T03:19:00Z",
  "status": "final",
  "reason": "isbat_hilal",
  "notes": null
}
```

`official_gregorian_date` adalah tanggal Gregorian saat hari pertama bulan
Hijriah dimulai. Anchor bukan delta dan tidak boleh diterapkan sebagai `+1` atau
`-1` terhadap tanggal lain.

## Aturan penting

1. Untuk satu `authority`, `country`, `region_scope`, `hijri_year`, dan
   `hijri_month`, hanya satu record `final` yang boleh aktif.
2. Revisi baru menaikkan `revision`; record lama menjadi `superseded`.
3. Selisih dua anchor berurutan harus 29 atau 30 hari.
4. Response range sebaiknya menyertakan anchor terakhir sebelum `from`, karena
   client memerlukannya untuk menghitung tanggal di awal range.
5. Jika tidak ada anchor sebelum target, single-date client dapat memakai
   `local_fallback` dengan `meta.isProvisional == true`; range client harus
   menolak sequence yang menghasilkan duplikat atau lompatan.
6. Client tidak boleh menggunakan anchor yang tanggalnya berada setelah target.

Response range dapat mengirim field tambahan `predecessor`:

```json
{
  "schema_version": "1.1.0",
  "generated_at": "2026-09-06T19:33:33.029Z",
  "predecessor": {
    "official_gregorian_date": "2026-01-20",
    "hijri_year": 1447,
    "hijri_month": 8,
    "hijri_day": 1,
    "revision": 1,
    "published_at": "2026-01-19T00:00:00Z",
    "status": "final"
  },
  "records": []
}
```

`predecessor` adalah anchor aktif terdekat sebelum `from`. Client yang
mendukungnya menggabungkan record ini dengan `records` setelah deduplikasi.
Client lama tetap dapat membaca `records`, tetapi mungkin tidak dapat
menghitung awal range secara resmi jika `records` dimulai di tengah bulan.

`published_at` adalah waktu publikasi atau koreksi resmi, bukan acuan
perhitungan tanggal. `generated_at` adalah waktu dataset response dibuat.
Gunakan timestamp RFC3339 yang timezone-aware; kontrak production menggunakan
UTC dengan suffix `Z`.

## Cache dan update

Tanggal yang sudah berada di antara dua anchor `final` tidak perlu meminta API
setiap kali. API perlu diakses kembali ketika:

- bulan Hijriah baru ditetapkan;
- revision anchor berubah;
- cache expired atau invalid;
- status provisional berubah menjadi final.

Update anchor baru tidak mengubah anchor bulan sebelumnya. Client cukup
menginvalidasi cache pada rentang antara anchor sebelumnya dan anchor yang
diperbarui.
