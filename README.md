# 🎮 Game Sambung Kata - Global Online Edition

Aplikasi permainan **Sambung Kata** berbasis Flutter yang modern dan kompetitif. Kini mendukung mode **Online Multiplayer** di seluruh dunia melalui Relay Server, serta mode **AI Opponent** untuk latihan mandiri.

## ✨ Fitur Utama

- **Global Online Multiplayer**: Bermain bersama teman dari mana saja menggunakan Room ID melalui Relay Server Node.js.
- **Relay Server & Cloudflare Tunnel**: Koneksi stabil dan aman menggunakan WebSocket (WSS) yang mendukung berbagai jaringan seluler.
- **AI Opponent (Single Player)**: Lawan komputer dengan 3 tingkat kesulitan (Mudah, Normal, Sulit). AI memiliki perilaku manusiawi (bisa bingung, typo, dan kecepatan mengetik bervariasi).
- **Custom Virtual Keyboard**: Keyboard in-game khusus untuk mobile yang estetik, responsif, dan tidak menutupi tampilan game.
- **Portrait Mode Optimization**: Pengalaman bermain di HP yang lebih nyaman dengan layout tegak (Portrait).
- **Music Player In-Game**: Playlist musik acak dari folder aset dengan kontrol penuh (Play/Pause, Skip, Back) dan progress bar real-time.
- **Sistem Skor & XP Real-time**: Poin diperbarui secara instan dan skor tertinggi (High Score) tersinkronisasi otomatis setelah permainan selesai.
- **Auto-Update Native**: Sistem update otomatis di dalam aplikasi untuk Android (OTA APK) dan Desktop (ZIP Extractor).
- **Aesthetic Cyberpunk UI**: Antarmuka modern dengan Google Fonts (Outfit), animasi halus, dan efek suara interaktif.

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Backend**: Node.js WebSocket Server
- **Tunneling**: Cloudflare Tunnel (WSS)
- **Networking**: `web_socket_channel`, `http`
- **Persistence**: `shared_preferences`
- **Updates**: `ota_update` (Android), `http`, `archive` (ZIP Extraction)
- **Audio**: `audioplayers`

## 🏗️ Mekanisme Unggulan

### 1. Human-like AI Opponent
AI tidak hanya sekadar menjawab, tapi mensimulasikan perilaku manusia:
- **Smart Typing**: AI hanya mengetik sisa huruf dari awalan yang tersedia, mencegah pengulangan kata yang membingungkan.
- **Mudah**: Kata pendek, ngetik lambat, sering typo dan bingung.
- **Sulit**: Kata panjang, gacor, ngetik cepat, dan jarang salah.
- **Simulasi Bingung**: AI bisa mengetik huruf acak lalu menghapusnya kembali (backspace) jika sedang "berpikir".

### 2. In-Game Media Controller
Pemain memiliki kontrol penuh atas musik selama pertandingan:
- **Random Playlist**: Lagu berganti secara otomatis atau manual dari koleksi aset game.
- **Sync UI**: Progress bar musik disinkronkan secara real-time menggunakan stream audio.

### 3. Sistem Skor Dinamis & Real-time
- **Jawaban Benar**: +50 s/d +600 poin (random).
- **Menang Game**: +600 s/d +1500 poin bonus.
- **Kalah/Eliminasi**: -100 s/d -500 poin.
- **Real-time Sync**: Skor tertinggi di menu utama langsung diperbarui begitu permainan selesai tanpa perlu restart aplikasi.

### 4. Native In-App Updater
Aplikasi dapat memperbarui dirinya sendiri dengan mengambil `version.json` dari server:
- **Android**: Otomatis mendownload APK dan memicu installer sistem.
- **Windows/Linux**: Mendownload ZIP, mengekstrak, dan menjalankan script updater (`.sh`/`.ps1`) untuk mengganti file lama sambil menampilkan log proses.

## 🚀 Build & Distribusi

Untuk memudahkan distribusi, gunakan script master release yang tersedia:

```bash
# Memberikan izin eksekusi
chmod +x build_apk.sh

# Jalankan script untuk build Linux & Android sekaligus
./build_apk.sh
```

---
**Developed with ❤️ by Sakum Studios**
