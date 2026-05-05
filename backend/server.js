const WebSocket = require('ws');
const url = require('url');

const PORT = 8000;
const wss = new WebSocket.Server({ port: PORT });
const rooms = new Map();

console.log(`==========================================`);
console.log(`  Sambung Kata Relay Server Online`);
console.log(`  URL: ws://43.106.117.177:${PORT}/[ROOM_ID]`);
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

    ws.on('message', (data) => {
        // Log pesan masuk (opsional, matikan jika terlalu ramai)
        // console.log(`[MSG] Room ${roomId}: ${data}`);

        // Teruskan ke semua orang di room yang sama (termasuk pengirim jika perlu sync)
        // Tapi biasanya kita teruskan ke orang lain saja
        clients.forEach((client) => {
            if (client !== ws && client.readyState === WebSocket.OPEN) {
                client.send(data.toString());
            }
        });
    });

    ws.on('close', () => {
        clients.delete(ws);
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

