# 🎮 Game Sambung Kata - Multiplatform P2P & AI

Aplikasi permainan **Sambung Kata** berbasis Flutter yang modern dan kompetitif. Bisa dimainkan bersama teman dalam jaringan lokal (P2P) atau melawan komputer (AI) dengan berbagai tingkat kesulitan.

## ✨ Fitur Utama

- **Multiplayer P2P Lokal**: Bermain bersama teman dalam satu jaringan Wi-Fi tanpa perlu server terpusat.
- **AI Opponent (Single Player)**: Lawan komputer dengan 3 tingkat kesulitan (Mudah, Normal, Sulit). AI memiliki perilaku manusiawi (bisa bingung, typo, dan kecepatan mengetik bervariasi).
- **Music Player In-Game**: Playlist musik acak dari folder aset dengan kontrol penuh (Play/Pause, Skip, Back) dan progress bar real-time.
- **Sistem Skor & XP Real-time**: Poin diperbarui secara instan dan skor tertinggi (High Score) tersinkronisasi otomatis setelah permainan selesai.
- **Auto-Update Native**: Sistem update otomatis di dalam aplikasi untuk Android (OTA APK) dan Desktop (ZIP Extractor).
- **UDP Discovery**: Sistem pencarian room otomatis menggunakan broadcast UDP.
- **Interactive Audio**: Efek suara ketikan mesin tik (Typing SFX) yang terdengar untuk semua pemain, menambah atmosfer kompetitif.
- **Visual Feedback**: Indikator warna dinamis (Hijau untuk benar, Merah untuk salah/duplikat) pada kotak input.
- **Kamus Internasional**: Validasi kata menggunakan dataset kosakata yang luas.
- **Aesthetic Cyberpunk UI**: Antarmuka modern dengan Google Fonts (Outfit), animasi halus, dan efek suara interaktif.

## 🛠️ Teknologi yang Digunakan

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Networking**: `shelf`, `shelf_web_socket`, `web_socket_channel`, `RawDatagramSocket` (UDP)
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
