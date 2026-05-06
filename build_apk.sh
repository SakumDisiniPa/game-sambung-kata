#!/bin/bash

# Konfigurasi Path
WEB_PATH="/home/sakum-disini-pa/Downloads"
WEB_ANDROID_DIR="$WEB_PATH/app/android"
WEB_LINUX_DIR="$WEB_PATH/app/linux"

echo "=== MEMULAI PROSES RELEASE MULTIPLATFORM ==="

# 1. Info Versi
VERSION_LINE=$(grep "version: " pubspec.yaml)
echo "Versi yang akan di-build: $VERSION_LINE"

# 2. Persiapan Folder Website
echo "2. Membersihkan folder distribusi lama..."
mkdir -p "$WEB_ANDROID_DIR"
mkdir -p "$WEB_LINUX_DIR"
rm -f "$WEB_ANDROID_DIR"/*.apk
rm -f "$WEB_LINUX_DIR"/*.zip

# 3. Build Linux (Didahulukan karena lebih cepat)
echo "3. Building Linux App (Release)..."
flutter build linux --release
if [ $? -eq 0 ]; then
    echo "Mengekstrak bundle ke bundle.zip..."
    # Masuk ke folder bundle biar isi ZIP-nya gak pake path panjang
    cd build/linux/x64/release/bundle
    zip -r ../../../../../bundle.zip .
    cd -
    mv bundle.zip "$WEB_LINUX_DIR/"
    echo "✔ bundle.zip Berhasil dipindah ke $WEB_LINUX_DIR"
else
    echo "✘ Gagal build Linux!"
    exit 1
fi

# 4. Build Android
echo "4. Building Android APK (Release)..."
flutter build apk --release
if [ $? -eq 0 ]; then
    cp build/app/outputs/flutter-apk/app-release.apk "$WEB_ANDROID_DIR/app-release.apk"
    echo "✔ app-release.apk Berhasil dipindah ke $WEB_ANDROID_DIR"
else
    echo "✘ Gagal build Android!"
    exit 1
fi

echo ""
echo "=== SEMUA PROSES SELESAI ==="
echo "Lokasi Website: $WEB_PATH"
echo "Silakan update 'version.json' di website dengan versi tersebut."
echo "Lalu push folder website abang ke hostingan!"
