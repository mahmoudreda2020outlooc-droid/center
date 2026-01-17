const CACHE_NAME = 'elmohaseb-v3.1'; // Bumped version
const ASSETS = [
    './',
    './index.html',
    './login.html',
    './css/style.css',
    './js/appwrite-config.js',
    './js/db-appwrite.js',
    './img/logo.jpg',
    './manifest.json'
];

// Install Event
self.addEventListener('install', (event) => {
    self.skipWaiting(); // Force activation
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then((cache) => cache.addAll(ASSETS))
    );
});

// Activate Event: Clear old caches
self.addEventListener('activate', (event) => {
    event.waitUntil(
        caches.keys().then((keys) => {
            return Promise.all(
                keys.filter(key => key !== CACHE_NAME)
                    .map(key => caches.delete(key))
            );
        })
    );
});

// Fetch Event: Network-First for HTML/Manifest, Cache-First for assets
self.addEventListener('fetch', (event) => {
    const url = new URL(event.request.url);

    // Performance: Network-First for dynamic content
    if (event.request.mode === 'navigate' || url.pathname.endsWith('.html')) {
        event.respondWith(
            fetch(event.request)
                .then(response => {
                    const copy = response.clone();
                    caches.open(CACHE_NAME).then(cache => cache.put(event.request, copy));
                    return response;
                })
                .catch(() => caches.match(event.request))
        );
    } else {
        // Cache-First for static assets
        event.respondWith(
            caches.match(event.request)
                .then((response) => response || fetch(event.request))
        );
    }
});
