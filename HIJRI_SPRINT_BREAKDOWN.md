# Hijri Feature Sprint Breakdown

Dokumen ini khusus untuk breakdown pekerjaan fitur Hijriyah.
Dokumen ini **terpisah** dari folder `doc/` yang sudah ada.

## Goal Utama

- Menambahkan modul `calendar_hijri` yang stabil, modular, dan siap ekspansi.
- Mendukung multi-method:
  - `calculatedLocal` (manual/local engine)
  - `ummAlQura` (dataset-based)
  - `kemenagRiOfficial` (adjustment API optional, prioritas tertinggi)
- Menjamin prayer core tidak terdampak regression.

## Prinsip Implementasi

1. Offline-first: local method tetap jalan tanpa API.
2. Official-first: jika method official dipilih dan adjustment tersedia, gunakan adjustment.
3. Deterministic fallback: remote -> cache -> local.
4. Isolasi domain: modul Hijriyah tidak mengubah hasil prayer engine.

---

## Sprint 0 - Foundation Planning

### Scope
- Finalisasi kontrak API internal Hijriyah (Dart-side).
- Finalisasi aturan prioritas sumber data.
- Finalisasi format metadata hasil (`source`, `revision`, `isAdjusted`).

### Deliverables
- Draft class contract final:
  - `HijriDate`
  - `HijriMethod`
  - `HijriCalendar`
  - `HijriResolver`
- Final decision matrix method selection.

### Acceptance Criteria
- Semua kontrak class disetujui.
- Tidak ada ambiguity soal urutan prioritas data.

---

## Sprint 1 - Module Scaffolding + Data Organization

### Scope
- Membuat struktur folder `calendar_hijri`.
- Memindahkan file dataset `hijri_array.dart` dari root ke folder yang rapi.
- Memisahkan data inti konversi dan labels i18n.

### Target Struktur

```text
lib/src/calendar_hijri/
  data/
    umm_al_qura_data.dart
    hijri_labels.dart
  models/
    hijri_date.dart
    hijri_method.dart
    hijri_result_meta.dart
  providers/
    hijri_provider.dart
    local_hijri_provider.dart
    umm_al_qura_provider.dart
  resolver/
    hijri_resolver.dart
```

### Deliverables
- Struktur modul baru siap.
- `ummAlquraDateArray` berada di lokasi baru.
- File root lama tidak dipakai lagi.

### Acceptance Criteria
- Build/test existing tetap hijau.
- Tidak ada import lint error setelah pemindahan.

---

## Sprint 2 - Umm al-Qura Provider (Local)

### Scope
- Implement konversi berbasis `ummAlquraDateArray`.
- Tambahkan validasi range dataset.
- Expose method `ummAlQura` di resolver.

### Deliverables
- `UmmAlQuraProvider` berfungsi untuk `fromGregorian`.
- Error handling untuk tanggal di luar range dataset.

### Acceptance Criteria
- Unit test konversi sample date lulus.
- Unit test boundary range lulus.

---

## Sprint 3 - Local Manual Engine (Calculated)

### Scope
- Implement engine manual/local (metode yang akan Anda berikan).
- Pastikan deterministic output.
- Integrasi ke resolver sebagai `calculatedLocal`.

### Deliverables
- `LocalHijriProvider` aktif.
- Kontrak method sama dengan provider lain.

### Acceptance Criteria
- Unit test parity internal local engine lulus.
- Tidak ada ketergantungan network.

---

## Sprint 4 - Official Adjustment Integration (Optional API)

### Scope
- Implement `RemoteAdjustmentClient` (optional).
- Implement cache layer + ETag revalidation.
- Implement apply adjustment rule ke hasil base.

### Priority Rule
1. remote adjustment (fresh)
2. cached adjustment
3. local result

### Deliverables
- `kemenagRiOfficial` method berjalan.
- Metadata result mengandung source info.

### Acceptance Criteria
- Integration test remote 200/304/error lulus.
- Offline fallback test lulus.

---

## Sprint 5 - Conflict Rules + Hardening

### Scope
- Implement conflict resolution untuk adjustment records.
- Stabilkan edge cases month boundary.
- Audit timezone handling (UTC/local boundaries).

### Deliverables
- Resolver conflict deterministic.
- Dokumentasi behavior edge-case tersedia.

### Acceptance Criteria
- Test conflict revision lulus.
- Test cross-month and cross-year lulus.

---

## Sprint 6 - Public API Exposure + Backward Safety

### Scope
- Expose API Hijriyah di `lib/islamic_utility.dart`.
- Pastikan tidak ada breaking behavior pada existing prayer APIs.
- Tambah contoh penggunaan untuk semua metode Hijriyah.

### Deliverables
- API publik Hijriyah siap dipakai.
- Example runnable untuk local, ummAlQura, official.

### Acceptance Criteria
- Existing test suite + Hijriyah test suite lulus.
- `dart pub publish --dry-run` tanpa warning baru.

---

## Sprint 7 - Production Readiness

### Scope
- Final docs user-facing + FAQ update.
- Performance sanity check.
- Release notes final.

### Deliverables
- Dokumen implementasi user lengkap untuk Hijriyah.
- Changelog untuk rilis fitur Hijriyah.

### Acceptance Criteria
- Dokumen sinkron dengan API final.
- QA checklist selesai.

---

## Risk Register

1. **Dataset range limitation (Umm al-Qura)**
- Mitigasi: deteksi out-of-range + fallback message jelas.

2. **Official adjustment ambiguity**
- Mitigasi: kunci authority `kemenag_ri` + revision policy ketat.

3. **Timezone mismatch near midnight**
- Mitigasi: test khusus boundary dan konversi eksplisit.

4. **Regression ke prayer core**
- Mitigasi: isolasi modul + regression suite wajib setiap sprint.

## Definition of Done (Hijri Track)

- Multi-method Hijriyah aktif (`calculatedLocal`, `ummAlQura`, `kemenagRiOfficial`).
- Fallback official adjustment stabil.
- Seluruh test lulus (unit + integration + boundary).
- Dokumentasi dan contoh penggunaan lengkap.
- Tidak ada perubahan hasil prayer core tanpa approval.
