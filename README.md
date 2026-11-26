# SarprasGo

Aplikasi Flutter peminjaman sarana dan prasarana fakultas. Antarmuka memakai Bahasa Indonesia dan mendukung tiga pengalaman berdasarkan role: Peminjam, Admin, dan Petugas Sarpras.

## Menjalankan mode demo

```sh
flutter pub get
flutter run
```

Pada halaman masuk pilih role lalu tekan **Masuk mode demo**. Mode demo menggunakan data lokal contoh; tidak mengirim atau menyimpan transaksi di Supabase.

## Menghubungkan Supabase

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_SUPABASE_PUBLISHABLE_OR_LEGACY_ANON_KEY
```

Jangan memasukkan `service_role` key ke aplikasi. Kebijakan RLS dan RPC database harus menjadi batas keamanan. Akun perlu diaktifkan Admin agar login diterima.

## Struktur kode

```text
lib/
  app/                 # Root app
  core/                # Config, model, tema
  features/
    auth/              # Login dan profil
    catalog/           # Barang/ruang dan formulir pengajuan
    home/              # Dashboard dan inventaris
    loans/              # Riwayat, antrean admin, QR peminjam
    staff/              # Scanner QR serah-terima
```

## Status integrasi backend

Konfigurasi Supabase mengaktifkan login, baca katalog/peminjaman, pengajuan, persetujuan, QR milik peminjam, dan verifikasi QR. Beberapa kontrak di PRD/RBA belum ditentukan sehingga integrasi produksi belum lengkap:

- Bentuk respons dan parameter `get_availability_summary` serta `create_loan` masih perlu diselaraskan dengan SQL final.
- RBA belum memberikan signature RPC penolakan, antrean petugas, konfirmasi PICKUP/RETURN, koreksi serah-terima, penyesuaian stok, dan pengelolaan akun.
- Unggah lampiran organisasi ke bucket privat belum disambungkan.
- Fitur realtime, notifikasi, registrasi/verifikasi NIM-NIP, pembatalan, manajemen master, dan penutupan administratif belum terintegrasi penuh.

Jangan gunakan data mode demo sebagai data operasional. Tetapkan kontrak RPC dan kebijakan yang masih menunggu validasi fakultas sebelum produksi.

## Validasi lokal

```sh
flutter analyze
flutter test
```
