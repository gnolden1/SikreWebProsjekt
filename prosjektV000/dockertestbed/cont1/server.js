const http = require('http');

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Hello, Docker World!\n');
});

const port = 3000;
server.listen(port, '0.0.0.0', () => {
  console.log(`Server is running on http://0.0.0.0:${port}/`);
});
