const https = require('https');
const express = require('express');
const cron = require('node-cron');
const { createProxyMiddleware } = require('http-proxy-middleware');
const startStrapi = require("@strapi/strapi/lib/Strapi");

const app = express();
let lastReqDateTime = Date.now();

const timeout = process.env.STRAPI_TIMEOUT ? parseInt(process.env.STRAPI_TIMEOUT) : 600 ;
const functionAppUrl = process.env.FUNCTION_APP_URL;

function onProxyReq(proxyReq, req, res) {
  lastReqDateTime = Date.now();
}

const options = {
  target: process.env.STRAPI_URL ?? 'http://localhost:1337',
  onProxyReq: onProxyReq
};

app.use(
  '/*',
  createProxyMiddleware(options)
);

app.get("/*", )

const port = process.env.EXPRESS_PORT ?? "8080"

app.listen(port, async () => {

    if (!global.strapi) {
        console.log("[Strapi] cold start");
        await startStrapi({ dir: __dirname }).start();
    }
    console.log(`[Express] Listening on port ${port}`);
})

cron.schedule('*/5 * * * *', () => {
  let now = Date.now();
  let diff = Math.abs(now - lastReqDateTime) / 1000;
  console.log(`[Cron] Last request was ${diff} seconds ago.`);
  if(diff > timeout) {
    console.log(`[Cron] Process exit with code 0.`);
    if(functionAppUrl != null) {
      https.get(functionAppUrl, (res) => {
        console.log(`statusCode: ${res.statusCode}`);
        let content = [];
        res.on('data', (data) => {
          content.push(data);
        });
        res.on('end', () => {
          let body = Buffer.concat(content);
          console.log("[Cron] " + body.toString());
          process.exit(0);
        });
        res.on('error', (error) => {
          console.log(error);
        });
      });
    }
  }
});
