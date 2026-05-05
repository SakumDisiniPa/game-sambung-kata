# 🚀 Sambung Kata - Update Log (v1.0.0+1)

Daftar perubahan terbaru dan peningkatan fitur pada permainan Sambung Kata.

## 🤖 Peningkatan AI (Computer Opponent)
- **Simulasi Mengetik Manusia**: Komputer sekarang memiliki animasi mengetik karakter-per-karakter dengan kecepatan yang disesuaikan (Easy, Medium, Hard).
- **Logika Typo & Berpikir**: Komputer terkadang melakukan kesalahan pengetikan atau kebingungan sesaat sebelum mengoreksi katanya, memberikan kesan bermain melawan manusia asli.
- **Turn-Safety Logic**: Memperbaiki bug di mana komputer tetap mengirim jawaban setelah waktunya habis (Race Condition). Sekarang giliran jauh lebih stabil.

## 🎵 Fitur Baru: Music Player In-Game
- **Playlist Random**: Musik latar saat bermain sekarang diambil secara acak dari folder `assets/audio/ingame/`.
- **Music Controller Bar**: Widget kontrol di bagian tengah atas layar untuk **Play/Pause**, **Skip Next**, dan **Previous**.
- **Progress Bar**: Indikator durasi lagu berupa bar tipis cyan yang berjalan secara real-time.
- **Auto-Transition**: Lagu akan otomatis berpindah ke lagu berikutnya saat durasi habis.

## ✨ Peningkatan Visual & Feedback
- **Color Glow Feedback**:
  - **Hijau**: Menyala terang saat jawaban benar (disertai delay 400ms agar mata sempat melihat).
  - **Merah**: Menyala saat kata tidak valid atau sudah pernah digunakan.
- **Smart Cursor**: Kursor pengetikan akan disembunyikan saat umpan balik warna muncul untuk tampilan yang lebih bersih.
- **Cyberpunk Aesthetics**: Penyesuaian transparansi (glassmorphism) pada berbagai elemen UI.

## 🛠️ Perbaikan Teknis & Stabilitas
- **Optimasi Volume**: Penyesuaian volume global (BGM: 0.3, SFX: 0.6) agar lebih nyaman di telinga.
- **Smart Update System**: Memperbaiki deteksi versi aplikasi agar lebih akurat dan tidak memunculkan notifikasi update jika versi sudah sama.
- **Asset Management**: Perbaikan pendaftaran aset audio di `pubspec.yaml` untuk mencegah crash saat loading lagu.
- **Dependency Fix**: Mengembalikan library mabar (P2P) dan networking yang sempat hilang untuk memastikan fitur multiplayer tetap jalan.
- **Build Automation**: Penyempurnaan script `build_apk.sh` untuk distribusi otomatis ke folder web hosting.

---
*Dibuat dengan ❤️ oleh Antigravity AI & SakumDisiniPa*
