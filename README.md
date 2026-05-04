# 🎮 Game Sambung Kata - Multiplatform P2P & AI

Aplikasi permainan **Sambung Kata** berbasis Flutter yang modern dan kompetitif. Bisa dimainkan bersama teman dalam jaringan lokal (P2P) atau melawan komputer (AI) dengan berbagai tingkat kesulitan.

## ✨ Fitur Utama

- **Multiplayer P2P Lokal**: Bermain bersama teman dalam satu jaringan Wi-Fi tanpa perlu server terpusat.
- **AI Opponent (Single Player)**: Lawan komputer dengan 3 tingkat kesulitan (Mudah, Normal, Sulit). AI memiliki perilaku manusiawi (bisa bingung, typo, dan kecepatan mengetik bervariasi).
- **Sistem Skor & XP**: Dapatkan poin setiap kata benar. Poin bersifat publik dan tersimpan secara lokal (High Score).
- **Auto-Update Native**: Sistem update otomatis di dalam aplikasi untuk Android (OTA APK) dan Desktop (ZIP Extractor).
- **UDP Discovery**: Sistem pencarian room otomatis menggunakan broadcast UDP.
- **Sinkronisasi Real-time**: Lihat apa yang diketik lawan secara langsung (*typing indicator*).
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
- **Mudah**: Kata pendek, ngetik lambat, sering typo dan bingung.
- **Sulit**: Kata panjang, gacor, ngetik cepat, dan jarang salah.
- **Simulasi Bingung**: AI bisa mengetik huruf acak lalu menghapusnya kembali (backspace) jika sedang "berpikir".

### 2. Sistem Skor Dinamis
- **Jawaban Benar**: +50 s/d +600 poin (random).
- **Menang Game**: +600 s/d +1500 poin bonus.
- **Kalah/Eliminasi**: -100 s/d -500 poin.
- Skor pemain tampil di bawah profil (*Hearts*) dan bersifat publik (bisa dilihat semua pemain).

### 3. Native In-App Updater
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

Script ini akan:
1. Membersihkan folder distribusi lama di direktori web.
2. Membuild Linux Bundle, men-ZIP-nya (`bundle.zip`), dan mengirim ke folder web.
3. Membuild Android APK (`app-release.apk`) dan mengirim ke folder web.

## 📂 Struktur Folder
```text
lib/
├── core/             # Networking & App Constants
├── features/
│   ├── game/         # Logika & UI Permainan
│   └── lobby/        # UI Lobby & Room Management
├── models/           # GameState, UpdateInfo, dll
└── services/         # AI, Update, Dictionary, Sound, Storage
```

---
**Developed with ❤️ by Sakum Studios**
