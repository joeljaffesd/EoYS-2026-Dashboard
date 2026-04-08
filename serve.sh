#!/usr/bin/env bash
# Serves the current directory on localhost, starting at port 3000.
# Automatically increments the port if it's already in use.

PORT=${1:-3000}
MAX_PORT=$((PORT + 20))

while [ "$PORT" -le "$MAX_PORT" ]; do
  if ! lsof -iTCP:"$PORT" -sTCP:LISTEN -t >/dev/null 2>&1; then
    break
  fi
  echo "Port $PORT is in use, trying $((PORT + 1))..."
  PORT=$((PORT + 1))
done

if [ "$PORT" -gt "$MAX_PORT" ]; then
  echo "Error: No available port found in range."
  exit 1
fi

echo "Serving on http://localhost:$PORT"

node -e "
const http = require('http');
const fs = require('fs');
const path = require('path');

const MIME = {
  '.html': 'text/html',
  '.css':  'text/css',
  '.js':   'application/javascript',
  '.json': 'application/json',
  '.png':  'image/png',
  '.jpg':  'image/jpeg',
  '.svg':  'image/svg+xml',
  '.ico':  'image/x-icon',
};

const server = http.createServer((req, res) => {
  let url = req.url.split('?')[0];
  if (url === '/') url = '/index.html';
  const filePath = path.join(process.cwd(), url);
  const ext = path.extname(filePath);

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('Not found');
      return;
    }
    res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
    res.end(data);
  });
});

server.listen(${PORT}, () => {
  console.log('Ready');
});
"
