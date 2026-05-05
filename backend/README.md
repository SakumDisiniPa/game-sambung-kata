# Sambung Kata Backend (Node.js)

Relay server untuk memungkinkan mabar online melalui internet menggunakan WebSocket.

## 🚀 Cara Deploy ke VPS

1. **Persiapan di VPS:**
   Pastikan Node.js sudah terinstal di VPS kamu.
   ```bash
   node -v
   ```

2. **Copy Folder Backend:**
   Upload atau git pull folder `backend` ini ke VPS kamu.

3. **Install Dependencies:**
   Masuk ke folder backend dan jalankan:
   ```bash
   npm install
   ```

4. **Buka Port Firewall:**
   Pastikan port 8000 sudah terbuka:
   ```bash
   sudo ufw allow 8000
   ```

5. **Jalankan Server dengan PM2 (Recommended):**
   Agar server jalan terus di background:
   ```bash
   npm install -g pm2
   pm2 start server.js --name "sambung-kata-backend"
   pm2 save
   pm2 startup
   ```

## 🔗 Endpoint
URL koneksi dari Flutter:
`ws://43.106.117.177:8000/[ID_ROOM_KAMU]`

## 🛠 Pengembangan Lokal
```bash
npm run dev
```
