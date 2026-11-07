import * as fs from "fs";
import * as http from "http";
import * as path from "path";
import { fileURLToPath } from "url";

const MIME_TYPES = {
  ".css": "text/css; charset=utf-8",
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json",
  ".js": "text/javascript; charset=utf-8",
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

function serveFile(root, req, res, log, newUrl) {
  if (req.url === newUrl) {
    serveFileHelper(root, req, res, log);
  } else {
    req.url = newUrl;
    serveFileHelper(root, req, res, (...args) => log(`-> ${newUrl}`, ...args));
  }
}

function serveFileHelper(root, req, res, log) {
  log(200);
  res.writeHead(200, {
    "Content-Type": MIME_TYPES[path.extname(req.url)] ?? "",
  });
  fs.createReadStream(path.join(root, req.url))
    .on("error", (error) => {
      log(404);
      res.writeHead(404);
      res.end(`File not found: ${req.url}\n\n${error.stack}`);
    })
    .pipe(res, { end: true });
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
      "ms",
    );
  };
}

function formatTime(date) {
  return [date.getHours(), date.getMinutes(), date.getSeconds()]
    .map((number) => number.toString().padStart(2, "0"))
    .join(":");
}

http
  .createServer((req, res) => {
    const log = makeLog(req);
    serveFile(
      path.join(path.dirname(fileURLToPath(import.meta.url)), "example"),
      req,
      res,
      log,
      looksLikeFile(req.url) ? req.url : "/index.html",
    );
  })
  .listen(8080, function () {
    console.log(
      `Small example ready at: http://localhost:${this.address().port}`,
    );
  });
