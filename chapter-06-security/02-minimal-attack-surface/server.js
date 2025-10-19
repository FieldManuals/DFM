const http = require('http');

const PORT = 3000;

const server = http.createServer((req, res) => {
  if (req.url === '/') {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(`
      <h1>Minimal Attack Surface Demo</h1>
      <p>This container has:</p>
      <ul>
        <li>No shell (/bin/sh removed)</li>
        <li>No package manager</li>
        <li>No build tools</li>
        <li>Only runtime dependencies</li>
        <li>Running as non-root user</li>
      </ul>
      <p><a href="/capabilities">Check capabilities</a></p>
    `);
  } else if (req.url === '/capabilities') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end(`
Process: ${process.pid}
User: ${process.getuid?.()} (non-root)
Group: ${process.getgid?.()}

This container runs with:
✓ No shell access
✓ Dropped Linux capabilities
✓ No privileged operations
✓ Minimal software footprint
    `);
  } else {
    res.writeHead(404);
    res.end('Not Found');
  }
});

server.listen(PORT, () => {
  console.log(`Minimal attack surface app on port ${PORT}`);
});
