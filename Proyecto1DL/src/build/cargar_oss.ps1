# ============================================================================
# Carga el entorno del oss-cad-suite dentro de la sesion actual de PowerShell.
# EL-3307 Diseno Logico - Proyecto corto I
#
# Uso:
#     .\cargar_oss.ps1
#
# Despues de correrlo, en ESA misma ventana ya funcionan directo:
#     make test-all
#     make synth
#     make synth pnr bitstream
#     yosys, nextpnr-gowin, iverilog, vvp, gtkwave, openFPGALoader
#
# Sin esto, vvp falla al cargar system.vpi con el error 0xC0000135
# ("no se encontro una DLL"), porque la carpeta lib\ del oss-cad-suite no
# queda en el PATH.
#
# Si su oss-cad-suite esta en otro lado:
#     .\cargar_oss.ps1 -Raiz "C:\oss-cad-suite"
# ============================================================================

param(
    [string]$Raiz = ""
)

# --- Encontrar la raiz del oss-cad-suite ----------------------------------
if ($Raiz -eq "") {
    # Si vvp ya esta en el PATH, deducir la raiz de ahi (bin\vvp.exe -> raiz)
    $vvp = Get-Command vvp -ErrorAction SilentlyContinue
    if ($vvp) {
        $Raiz = Split-Path (Split-Path $vvp.Source -Parent) -Parent
    } else {
        # Si no, probar las ubicaciones tipicas
        foreach ($tentativa in @("$env:USERPROFILE\Downloads\oss-cad-suite",
                                 "C:\oss-cad-suite",
                                 "$env:USERPROFILE\oss-cad-suite",
                                 "C:\tools\oss-cad-suite")) {
            if (Test-Path "$tentativa\environment.bat") { $Raiz = $tentativa; break }
        }
    }
}

if ($Raiz -eq "" -or -not (Test-Path "$Raiz\environment.bat")) {
    Write-Host "No encuentro el oss-cad-suite." -ForegroundColor Red
    Write-Host "Pase la ruta a mano, por ejemplo:" -ForegroundColor Red
    Write-Host '   .\cargar_oss.ps1 -Raiz "C:\Users\ariet\Downloads\oss-cad-suite"' -ForegroundColor Yellow
    exit 1
}

Write-Host "Cargando oss-cad-suite desde: $Raiz" -ForegroundColor DarkGray

# --- Correr environment.bat y traerse las variables que deja --------------
# El truco: se ejecuta el .bat en un cmd, se le pide "set" para que liste
# todas las variables ya configuradas, y se copian a esta sesion.
$antes = @{}
Get-ChildItem Env: | ForEach-Object { $antes[$_.Name] = $_.Value }

$salida = cmd /c "`"$Raiz\environment.bat`" >nul 2>&1 && set"

if (-not $salida) {
    Write-Host "environment.bat no devolvio nada. Revise la ruta." -ForegroundColor Red
    exit 1
}

$cambiadas = 0
foreach ($linea in $salida) {
    if ($linea -match '^([^=]+)=(.*)$') {
        $nombre = $matches[1]
        $valor  = $matches[2]
        if ($antes[$nombre] -ne $valor) {
            Set-Item -Path "Env:\$nombre" -Value $valor
            $cambiadas++
        }
    }
}

# --- Comprobar que quedo bien ---------------------------------------------
$faltan = @()
foreach ($herramienta in @("iverilog","vvp","yosys","nextpnr-gowin","openFPGALoader")) {
    if (-not (Get-Command $herramienta -ErrorAction SilentlyContinue)) { $faltan += $herramienta }
}

Write-Host ""
Write-Host "oss-cad-suite cargado ($cambiadas variables de entorno)." -ForegroundColor Green
if ($faltan.Count -gt 0) {
    Write-Host "Ojo, no aparecen en el PATH: $($faltan -join ', ')" -ForegroundColor Yellow
}
Write-Host "Ya puede correr 'make test-all' o 'make synth' en esta ventana." -ForegroundColor Green
