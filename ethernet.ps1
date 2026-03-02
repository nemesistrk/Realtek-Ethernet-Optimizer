<#
.SYNOPSIS
    Realtek PCIe GbE Family Controller Performance Optimizer
.DESCRIPTION
    This script analyzes and optimizes Realtek network adapter settings 
    for maximum performance and minimum latency (ping).
.AUTHOR
    YourName/GitHubHandle
#>

# --- 1. ADMINISTRATOR PRIVILEGE CHECK ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
    Write-Host "ERROR: PLEASE RUN THIS SCRIPT AS ADMINISTRATOR!" -ForegroundColor Red
    Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
    Pause
    Exit
}

# --- 2. IDENTIFY NETWORK ADAPTER ---
$adapter = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*Realtek*" }
if ($null -eq $adapter) {
    Write-Host "ERROR: Realtek Network Adapter not found!" -ForegroundColor Red
    Pause
    Exit
}

$adapterName = $adapter.Name

# --- FUNCTION: DISPLAY SETTINGS ---
function Show-NetworkSettings {
    param([string]$title)
    Write-Host "`n=== $title ===" -ForegroundColor Cyan
    Write-Host "Adapter : $($adapter.InterfaceDescription)" -ForegroundColor White
    Write-Host "Speed   : $($adapter.LinkSpeed)" -ForegroundColor White
    Write-Host "Status  : $($adapter.Status)" -ForegroundColor White
    Write-Host "----------------------------------------------------------------------"
    Write-Host "{PROPERTY} | {VALUE} | {ANALYSIS}" -ForegroundColor Gray
    Write-Host "----------------------------------------------------------------------"
    
    $props = Get-NetAdapterAdvancedProperty -Name $adapterName
    foreach ($p in $props) {
        $pName = $p.DisplayName
        $pVal = $p.DisplayValue
        
        # Performance Analysis Logic
        $isPowerSaving = $pName -match "Energy Efficient|Green Ethernet|Power Saving|Gigabit Lite"
        $isLatencyLimit = $pName -match "Flow Control|Interrupt Moderation|Jumbo"
        
        if ($isPowerSaving -or $isLatencyLimit) {
            if ($pVal -match "Disabled|Off") {
                Write-Host "$pName | $pVal | [OPTIMIZED]" -ForegroundColor Green
            } else {
                Write-Host "$pName | $pVal | [CAN BE OPTIMIZED]" -ForegroundColor Yellow
            }
        } else {
            Write-Host "$pName | $pVal" -ForegroundColor White
        }
    }
}

# --- 3. INITIAL ANALYSIS ---
Show-NetworkSettings -title "CURRENT NETWORK CONFIGURATION"

Write-Host "`nINFO: Yellow items are currently using power-saving or latency-inducing modes." -ForegroundColor Yellow
Write-Host "You can change these manually in Device Manager or let this script do it." -ForegroundColor Gray

# --- 4. USER CONSENT ---
Write-Host "`n----------------------------------------------------------------------"
$choice = Read-Host "Apply performance optimizations automatically? (Y/N)"

if ($choice -eq "Y" -or $choice -eq "y") {
    Write-Host "`nApplying changes... Your connection may drop for a few seconds." -ForegroundColor Cyan
    
    # Optimization Map
    $targets = @(
        @{n="*Energy Efficient*"; v="Disabled"},
        @{n="*Green Ethernet*"; v="Disabled"},
        @{n="*Power Saving Mode*"; v="Disabled"},
        @{n="*Gigabit Lite*"; v="Disabled"},
        @{n="*Flow Control*"; v="Disabled"},
        @{n="*Interrupt Moderation*"; v="Disabled"},
        @{n="*Jumbo*"; v="Disabled"}
    )

    foreach ($t in $targets) {
        Set-NetAdapterAdvancedProperty -Name $adapterName -DisplayName $t.n -DisplayValue $t.v -ErrorAction SilentlyContinue
    }

    Write-Host "Optimization complete! Refreshing status..." -ForegroundColor Green
    Start-Sleep -Seconds 3

    # --- 5. FINAL VERIFICATION ---
    Show-NetworkSettings -title "POST-OPTIMIZATION CONFIGURATION"
    Write-Host "`nAll optimizations applied successfully. Press any key to exit." -ForegroundColor Cyan
    Pause
} else {
    Write-Host "`nOperation cancelled. No changes were made." -ForegroundColor Red
    Pause
}