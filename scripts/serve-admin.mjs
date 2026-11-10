import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');
const webDir = path.join(projectRoot, 'web');

const PORT = process.env.PORT || 8080;

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
};

const server = http.createServer((req, res) => {
  const urlPath = decodeURIComponent(req.url.split('?')[0]);
  let filePath;

  if (urlPath === '/' || urlPath === '/admin' || urlPath === '/admin.html') {
    filePath = path.join(webDir, 'admin.html');
  } else {
    // Check in web/ first, then repo root
    const testWeb = path.join(webDir, urlPath);
    if (fs.existsSync(testWeb) && fs.statSync(testWeb).isFile()) {
      filePath = testWeb;
    } else {
      filePath = path.join(projectRoot, urlPath);
    }
  }

  if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
    res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end(`404 Not Found: ${urlPath}`);
    return;
  }

  const ext = path.extname(filePath).toLowerCase();
  const mime = MIME_TYPES[ext] || 'application/octet-stream';

  res.writeHead(200, {
    'Content-Type': mime,
    'Access-Control-Allow-Origin': '*',
  });
  fs.createReadStream(filePath).pipe(res);
});

server.listen(PORT, () => {
  console.log(`\n===========================================`);
  console.log(` GrindFit Admin Portal is running!`);
  console.log(` Live:    http://localhost:${PORT}/admin.html`);
  console.log(` Preview: http://localhost:${PORT}/admin.html?preview=1`);
  console.log(`===========================================\n`);
});
