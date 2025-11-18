<#
.SYNOPSIS
    Dead by daylight ASIA Region Locker by Hanz Jamal
    Features: Platform Selector, Auto-Fetch AWS IP, Double Lock Firewall, Anti-Error 2 logic, Clean UI/UX.
#>

# --- SETUP AWAL ---
Add-Type -AssemblyName System.Windows.Forms
$AwsUrl  = "https://ip-ranges.amazonaws.com/ip-ranges.json"
$Global:ExePath = "" 

# --- DATA REGION ---
$RegionList = @{
    1 = @{ Code="ap-east-1";      Name="Hongkong (China)" }
    2 = @{ Code="ap-northeast-1"; Name="Tokyo (Jepang)" }
    3 = @{ Code="ap-northeast-2"; Name="Seoul (Korea)" }
    4 = @{ Code="ap-northeast-3"; Name="Osaka (Jepang)" }
    5 = @{ Code="ap-south-1";     Name="Mumbai (India)" }
    6 = @{ Code="ap-south-2";     Name="Hyderabad (India)" }
    7 = @{ Code="ap-southeast-2"; Name="Sydney (Australia)" }
    8 = @{ Code="ap-southeast-4"; Name="Melbourne (Australia)" }
    9 = @{ Code="ap-southeast-1"; Name="Singapore (MAIN SERVER - HATI-HATI)" }
}

# --- FUNGSI: CEK ADMIN ---
function Check-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "ERROR: Script ini butuh akses Administrator!" -ForegroundColor Red
        Start-Sleep 3
        exit
    }
}

# --- FUNGSI: PILIH LOKASI GAME ---
function Select-GameLocation {
    Clear-Host
    Write-Host "=======================================================" -ForegroundColor Magenta
    Write-Host "    Dead by daylight ASIA Region Locker by Hanz Jamal  " -ForegroundColor Yellow
    Write-Host "=======================================================" -ForegroundColor Magenta
    Write-Host "`nKONFIGURASI LOKASI GAME:"
    Write-Host "[1] Xbox App (Default C:)" -ForegroundColor Cyan
    Write-Host "    -> C:\XboxGames\Dead By Daylight\..."
    Write-Host "[2] Custom / Steam / Epic / Drive Lain" -ForegroundColor Cyan
    Write-Host "    -> Pilih manual file .exe shipping gamenya"
    
    $pilih = Read-Host "`nPilih Platform [1/2]"
    
    if ($pilih -eq "1") {
        $DefaultPath = "C:\XboxGames\Dead By Daylight\Content\DeadByDaylight\Binaries\WinGDK\DeadByDaylight-WinGDK-Shipping.exe"
        if (Test-Path $DefaultPath) {
            $Global:ExePath = $DefaultPath
            Write-Host "-> Game ditemukan." -ForegroundColor Green
            Start-Sleep 1
        } else {
            Write-Host "X File tidak ditemukan. Mode manual..." -ForegroundColor Red
            Start-Sleep 1
            Browse-File
        }
    } else {
        Browse-File
    }
}

# --- FUNGSI: BROWSE FILE ---
function Browse-File {
    Write-Host "`n[..] Membuka jendela pencarian file..." -ForegroundColor Cyan
    Start-Sleep -Milliseconds 500
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
    $FileBrowser.Title = "PILIH FILE: DeadByDaylight-Win64-Shipping.exe / WinGDK"
    $FileBrowser.Filter = "DbD Shipping (*.exe)|*.exe"
    $FileBrowser.InitialDirectory = "C:\"

    if ($FileBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $Global:ExePath = $FileBrowser.FileName
        Write-Host "-> Target: $Global:ExePath" -ForegroundColor Green
        Start-Sleep 1
    } else {
        Write-Host "X Dibatalkan." -ForegroundColor Red
        exit
    }
}

# --- FUNGSI: DOWNLOAD IP ---
function Get-AwsIPs ($SelectedCodes) {
    Write-Host "   [..] Download database IP AWS..." -ForegroundColor Cyan
    try {
        $JsonData = Invoke-RestMethod -Uri $AwsUrl
        $IPv4 = $JsonData.prefixes | Where-Object { $SelectedCodes -contains $_.region } | Select-Object -ExpandProperty ip_prefix
        $IPv6 = $JsonData.ipv6_prefixes | Where-Object { $SelectedCodes -contains $_.region } | Select-Object -ExpandProperty ipv6_prefix
        return $IPv4 + $IPv6
    } catch {
        Write-Error "Gagal download data AWS."
        return $null
    }
}

# --- FUNGSI: PASANG FIREWALL ---
function Install-Rules ($IPList) {
    $RuleNameOut = "Block DbD Custom (OUTBOUND)"
    $RuleNameIn  = "Block DbD Custom (INBOUND)"
    
    Write-Host "   [..] Membersihkan rule lama..." -ForegroundColor DarkGray
    Remove-NetFirewallRule -DisplayName $RuleNameOut -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName $RuleNameIn -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName "Block DbD: Asia Pasifik (OUTBOUND)" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName "Block DbD: Asia Pasifik (INBOUND)" -ErrorAction SilentlyContinue

    Write-Host "   [..] Mengunci Firewall (Inbound + Outbound)..." -ForegroundColor Cyan
    try {
        New-NetFirewallRule -DisplayName $RuleNameOut -Direction Outbound -Action Block -Enabled True -ErrorAction Stop | Out-Null
        New-NetFirewallRule -DisplayName $RuleNameIn -Direction Inbound -Action Block -Enabled True -ErrorAction Stop | Out-Null
        
        Set-NetFirewallRule -DisplayName $RuleNameOut -Program $Global:ExePath -ErrorAction Stop
        Set-NetFirewallRule -DisplayName $RuleNameIn -Program $Global:ExePath -ErrorAction Stop
        
        Set-NetFirewallRule -DisplayName $RuleNameOut -RemoteAddress $IPList -ErrorAction Stop
        Set-NetFirewallRule -DisplayName $RuleNameIn -RemoteAddress $IPList -ErrorAction Stop

        Write-Host "   [OK] SUKSES! Firewall Aktif." -ForegroundColor Green
        Write-Host "        Total IP Diblokir: $($IPList.Count)" -ForegroundColor Green
    } catch {
        Write-Host "   [X] GAGAL! Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# --- FUNGSI: HAPUS RULE ---
function Remove-Rules {
    Write-Host "   [..] Menghapus rule..." -ForegroundColor Cyan
    Remove-NetFirewallRule -DisplayName "Block DbD Custom (OUTBOUND)" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName "Block DbD Custom (INBOUND)" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName "Block DbD: Asia Pasifik (OUTBOUND)" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName "Block DbD: Asia Pasifik (INBOUND)" -ErrorAction SilentlyContinue
    Write-Host "   [OK] Firewall bersih. Matchmaking Normal." -ForegroundColor Green
}

# --- MAIN PROGRAM ---
Check-Admin
Select-GameLocation

while ($true) {
    Clear-Host
    Write-Host "=======================================================" -ForegroundColor Magenta
    Write-Host "         LOCKER MENU - HANZ JAMAL NETWORK              " -ForegroundColor Yellow
    Write-Host "=======================================================" -ForegroundColor Magenta
    Write-Host "Target: ...\$(Split-Path $Global:ExePath -Leaf)" -ForegroundColor DarkGray
    Write-Host "-------------------------------------------------------"
    Write-Host "1. MODE PARANOID (Blokir Asia KECUALI Singapore)" -ForegroundColor Green
    Write-Host "2. Mode Custom (Bisa Blokir Singapore juga)" -ForegroundColor Yellow
    Write-Host "3. HAPUS / UNINSTALL RULE (Normal Mode)" -ForegroundColor Cyan
    Write-Host "4. Ganti Target File Game" -ForegroundColor White
    Write-Host "5. Keluar" -ForegroundColor Red
    
    $choice = Read-Host "`nPilih Menu [1-5]"

    switch ($choice) {
        "1" { 
            Clear-Host # BERSIHKAN LAYAR
            Write-Host "--- MENJALANKAN MODE PARANOID (SAFE SG) ---`n" -ForegroundColor Green
            $Codes = $RegionList.Values | Where-Object { $_.Code -ne "ap-southeast-1" } | ForEach-Object { $_.Code }
            $IPs = Get-AwsIPs $Codes
            if ($IPs) { Install-Rules $IPs }
            Read-Host "`nTekan Enter untuk kembali ke menu..."
        }
        "2" {
            Clear-Host # BERSIHKAN LAYAR
            Write-Host "--- SETUP CUSTOM REGION (FULL CONTROL) ---`n" -ForegroundColor Yellow
            Write-Host "Daftar Region:"
            1..9 | ForEach-Object { Write-Host "  $_ . $($RegionList[$_].Name)" }
            Write-Host "`n[!] Info: Pilih nomor 9 jika ingin memblokir Singapore." -ForegroundColor DarkGray
            
            $input = Read-Host "`nMasukkan angka region yg mau DIBLOKIR (pisahkan koma, cth: 1,2,9)"
            $selections = $input -split ","
            $Codes = @()
            foreach ($s in $selections) {
                if ($RegionList[$s.Trim()]) { $Codes += $RegionList[$s.Trim()].Code }
            }
            
            Write-Host ""
            if ($Codes.Count -gt 0) {
                $IPs = Get-AwsIPs $Codes
                if ($IPs) { Install-Rules $IPs }
            } else {
                Write-Host "Pilihan tidak valid / Kosong." -ForegroundColor Red
            }
            Read-Host "`nTekan Enter untuk kembali ke menu..."
        }
        "3" { 
            Clear-Host # BERSIHKAN LAYAR
            Write-Host "--- MENGHAPUS ATURAN ---`n" -ForegroundColor Cyan
            Remove-Rules 
            Read-Host "`nTekan Enter untuk kembali ke menu..."
        }
        "4" { Select-GameLocation }
        "5" { exit }
        default { Start-Sleep 1 }
    }
}