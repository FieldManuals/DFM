const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;
const CACHE_DIR = process.env.CACHE_DIR || '/tmp/app-cache';

const server = http.createServer((req, res) => {
  if (req.url === '/') {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(`
      <h1>Read-Only Filesystem Demo</h1>
      <p>This application runs with a read-only root filesystem.</p>
      <p>Try these endpoints:</p>
      <ul>
        <li><a href="/write-temp">Write to /tmp (allowed)</a></li>
        <li><a href="/write-root">Write to root (blocked)</a></li>
        <li><a href="/status">Check status</a></li>
      </ul>
    `);
  } else if (req.url === '/write-temp') {
    try {
      const testFile = path.join(CACHE_DIR, 'test.txt');
      fs.writeFileSync(testFile, 'Success! Temporary writes work.');
      res.writeHead(200, { 'Content-Type': 'text/plain' });
      res.end('✓ Write to /tmp successful (tmpfs mount)');
    } catch (err) {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end(`✗ Write failed: ${err.message}`);
    }
  } else if (req.url === '/write-root') {
    try {
      fs.writeFileSync('/test.txt', 'This should fail');
      res.writeHead(200, { 'Content-Type': 'text/plain' });
      res.end('✗ Write to root succeeded (security issue!)');
    } catch (err) {
      res.writeHead(200, { 'Content-Type': 'text/plain' });
      res.end(`✓ Write blocked by read-only filesystem: ${err.message}`);
    }
  } else if (req.url === '/status') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      readonly: true,
      cacheDir: CACHE_DIR,
      uptime: process.uptime(),
      memory: process.memoryUsage()
    }, null, 2));
  } else {
    res.writeHead(404);
    res.end('Not Found');
  }
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Cache directory: ${CACHE_DIR}`);
});
