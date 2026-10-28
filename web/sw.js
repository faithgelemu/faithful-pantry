"use strict";

// Generated after each release build.
importScripts("./sw-assets.js");

const CACHE_PREFIX = "faithful-pantry-shell-";
const CACHE_NAME = CACHE_PREFIX + self.PANTRY_PRECACHE.version;

const APP_ROOT = new URL("./", self.location.href);
const INDEX_URL = new URL("index.html", APP_ROOT).href;

const ASSET_URLS = self.PANTRY_PRECACHE.files.map(
  (file) => new URL(file, APP_ROOT).href
);

const ALLOWED_ASSETS = new Set(ASSET_URLS);

self.addEventListener("install", (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE_NAME);

      try {
        await cache.addAll(
          ASSET_URLS.map(
            (url) => new Request(url, { cache: "reload" })
          )
        );
      } catch (error) {
        await caches.delete(CACHE_NAME);
        throw error;
      }
    })()
  );

  // Updates wait until existing app windows have closed.
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      const names = await caches.keys();

      await Promise.all(
        names
          .filter(
            (name) =>
              name.startsWith(CACHE_PREFIX) &&
              name !== CACHE_NAME
          )
          .map((name) => caches.delete(name))
      );

      await self.clients.claim();
    })()
  );
});

self.addEventListener("fetch", (event) => {
  const request = event.request;

  if (request.method !== "GET") return;

  const url = new URL(request.url);

  // Leave Firebase and other external services alone.
  if (url.origin !== APP_ROOT.origin) return;

  if (!url.pathname.startsWith(APP_ROOT.pathname)) return;

  if (request.mode === "navigate") {
    event.respondWith(
      (async () => {
        const cache = await caches.open(CACHE_NAME);
        const savedPage = await cache.match(INDEX_URL);

        return savedPage || fetch(request);
      })()
    );

    return;
  }

  // Ignore query parameters when matching known app assets.
  url.search = "";
  url.hash = "";

  if (!ALLOWED_ASSETS.has(url.href)) return;

  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      const savedAsset = await cache.match(url.href);

      return savedAsset || fetch(request);
    })()
  );
});