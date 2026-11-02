const net = require('net');

const TARGET_PORT = 8080;
const TARGET_HOST = '192.168.88.104';
const LISTEN_PORT = 8080;
const LISTEN_HOST = '127.0.0.1';

const server = net.createServer((socket) => {
  const client = net.connect(TARGET_PORT, TARGET_HOST);
  socket.pipe(client).pipe(socket);
  socket.on('error', () => {});
  client.on('error', () => {});
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    // 127.0.0.1:8080 is already listening (e.g. backend directly on 0.0.0.0), no proxy needed.
    process.exit(0);
  }
});

server.listen(LISTEN_PORT, LISTEN_HOST, () => {
  console.log(`ADB reverse bridge active: ${LISTEN_HOST}:${LISTEN_PORT} -> ${TARGET_HOST}:${TARGET_PORT}`);
});
