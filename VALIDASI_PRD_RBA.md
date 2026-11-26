# Validasi SarprasGo terhadap PRD dan RBA

## Hasil validasi Flutter

- `flutter analyze`: lulus, **No issues found**.
- `flutter test`: lulus, **2 widget test** untuk alur masuk mode demo sebagai Peminjam dan Admin, membuka katalog, serta melihat antrean persetujuan.
- `flutter build apk --debug`: lulus; artefak dibuat di `build/app/outputs/flutter-apk/app-debug.apk`.
- Pengujian ini memvalidasi UI lokal, bukan koneksi Supabase, RLS, transaksi PostgreSQL, kamera perangkat fisik, atau konkurensi.

Android wrapper juga diperbaiki supaya path workspace dengan karakter `&` tetap terbaca di Windows. Incremental Kotlin dimatikan karena cache Pub berada di drive C: sementara project berada di D: dan compiler Kotlin gagal membentuk path relatif lintas drive.

## Pemetaan implementasi

| Area PRD/RBA | Implementasi saat ini | Status |
| --- | --- | --- |
| Role Peminjam, Admin, Petugas Sarpras | Navigasi dan dashboard berbeda per role; role produksi dibaca dari `public.users` setelah login Supabase | Parsial; data mode demo terpisah |
| Login akun aktif | Login email/password; akun `is_active = false` ditolak | Tersedia dengan Supabase |
| Katalog/ketersediaan | Katalog barang dan ruang; baca melalui `get_availability_summary` | Parsial; signature dan respons RPC belum ditetapkan dalam RBA |
| Pengajuan barang/ruang | Form keperluan, jadwal WIB, multi-barang, ruang opsional, organisasi, validasi input, UUID idempotensi | Parsial; `create_loan` belum memiliki kontrak parameter di RBA; lampiran belum diunggah |
| Persetujuan penuh/parsial | Admin mengatur kuantitas dan memanggil `approve_loan_atomic` | Parsial; kontrak approval ada, tetapi respons dan relasi PostgREST harus cocok dengan migrasi final |
| Penolakan | Alasan diwajibkan pada UI | Belum tersambung; RBA belum menetapkan nama/signature RPC penolakan |
| QR peminjam | Token diminta lewat `get_my_loan_qr` dan ditampilkan sebagai QR | Parsial; signature/respons perlu dicocokkan dengan SQL final |
| Verifikasi QR petugas | Scanner kamera dan pemanggilan read-only `verify_qr_transaction` | Parsial; parameter RPC masih asumsi aplikasi |
| Pickup/return | Mode demo dapat disimulasikan | Belum ada mutasi produksi; RBA belum menetapkan RPC/payload serah-terima |
| Inventaris dan penyesuaian stok | Tampilan katalog/inventaris | Baca saja; metadata, `adjust_item_stock`, dan audit belum tersambung |
| Koreksi, pembatalan, akun, notifikasi, realtime, cron | Belum tersedia sebagai alur produksi | Belum diimplementasikan; perlu kontrak RPC, kebijakan, dan backend |

## Flaws dan risiko integrasi yang teridentifikasi

1. **Kontrak RPC belum lengkap.** Aplikasi memakai asumsi parameter untuk `get_availability_summary`, `create_loan`, `get_my_loan_qr`, dan `verify_qr_transaction`. PRD/RBA belum menetapkan signature/JSON response lengkap untuk fungsi-fungsi tersebut. Respons kesalahan JSON `{ok:false}` ditangani, tetapi format final wajib dicocokkan sebelum koneksi produksi.
2. **Pengajuan organisasi belum membawa lampiran.** Nama organisasi divalidasi di UI, tetapi bucket privat, batas ukuran/MIME, path per pengguna, cleanup unggahan yatim, dan `attachment_url` belum diterapkan di klien.
3. **Pengembalian belum mencatat kuantitas.** Tidak ada alur produksi untuk `returned_qty`, `damaged_qty`, dan `lost_qty`, jadi belum dapat menjaga invarian stok melalui aplikasi.
4. **Akses Petugas masih menunggu RPC antrean.** Aplikasi tidak melakukan `SELECT` massal dari tabel `loans`; mode Supabase menampilkan bahwa antrean perlu RPC terlingkup. Ini mengikuti prinsip RLS dalam RBA, tetapi FR antrean serah-terima belum selesai.
5. **Ketersediaan harus otoritatif di server.** Klien memeriksa hasil RPC untuk rentang pilihan, tetapi persetujuan/pengajuan tetap harus memvalidasi stok dan konflik jadwal secara atomik di PostgreSQL. Bentuk respons RPC sekarang masih asumsi.
6. **Pemulihan idempotensi lintas proses belum penuh.** UUID idempotensi disimpan lokal dan dipakai ulang selama draft/form aktif, namun isi draft dan `draft_id` belum dipulihkan setelah aplikasi ditutup paksa. Persistensikan draft penuh dan tambahkan jalur cek status setelah timeout sebelum rilis produksi.
7. **Pendaftaran belum tersedia.** Login hanya melayani akun yang sudah dibuat dan diaktifkan. Alur signup, verifikasi NIM/NIP, dan aktivasi Admin belum dapat ditentukan aman karena trigger signup serta aturan identitas di RBA masih belum lengkap.
8. **Hak akses server tetap wajib diuji.** Penyembunyian tombol di Flutter bukan kontrol keamanan. Semua izin, pembatasan kolom `qr_token`, RLS, idempotensi, lock ordering, koreksi stok, dan audit harus ditegakkan oleh RPC/database dan dites terpisah dengan pgTAP serta uji konkurensi.

## Kebutuhan sebelum dipakai operasional

- Finalkan signature, payload, respons sukses/gagal, idempotensi, serta role `EXECUTE` untuk seluruh RPC.
- Terapkan dan verifikasi migrasi Supabase/RLS/Storage/Realtime/cron dari RBA; repository saat ini hanya berisi Flutter, belum ada SQL migration atau seed Admin.
- Lengkapi signup dan verifikasi identitas; tetapkan keputusan fakultas yang masih placeholder pada PRD.
- Implementasikan penolakan, pembatalan, pickup/return, koreksi, manajemen master/stok/akun, notifikasi, dan pemulihan draft.
- Jalankan pgTAP, tes konkurensi, pengujian kamera Android/iOS, dan UAT terhadap backend yang sudah dikonfigurasi.
