# 🚀 Changelog v1.8.0+1 - The Cloud Identity Update

## ☁️ Fitur Utama: Cloud Sync & Identity
- **Global User Identity (UUID)**: Setiap perangkat sekarang memiliki ID Unik permanen. Rekor abang tidak akan tertukar meskipun ada pemain lain dengan nama yang sama.
- **Auto-Profile Sync**: Saat aplikasi dibuka, data lokal (Nama & Skor) otomatis di-import ke server. Rekor abang langsung nampang di leaderboard dunia tanpa harus main ulang.
- **Persistent Personal Best**: Skor tertinggi abang sekarang tersimpan aman di file biner terenkripsi `user.skm` dan disinkronkan ke cloud.

## 🏆 Leaderboard & Kompetisi
- **Global Top 3 Podium**: Lobby sekarang menampilkan 3 pemain terbaik di seluruh dunia secara real-time.
- **In-Game PB Display**: Sekarang abang bisa melihat rekor tertinggi (Personal Best) musuh langsung di bawah profil mereka saat bertanding. Begitu juga sebaliknya!
- **Identity-Based Leaderboard**: Sistem peringkat sekarang menggunakan User ID sebagai kunci, bukan lagi nama. Ganti nama tetap bisa, rekor tidak akan hilang.

## 🤖 Mode Offline & AI
- **Smart AI PB**: Lawan komputer sekarang memiliki rekor (PB) yang berbeda-beda sesuai tingkat kesulitan (Easy, Normal, Hard).
- **Network Decoupling**: Perbaikan bug di mana game offline lawan komputer sempat mencoba mengirim data ke server. Sekarang mode offline benar-benar mandiri.

## 🛠️ Optimasi & Perbaikan Bug
- **Linux Compatibility**: Memperbaiki masalah "Loading Selamanya" pada OS Linux dengan menambahkan pengaman pada sistem perizinan (Permission Gating).
- **Room Switching Logic**: Memperbaiki bug "Global Lobby Log". Sekarang saat abang membuat room, koneksi ke lobby utama diputus dengan benar untuk masuk ke room privat.
- **Profile Header Fix**: Memperbaiki nama di pojok kanan atas yang sempat macet di tulisan "Pemain". Sekarang nama langsung tersinkron dari data lokal saat startup.
- **Smart JSON Backend**: Backend bermigrasi ke sistem penyimpanan JSON berbasis ID untuk menghindari error GLIBC pada VPS.

---
*Nikmati pengalaman kompetisi global yang lebih adil dan transparan!*
