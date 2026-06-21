$ErrorActionPreference = "Stop"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   MUNINN IHA - OTO-BASLATICI v1.0" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# 1. Aktif COM Portlarını Bul
Write-Host "1. Telemetri portu araniyor..." -ForegroundColor Yellow
$comPort = ""
$ports = Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -match "\(COM\d+\)" }

if ($null -eq $ports -or $ports.Count -eq 0) {
    Write-Host "[X] HATA: Bilgisayara bagli hicbir COM port bulunamadi!" -ForegroundColor Red
    Write-Host "    Lutfen telemetri modulunu bilgisayara takin ve tekrar deneyin." -ForegroundColor Red
    Read-Host "Cikmak icin ENTER'a basin..."
    exit
}

# Eğer sadece 1 port varsa otomatik seç, birden fazlaysa kullanıcıya sor
if ($ports.Count -eq 1 -or $ports.GetType().Name -eq "ManagementObject") {
    # Bazen tek obje dönünce array olmaz
    $portObj = if ($ports.Count -eq 1) { $ports[0] } else { $ports }
    $comPort = [regex]::match($portObj.Name, 'COM\d+').Value
    Write-Host "[V] Otomatik Baglanti Kuruldu: $($portObj.Name) ($comPort)" -ForegroundColor Green
} else {
    Write-Host "[!] Birden fazla cihaz bulundu. Lutfen Telemetri cihazini secin:" -ForegroundColor Yellow
    for ($i=0; $i -lt $ports.Count; $i++) {
        Write-Host "    [$i] $($ports[$i].Name)"
    }
    
    $validChoice = $false
    while (-not $validChoice) {
        $choice = Read-Host "Seciminiz (0 - $($ports.Count - 1))"
        if ([int]::TryParse($choice, [ref]$null) -and $choice -ge 0 -and $choice -lt $ports.Count) {
            $validChoice = $true
            $selected = $ports[[int]$choice]
            $comPort = [regex]::match($selected.Name, 'COM\d+').Value
            Write-Host "[V] Secilen Port: $($selected.Name) ($comPort)" -ForegroundColor Green
        } else {
            Write-Host "Gecersiz secim, lutfen gecerli bir numara girin." -ForegroundColor Red
        }
    }
}

Write-Host ""

# 1.5 Hedef IP Adresini Belirle
$configPath = Join-Path $PSScriptRoot "muninn_ip.txt"
$remoteIp = ""

if (Test-Path $configPath) {
    $savedIp = Get-Content $configPath
    $useSaved = Read-Host "Kayitli Uzak Baglanti IP'si bulundu ($savedIp). Kullanilsin mi? (E/H)"
    if ($useSaved -match "^[eE]") {
        $remoteIp = $savedIp
    }
}

if ($remoteIp -eq "") {
    $remoteIp = Read-Host "Lutfen uzaktaki cihazin (GCS/Telefon) IP adresini girin (Orn: 100.82.70.52)"
    $remoteIp | Out-File -FilePath $configPath -Encoding UTF8
    Write-Host "[V] Yeni IP adresi kaydedildi: $remoteIp" -ForegroundColor Green
}

Write-Host ""

# 2. MAVProxy'i Ayrı Bir Pencerede Başlat
Write-Host "2. MAVProxy Baslatiliyor ($comPort) ..." -ForegroundColor Yellow
# Sabit olan portlar: 127.0.0.1:14550 ve udpin:0.0.0.0:14540
# Degisebilen (Elle girilen) IP ve port eklentisi:

$remoteIpArg = ""
if ($remoteIp -ne "") {
    $remoteIpArg = "--out=udp:${remoteIp}:14551"
}

$mavproxyCmd = "mavproxy.exe --master=$comPort --baudrate=57600 --out=udp:127.0.0.1:14550 $remoteIpArg --out=udpin:0.0.0.0:14540"
Start-Process "cmd.exe" -ArgumentList "/c title MAVProxy Terminal & color 0A & echo Running: $mavproxyCmd & echo. & $mavproxyCmd & pause" -WindowStyle Normal
Write-Host "[V] MAVProxy arka planda acildi." -ForegroundColor Green

Write-Host ""

# 3. Video Sender'ı Ayrı Bir Pencerede Başlat
Write-Host "3. Odin Video Sender Baslatiliyor..." -ForegroundColor Yellow

# Script klasör yolunu dinamik alıyoruz ki masaüstüne falan taşıdığında yol sorunu olmasın
$videoPath = Join-Path $PSScriptRoot "odin_video_sender.py"
if (-not (Test-Path $videoPath)) {
    $videoPath = Join-Path $PSScriptRoot "scripts\odin_video_sender.py"
}

$videoCmd = "python ""$videoPath"""
Start-Process "cmd.exe" -ArgumentList "/c title Video Sender Terminal & color 0B & echo Running: python odin_video_sender.py & echo. & $videoCmd & pause" -WindowStyle Normal
Write-Host "[V] Video Sender arka planda acildi." -ForegroundColor Green

Write-Host ""

# 4. QGroundControl'u Başlat
Write-Host "4. QGroundControl Aranip Baslatiliyor..." -ForegroundColor Yellow

# Windows Başlat/Arama çubuğu mantığıyla kısayol arıyoruz:
$shortcutPaths = @(
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
)

$qgcShortcut = Get-ChildItem -Path $shortcutPaths -Recurse -Filter "QGroundControl.lnk" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($qgcShortcut) {
    Write-Host "[V] QGroundControl Arama Cubugunda Bulundu!" -ForegroundColor Green
    Start-Process $qgcShortcut.FullName
} else {
    Write-Host "[!] QGroundControl arama kisminda bulunamadi. Manuel acmaniz gerekebilir." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " TUM SISTEMLER BASARIYLA ATESLENDI!" -ForegroundColor Green
Write-Host " Pencereleri gorebilirsiniz. Iyi ucuslar!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan

Start-Sleep -Seconds 5
