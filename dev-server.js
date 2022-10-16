import * as fs from "fs";
import * as http from "http";
import * as https from "https";
import * as path from "path";
import { fileURLToPath } from "url";

const ROOT = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  "concourse",
  "web"
);

const DEV_SERVER_PORT = 8080;

const MIME_TYPES = {
  ".css": "text/css; charset=utf-8",
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json",
  ".mjs": "text/javascript; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".ttf": "font/ttf",
  ".txt": "text/plain",
  ".wasm": "application/wasm",
};

function looksLikeFile(url) {
  return /\.\w+(\?.*)?$/.test(url);
}

function serveFile(req, res, log, newUrl) {
  if (req.url === newUrl) {
    serveFileHelper(req, res, log);
  } else {
    req.url = newUrl;
    serveFileHelper(req, res, (...args) => log(`-> ${newUrl}`, ...args));
  }
}

function serveFileHelper(req, res, log) {
  log(200);
  res.writeHead(200, { "Content-Type": MIME_TYPES[path.extname(req.url)] });
  fs.createReadStream(path.join(ROOT, req.url)).pipe(res, { end: true });
}

function proxyToWeb(req, res, log, hostname) {
  const options = {
    hostname,
    path: req.url,
    method: req.method,
    headers: { ...req.headers, host: hostname },
  };

  const proxyReq = https.request(options, (proxyRes) => {
    const { statusCode } = proxyRes;
    log(`-> ${hostname}`, statusCode);
    res.writeHead(statusCode, proxyRes.headers);
    proxyRes.pipe(res, { end: true });
  });

  proxyReq.on("error", (error) => {
    log(503);
    res.writeHead(503);
    res.end(`Failed to proxy to ${hostname}. Is it down?\n\n${error.stack}`);
  });

  req.pipe(proxyReq, { end: true });
}

function makeLog(req) {
  const startTime = new Date();
  const originalRequest = `${req.method} ${req.headers.host} ${req.url}`;
  return (...args) => {
    console.info(
      formatTime(startTime),
      originalRequest,
      ...args,
      "|",
      Date.now() - startTime.getTime(),
      "ms"
    );
  };
}

function formatTime(date) {
  return [date.getHours(), date.getMinutes(), date.getSeconds()]
    .map((number) => number.toString().padStart(2, "0"))
    .join(":");
}

const server = http.createServer((req, res) => {
  const log = makeLog(req);
  if (req.url.startsWith("/api/")) {
    proxyToWeb(req, res, log, "ci.concourse-ci.org");
  } else {
    serveFile(
      req,
      res,
      log,
      looksLikeFile(req.url) ? req.url : "/public/index.html"
    );
  }
});

server.listen(DEV_SERVER_PORT, () => {
  console.log(`Server ready at: http://localhost:${DEV_SERVER_PORT}`);
});
