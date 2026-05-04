# 🎮 Game Sambung Kata - P2P Multiplayer

Aplikasi permainan **Sambung Kata** berbasis Flutter yang memungkinkan pemain bermain bersama dalam jaringan lokal menggunakan sistem **P2P (Peer-to-Peer)**. Game ini menantang kecepatan berpikir dan kosakata pemain untuk menyambung kata berdasarkan awalan (prefix) yang diberikan.

## ✨ Fitur Utama
- **Multiplayer P2P Lokal**: Bermain bersama teman dalam satu jaringan Wi-Fi tanpa perlu server terpusat.
- **UDP Discovery**: Sistem pencarian room otomatis menggunakan broadcast UDP. Pemain cukup memasukkan Kode Room untuk terhubung.
- **Sistem Prefix Progresif**: Kesulitan meningkat seiring bertambahnya ronde. Awalan kata akan bertambah panjang (1-5 huruf) di fase *late game*.
- **Sinkronisasi Real-time**: Ketikan lawan dapat dilihat secara langsung (*typing indicator*) untuk menambah keseruan.
- **Kamus Internasional**: Validasi kata menggunakan dataset kosakata yang komprehensif (`datasetinternasional.csv`).
- **Efek Suara & Visual Modern**: Antarmuka dengan tema *dark mode/cyan glow* dan efek suara interaktif.

## 🛠️ Teknologi yang Digunakan
- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Networking**:
  - `shelf` & `shelf_web_socket` (Host Server)
  - `web_socket_channel` (Client Connection)
  - `RawDatagramSocket` (UDP Broadcasting untuk Discovery)
- **Audio**: `audioplayers`
- **Fonts**: Google Fonts (Outfit)

## 🏗️ Arsitektur & Cara Kerja Sistem

### 1. Mekanisme Networking (P2P Hybrid)
Game ini menggunakan model *Host-Client* yang berjalan secara lokal:
- **Host Role**: Saat pemain membuat room, aplikasi menjalankan server HTTP/WebSocket (via `shelf`) dan mulai memancarkan sinyal (UDP Broadcast) di port `45451`. Sinyal ini berisi informasi: `SK_ID|KODE_ROOM|IP_ADDRESS|PORT`.
- **Client Role**: Saat pemain ingin bergabung, aplikasi mendengarkan paket UDP di port yang sama. Jika Kode Room yang diterima cocok dengan yang dicari, Client akan langsung menginisiasi koneksi WebSocket ke IP Host.
- **Data Sync**: Seluruh status permainan dikelola oleh Host dan disinkronkan ke Client setiap kali ada perubahan status (sinkronisasi state).

### 2. Aturan Permainan (Game Rules)
- **Input & Validasi**: Pemain harus mengetik kata yang dimulai dengan huruf awalan (prefix) yang ditentukan. Kata tersebut harus valid di kamus dan belum pernah digunakan sebelumnya dalam ronde tersebut.
- **Sistem Nyawa (HP)**: Setiap pemain memiliki 4 nyawa. Nyawa akan berkurang jika:
  1. Waktu habis (Timer mencapai 0).
  2. Salah memasukkan kata sebanyak 3 kali berturut-turut dalam satu giliran.
- **Skalabilitas Kesulitan**:
  - **Early Game (Ronde < 20)**: Prefix diambil secara acak sebanyak 1-3 huruf dari akhir kata sebelumnya.
  - **Late Game (Ronde >= 20)**: Prefix menjadi lebih menantang dengan panjang 3-5 huruf.

### 3. Sinkronisasi Ketikan (Typing Indicator)
Salah satu fitur unik adalah sinkronisasi ketikan. Setiap karakter yang diketik oleh pemain aktif akan dikirimkan secara real-time ke lawan melalui WebSocket, sehingga lawan bisa melihat apa yang sedang diketik sebelum kata tersebut di-submit.

## 📂 Struktur Folder Utama
```text
lib/
├── core/
│   └── network/          # Logika Networking (UDP & WebSocket)
├── features/
│   └── game/
│       ├── providers/    # Logic Provider (Riverpod)
│       ├── views/        # UI Screen (GameView)
│       └── widgets/      # Komponen UI (Keyboard, PlayerCard, dll)
├── models/               # Data Model (GameState, GameRoom)
└── services/             # Service (Dictionary, Audio, GameRules)
```

## 🚀 Cara Menjalankan
1. Pastikan Flutter SDK sudah terinstal.
2. Clone repository dan jalankan `flutter pub get`.
3. Pastikan semua perangkat berada dalam **jaringan Wi-Fi yang sama**.
4. Jalankan aplikasi di dua perangkat atau lebih.
5. Satu pemain memilih **BUAT ROOM**, pemain lain memilih **JOIN ROOM** dengan Kode Room yang sama.

---
**Dibuat oleh Sakum Studios**
