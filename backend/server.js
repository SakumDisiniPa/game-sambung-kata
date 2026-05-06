const WebSocket = require('ws');
const url = require('url');
const fs = require('fs');
const path = require('path');

const PORT = 8000;
const wss = new WebSocket.Server({ port: PORT });
const rooms = new Map();

// Path untuk simpan Leaderboard Top 10
const SCORE_FILE = path.join(__dirname, 'global_leaderboard.json');

// Fungsi Helper untuk baca/tulis data skor
function loadLeaderboard() {
    if (!fs.existsSync(SCORE_FILE)) return [];
    try {
        const data = JSON.parse(fs.readFileSync(SCORE_FILE, 'utf8'));
        return Array.isArray(data) ? data : [];
    } catch (e) {
        return [];
    }
}

function submitScore(userId, player, score) {
    let leaderboard = loadLeaderboard();
    
    // Cek apakah User ID sudah ada di list
    const existingIndex = leaderboard.findIndex(item => item.id === userId);
    
    if (existingIndex !== -1) {
        // Update nama kalau ganti nama, dan update skor kalau lebih tinggi
        leaderboard[existingIndex].player = player;
        if (score > leaderboard[existingIndex].score) {
            leaderboard[existingIndex].score = score;
            leaderboard[existingIndex].date = new Date().toISOString();
        } else if (score === 0) {
             // Kalau cuma sync profil (score 0 dari client), jangan update skor
        }
    } else {
        // Tambah baru
        leaderboard.push({
            id: userId,
            player: player,
            score: score,
            date: new Date().toISOString()
        });
    }

    // Sortir: Terbesar ke terkecil
    leaderboard.sort((a, b) => b.score - a.score);

    // Ambil Top 10 saja
    leaderboard = leaderboard.slice(0, 10);

    fs.writeFileSync(SCORE_FILE, JSON.stringify(leaderboard, null, 2));
    return true;
}

console.log(`==========================================`);
console.log(`  Sambung Kata Relay Server Online`);
console.log(`  URL: ws://43.106.117.177:${PORT}/[ROOM_ID]`);
console.log(`  Mode: Global Leaderboard (Top 10)`);
console.log(`==========================================`);

wss.on('connection', (ws, req) => {
    const pathname = url.parse(req.url).pathname;
    const roomId = pathname ? pathname.substring(1).trim() : "";

    if (!roomId) {
        console.log("[REJECTED] No Room ID provided");
        ws.close();
        return;
    }

    if (!rooms.has(roomId)) {
        rooms.set(roomId, new Set());
    }
    const clients = rooms.get(roomId);
    clients.add(ws);

    console.log(`[JOIN] Room: ${roomId} | Total Clients: ${clients.size}`);

    // Kirim Leaderboard saat baru konek
    ws.send(JSON.stringify({
        type: 'leaderboard_update',
        topPlayers: loadLeaderboard().slice(0, 3) // Kirim Top 3 saja buat efisiensi
    }));

    ws.on('message', (data) => {
        let msg;
        try {
            msg = JSON.parse(data.toString());
        } catch (e) {
            msg = {};
        }

        if (msg.type === 'submit_score' || msg.type === 'sync_profile') {
            const userId = msg.userId || "GUEST";
            const player = msg.player || "Anonim";
            const score = parseInt(msg.score) || 0;

            const isUpdated = submitScore(userId, player, score);
            if (isUpdated) {
                console.log(`[SYNC/SCORE] ${player} (${userId}) -> ${score}`);

                // Broadcast Leaderboard baru ke SEMUA orang di SEMUA room
                const updateMsg = JSON.stringify({
                    type: 'leaderboard_update',
                    topPlayers: loadLeaderboard().slice(0, 3)
                });
                
                wss.clients.forEach(client => {
                    if (client.readyState === WebSocket.OPEN) {
                        client.send(updateMsg);
                    }
                });
            }
            return;
        }

        if (msg.type === 'get_leaderboard') {
            ws.send(JSON.stringify({
                type: 'leaderboard_update',
                topPlayers: loadLeaderboard().slice(0, 3)
            }));
            return;
        }

        // Teruskan pesan game normal ke room yang sama
        clients.forEach((client) => {
            if (client !== ws && client.readyState === WebSocket.OPEN) {
                client.send(data.toString());
            }
        });
    });

    ws.on('close', () => {
        clients.delete(ws);
        
        // Beritahu pemain lain kalau ada yang kabur/diskonek
        const leaveMsg = JSON.stringify({
            type: 'player_left',
            player: playerName,
            message: `${playerName} terputus dari permainan`
        });
        
        clients.forEach(client => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(leaveMsg);
            }
        });

        console.log(`[LEAVE] Room: ${roomId} | Remaining: ${clients.size}`);
        if (clients.size === 0) {
            rooms.delete(roomId);
            console.log(`[CLEANUP] Room ${roomId} deleted`);
        }
    });

    ws.on('error', (err) => {
        console.error(`[ERROR] Room ${roomId}:`, err.message);
    });
});

