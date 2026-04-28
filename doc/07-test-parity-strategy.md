# Test and Parity Strategy

Tujuan: memastikan implementasi baru menghasilkan output setara package referensi.

## Prinsip Uji

- Gunakan regression tests dari dataset referensi sebanyak mungkin.
- Uji lintang rendah, sedang, tinggi; musim panas dan dingin.
- Uji semua method preset.
- Uji precision mode (`true/false`).

## Kategori Test

1. API Contract Test
- Konstruktor, enum mapping, `timeForPrayer` mapping.

2. Numerical Parity Test
- Bandingkan hasil UTC terhadap baseline.

3. Boundary Behavior Test
- `currentPrayer`/`nextPrayer` untuk seluruh window waktu.

4. High Latitude Test
- Aturan 1/7 night untuk moonsighting latitude >= 55.
- `middleOfTheNight`, `seventhOfTheNight`, `twilightAngle`.

5. Timezone Consistency Test
- Schedule dibuat dengan timezone lokasi, compare dengan instant referensi konsisten.

## Toleransi

- `precision: true`: ideal 0 detik, toleransi <= 1 detik.
- `precision: false`: toleransi <= 1 menit.
- Untuk skenario eksternal tertentu boleh toleransi khusus (mis. 1 menit pada method tertentu) asalkan terdokumentasi.

## Baseline Matrix Minimum

- Method: `northAmerica`, `muslimWorldLeague`, `moonsightingCommittee`, `turkiye`, `egyptian`, `singapore`, `ummAlQura`, `qatar`, `dubai`, `kuwait`, `tehran`, `karachi`, `morocco`.
- Lokasi: minimal 1 kota representatif per method.
- Waktu: minimal 2 musim per lokasi.

## Acceptance Criteria

- Semua test kontrak API lulus.
- Semua test parity numerik lulus dalam toleransi.
- Semua test boundary lintas hari lulus.
- Tidak ada flakiness akibat timezone sistem build agent.
