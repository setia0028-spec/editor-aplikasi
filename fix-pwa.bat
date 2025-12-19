@echo off
chcp 65001 >nul
echo ╔══════════════════════════════════╗
echo ║  PWA FIX - ICONS IN HEAD PROPER  ║
echo ╚══════════════════════════════════╝
echo.

echo [1/5] Creating manifest.json...
(
echo {
echo   "name": "LiteCode Editor",
echo   "short_name": "LiteCode",
echo   "start_url": ".",
echo   "scope": ".",
echo   "display": "standalone",
echo   "orientation": "portrait", 
echo   "background_color": "#0f172a",
echo   "theme_color": "#0f172a",
echo   "icons": [
echo     {"src": "icon-192.png", "sizes": "192x192", "type": "image/png"},
echo     {"src": "icon-512.png", "sizes": "512x512", "type": "image/png"}
echo   ]
echo }
) > manifest.json

echo [2/5] Creating PWA icons...
if exist "icon.png" (
  echo Creating icon-512.png...
  copy "icon.png" "icon-512.png" >nul
  
  echo Creating icon-192.png...
  powershell -Command "Add-Type -AssemblyName System.Drawing; $img=[Drawing.Image]::FromFile('icon-512.png'); $bmp=New-Object Drawing.Bitmap(192,192); $g=[Drawing.Graphics]::FromImage($bmp); $g.DrawImage($img,0,0,192,192); $bmp.Save('icon-192.png',[Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); $img.Dispose()"
  echo ✅ Icons created
) else (
  echo ❌ icon.png not found! Please add icon.png first.
  pause
  exit /b 1
)

echo [3/5] Creating service-worker.js...
(
echo const CACHE_NAME = 'litecode-pwa';
echo const urlsToCache = ['.', './index.html', './manifest.json', './icon-192.png', './icon-512.png'];
echo 
echo self.addEventListener('install', e => {
echo   e.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(urlsToCache)));
echo });
echo 
echo self.addEventListener('fetch', e => {
echo   e.respondWith(caches.match(e.request).then(response => response || fetch(e.request)));
echo });
) > service-worker.js

echo [4/5] Updating index.html HEAD section...
powershell -Command "
# Baca file index.html
\$content = Get-Content -Path 'index.html' -Raw

# Cek apakah sudah ada PWA tags
if (\$content -match 'rel=\"manifest\"') {
    Write-Host '⚠  PWA tags already exist. Replacing...'
    
    # Hapus tags PWA yang lama
    \$content = \$content -replace '<link[^>]*rel=\"manifest\"[^>]*>', ''
    \$content = \$content -replace '<link[^>]*rel=\"icon\"[^>]*>', ''
    \$content = \$content -replace '<link[^>]*rel=\"apple-touch-icon\"[^>]*>', ''
    \$content = \$content -replace '<meta[^>]*name=\"theme-color\"[^>]*>', ''
}

# PWA tags untuk HEAD
\$pwaTags = @'
<!-- ========== PWA CONFIGURATION ========== -->
<meta name=\"theme-color\" content=\"#0f172a\">
<link rel=\"manifest\" href=\"manifest.json\">
<link rel=\"icon\" type=\"image/png\" href=\"icon-192.png\" sizes=\"192x192\">
<link rel=\"apple-touch-icon\" href=\"icon-192.png\">
<!-- ====================================== -->
'@

# Masukkan tepat SEBELUM </head>
if (\$content -match '</head>') {
    \$content = \$content -replace '</head>', \"\$pwaTags</head>\"
    Write-Host '✅ PWA tags added to <head> section'
} else {
    Write-Host '❌ ERROR: </head> tag not found in index.html'
    Write-Host 'Please add PWA tags manually to <head> section'
}

# Service Worker script untuk BODY (sebelum </body>)
\$swScript = @'
<!-- Service Worker Registration -->
<script>
// Register Service Worker
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('service-worker.js')
      .then(reg => console.log('✅ Service Worker registered:', reg.scope))
      .catch(err => console.log('❌ Service Worker failed:', err));
  });
}

// Detect PWA mode
if (window.matchMedia('(display-mode: standalone)').matches) {
  document.documentElement.classList.add('pwa-mode');
  console.log('📱 Running in PWA mode');
}
</script>
'@

# Masukkan sebelum </body>
if (\$content -match '</body>') {
    \$content = \$content -replace '</body>', \"\$swScript</body>\"
    Write-Host '✅ Service Worker script added before </body>'
} else {
    Write-Host '⚠  </body> tag not found, adding at end of file'
    \$content += \$swScript
}

# Simpan file
Set-Content -Path 'index.html' -Value \$content -Encoding UTF8
Write-Host '✅ index.html updated successfully'
"

echo [5/5] Creating verification file...
(
echo ^<html^>
echo ^<head^>
echo   ^<title^>PWA Verification^</title^>
echo   ^<link rel="manifest" href="manifest.json"^>
echo   ^<link rel="icon" href="icon-192.png"^>
echo ^</head^>
echo ^<body style="padding:20px;font-family:Arial;"^>
echo   ^<h1^>PWA Verification^</h1^>
echo   ^<p^>Open browser DevTools (F12) and check:^</p^>
echo   ^<ol^>
echo     ^<li^>Application → Manifest (should show data)^</li^>
echo     ^<li^>Application → Service Workers (should be registered)^</li^>
echo     ^<li^>Look for "Install" button in address bar^</li^>
echo   ^</ol^>
echo   ^<p^>^<a href="index.html"^>Back to Main App^</a^>^</p^>
echo ^</body^>
echo ^</html^>
) > verify-pwa.html

echo.
echo ════════════════════════════════════════════════════
echo ✅ PWA SETUP COMPLETE!
echo ════════════════════════════════════════════════════
echo.
echo Files created:
echo - manifest.json      (PWA configuration)
echo - service-worker.js  (Offline cache)
echo - icon-192.png       (192x192 icon)
echo - icon-512.png       (512x512 icon)
echo - verify-pwa.html    (Test page)
echo.
echo 📁 Check your index.html - PWA tags are NOW in ^<head^>!
echo.
echo To test:
echo 1. Run: python -m http.server 8000
echo 2. Open: http://localhost:8000
echo 3. Press F12 → Application → Manifest
echo.
pause
