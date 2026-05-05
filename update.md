# 🚀 Changelog v1.7.0+1 - Global Online Update

## 🌐 Fitur Baru: Online Multiplayer
- **Relay Server Support**: Migrasi dari koneksi lokal P2P ke server terpusat. Sekarang pemain bisa bermain antar jaringan (misal: Telkomsel vs Indihome).
- **Room ID System**: Buat dan gabung room menggunakan kode unik 4-6 digit.
- **WebSocket Synchronization**: Jabat tangan koneksi yang lebih stabil menggunakan protokol WSS (Secure WebSocket).
- **Cloudflare Tunnel Integration**: Memungkinkan server berjalan di balik firewall ketat tanpa perlu konfigurasi port forwarding manual.

## 📱 Mobile Experience
- **Portrait Mode Locked**: Tampilan game sekarang terkunci di mode Portrait (berdiri) untuk kenyamanan bermain di smartphone.
- **Custom Virtual Keyboard**: 
  - Menggantikan keyboard bawaan sistem agar tidak menutupi tampilan game.
  - Layout dioptimalkan untuk kecepatan mengetik.
  - Mendukung input simultan dengan keyboard fisik (untuk tablet/desktop).
- **Keyboard Auto-Focus**: Keyboard virtual otomatis muncul dan fokus saat giliran pemain tiba.

## 🎨 Visual & Branding
- **New App Icon**: Mengganti icon standar Flutter dengan logo resmi Sambung Kata.
- **Responsive Layout**: Konten game di area tengah kini bersifat scrollable untuk mencegah overflow pada layar HP kecil saat keyboard aktif.

## 🛠️ Perbaikan Bug
- Menghapus dependensi UDP/P2P yang sering menyebabkan crash pada beberapa jaringan.
- Memperbaiki penanganan nama pemain duplikat di dalam satu room (otomatis ditambahkan angka pembeda).
- Optimasi pembersihan memori saat keluar dari game room.

---
*Update ini wajib untuk dapat menggunakan fitur Online Multiplayer.*
