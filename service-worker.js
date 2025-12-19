const CACHE_NAME = 'litecode-pwa-v1';
const urlsToCache = [
  './',  // ⚠️ PERHATIKAN: "./" bukan "/"
  './index.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png',
  'https://cdn.tailwindcss.com',  // CDN external
  'https://cdnjs.cloudflare.com/ajax/libs/ace/1.32.2/ace.js'
];

self.addEventListener('install', event => {
  console.log('🟢 Service Worker installing...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('📦 Caching app shell');
        return cache.addAll(urlsToCache);
      })
  );
});

self.addEventListener('fetch', event => {
  // ⚠️ IGNORE chrome-extension:// dan data: URLs
  if (event.request.url.startsWith('chrome-extension://') || 
      event.request.url.startsWith('data:')) {
    return;
  }
  
  event.respondWith(
    caches.match(event.request)
      .then(cachedResponse => {
        if (cachedResponse) {
          console.log('📂 From cache:', event.request.url);
          return cachedResponse;
        }
        
        return fetch(event.request)
          .then(response => {
            // Don't cache if not a valid response
            if (!response || response.status !== 200 || response.type !== 'basic') {
              return response;
            }
            
            // Clone the response
            const responseToCache = response.clone();
            
            caches.open(CACHE_NAME)
              .then(cache => {
                cache.put(event.request, responseToCache);
              });
              
            return response;
          })
          .catch(error => {
            console.log('❌ Fetch failed:', error);
            // Fallback page for offline
            if (event.request.mode === 'navigate') {
              return caches.match('./index.html');
            }
          });
      })
  );
});

self.addEventListener('activate', event => {
  console.log('🟡 Service Worker activating...');
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            console.log('🗑️ Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});
