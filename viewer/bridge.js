// USC LPL Ranger Bridge V0.1
// Serves a web-based viewer at http://127.0.0.1:8080 (open in your browser), relays Simulink's UDP 
// telemetry (port 50000) to it as server-sent events.

const http = require('http');
const fs = require('fs');
const path = require('path');
const dgram = require('dgram');

const files = {
  '/': ['index.html', 'text/html'],
  '/main.js': ['main.js', 'text/javascript'],
  '/ranger.urdf': ['ranger.urdf', 'application/xml'],
  '/pad.png': ['pad.png', 'image/png'],
};
const clients = new Set();

// probably want an actual js toolkit if things get more complicated here. bun.js in the future mabey?
http.createServer((req, res) => {
  if (req.url === '/telemetry') {
    res.writeHead(200, { 'Content-Type': 'text/event-stream' });
    clients.add(res);
    req.on('close', () => clients.delete(res));
    return;
  }
  const file = files[req.url];
  if (!file) return res.writeHead(404).end();
  fs.readFile(path.join(__dirname, file[0]), (err, data) => {
    if (err) return res.writeHead(404).end();
    res.writeHead(200, { 'Content-Type': file[1] }).end(data);
  });
}).listen(8080, '127.0.0.1', () => console.log('Viewer: http://127.0.0.1:8080'));

dgram.createSocket('udp4')
  .on('message', msg => clients.forEach(res => res.write(`data: ${msg}\n\n`)))
  .bind(50000, '127.0.0.1');
