@echo off
chcp 65001 >nul
echo ╔══════════════════════════════╗
echo ║  COMPLETE PWA FIX SCRIPT    ║
echo ╚══════════════════════════════╝
echo.

echo [1/6] Creating CORRECT manifest.json...
(
echo {
echo   "name": "LiteCode Editor",
echo   "short_name": "LiteCode", 
echo   "description": "Hybrid Code Editor",
echo   "start_url": ".",
echo   "scope": ".",
echo   "display": "standalone",
echo   "orientation": "portrait",
echo   "background_color": "#0f172a",
echo   "theme_color": "#0f172a",
echo   "icons": [
echo     {
echo       "src": "icon-192.png",
echo       "sizes": "192x192",
echo       "type": "image/png"
echo     },
echo     {
echo       "src": "icon-512.png",
echo       "sizes": "512x512", 
echo       "type": "image/png"
echo     }
echo   ]
echo }
) > manifest.json

echo [2/6] Checking icon files...
if exist "icon.png" (
  echo Found icon.png, creating PWA icons...
  
  REM Buat icon-512.png
  copy "icon.png" "icon-512.png" >nul
  echo ✅ Created icon-512.png
  
  REM Buat icon-192.png dari icon-512.png
  powershell -Command "& {
      Add-Type -AssemblyName System.Drawing
      try {
          \$img = [System.Drawing.Image]::FromFile('icon-512.png')
          \$bmp = New-Object System.Drawing.Bitmap(192, 192)
          \$g = [System.Drawing.Graphics]::FromImage(\$bmp)
          \$g.DrawImage(\$img, 0, 0, 192, 192)
          \$bmp.Save('icon-192.png', [System.Drawing.Imaging.ImageFormat]::Png)
          \$g.Dispose()
          \$bmp.Dispose()
          \$img.Dispose()
          Write-Host '✅ Created icon-192.png (192x192)'
      } catch {
          Write-Host '❌ Error creating icon-192.png'
          Write-Host \$_.Exception.Message
      }
  }"
) else (
  echo ❌ icon.png not found! Creating default icons...
  call :CREATE_DEFAULT_ICONS
)

echo [3/6] Creating service-worker.js...
(
echo // Simple Service Worker
echo const CACHE_NAME = 'litecode-v1';
echo 
echo self.addEventListener('install', function(event) {
echo   event.waitUntil(
echo     caches.open(CACHE_NAME).then(function(cache) {
echo       return cache.addAll([
echo         './',
echo         './index.html',
echo         './manifest.json',
echo         './icon-192.png',
echo         './icon-512.png'
echo       ]);
echo     })
echo   );
echo });
echo 
echo self.addEventListener('fetch', function(event) {
echo   event.respondWith(
echo     caches.match(event.request).then(function(response) {
echo       return response || fetch(event.request);
echo     })
echo   );
echo });
) > service-worker.js

echo [4/6] Updating index.html for PWA...
powershell -Command "& {
    \$file = 'index.html'
    if (Test-Path \$file) {
        \$content = Get-Content \$file -Raw
        
        # Hapus semua manifest dan icon links yang ada
        \$content = \$content -replace '<link[^>]*manifest[^>]*>', ''
        \$content = \$content -replace '<link[^>]*icon-192[^>]*>', ''
        \$content = \$content -replace '<link[^>]*icon-512[^>]*>', ''
        \$content = \$content -replace '<meta[^>]*theme-color[^>]*>', ''
        
        # Tambahkan PWA tags sebelum </head>
        \$pwaTags = @'
<!-- PWA Configuration -->
<meta name=\"theme-color\" content=\"#0f172a\">
<link rel=\"manifest\" href=\"manifest.json\">
<link rel=\"icon\" type=\"image/png\" href=\"icon-192.png\">
<link rel=\"apple-touch-icon\" href=\"icon-192.png\">
'@
        
        \$content = \$content -replace '</head>', \"\$pwaTags</head>\"
        
        # Tambahkan service worker registration sebelum </body>
        \$swScript = @'
<!-- Service Worker Registration -->
<script>
if ('serviceWorker' in navigator) {
  window.addEventListener('load', function() {
    navigator.serviceWorker.register('service-worker.js')
      .then(function(reg) {
        console.log('Service Worker registered: ', reg.scope);
      }).catch(function(err) {
        console.log('Service Worker registration failed: ', err);
      });
  });
}

// Check if running as PWA
if (window.matchMedia('(display-mode: standalone)').matches) {
  console.log('Running as PWA');
  document.documentElement.classList.add('pwa-mode');
}
</script>
'@
        
        \$content = \$content -replace '</body>', \"\$swScript</body>\"
        
        Set-Content \$file \$content -Encoding UTF8
        Write-Host '✅ index.html updated for PWA'
    } else {
        Write-Host '❌ index.html not found!'
    }
}"

echo [5/6] Creating test files...
echo Testing PWA configuration...
echo.
echo Folder structure:
dir *.html *.json *.js *.png

echo [6/6] Starting test server...
echo.
echo ════════════════════════════════════════════════════
echo 🔗 OPEN THIS URL: http://localhost:8080
echo ════════════════════════════════════════════════════
echo.
echo 1. Buka Chrome/Edge
echo 2. Kunjungi: http://localhost:8080
echo 3. F12 → Application → Manifest (harus hijau)
echo 4. F12 → Application → Service Workers
echo 5. Look for "Add to Home Screen" prompt
echo.
echo Press Ctrl+C to stop server
echo.
python -m http.server 8080

goto :EOF

:CREATE_DEFAULT_ICONS
echo Creating default icons...
powershell -Command "& {
    Add-Type -AssemblyName System.Drawing
    
    # Buat icon-512.png
    \$bmp = New-Object System.Drawing.Bitmap(512, 512)
    \$g = [System.Drawing.Graphics]::FromImage(\$bmp)
    \$g.Clear([System.Drawing.Color]::FromArgb(15, 23, 42))
    
    \$font = New-Object System.Drawing.Font('Arial', 180, [System.Drawing.FontStyle]::Bold)
    \$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    \$g.DrawString('LC', \$font, \$brush, 130, 150)
    
    \$bmp.Save('icon-512.png', [System.Drawing.Imaging.ImageFormat]::Png)
    \$g.Dispose()
    \$bmp.Dispose()
    Write-Host '✅ Created default icon-512.png'
    
    # Buat icon-192.png
    \$img = [System.Drawing.Image]::FromFile('icon-512.png')
    \$bmp192 = New-Object System.Drawing.Bitmap(192, 192)
    \$g192 = [System.Drawing.Graphics]::FromImage(\$bmp192)
    \$g192.DrawImage(\$img, 0, 0, 192, 192)
    \$bmp192.Save('icon-192.png', [System.Drawing.Imaging.ImageFormat]::Png)
    
    \$g192.Dispose()
    \$bmp192.Dispose()
    \$img.Dispose()
    Write-Host '✅ Created default icon-192.png'
}"
exit /b