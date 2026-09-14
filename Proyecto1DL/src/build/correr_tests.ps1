# ============================================================================
# Corre todos los testbenches del proyecto SIN necesidad de make.
# EL-3307 Diseno Logico - Proyecto corto I
#
# Uso, desde PowerShell:
#     cd Proyecto1DL\src\build
#     .\correr_tests.ps1
#
# Si Windows se queja de que los scripts estan bloqueados, corra una sola vez:
#     Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
# Este script existe como respaldo: lo normal es usar "make test-all". Sirve
# cuando el make del oss-cad-suite no encuentra un shell en Windows.
# ============================================================================

Set-Location $PSScriptRoot

# --- Revisar que los archivos esten donde deben ---------------------------
$faltantes = @()
foreach ($f in @("..\design\top_hamming.sv",
                 "..\design\module_corrector.sv",
                 "..\design\module_display_7seg.sv",
                 "..\design\module_generador_error.sv",
                 "..\design\module_bin_a_7seg.sv",
                 "..\sim\module_hamming74_estructural.sv",
                 "..\sim\modelo_hamming_verificacion.sv",
                 "..\sim\modelo_receptor_fisico.sv",
                 "..\constr\proyecto.cst")) {
    if (-not (Test-Path $f)) { $faltantes += $f }
}
if ($faltantes.Count -gt 0) {
    Write-Host "Faltan archivos del proyecto:" -ForegroundColor Red
    $faltantes | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
    Write-Host "Revise que haya copiado el .zip completo respetando las carpetas." -ForegroundColor Red
    exit 1
}

# --- Revisar que iverilog este en el PATH ---------------------------------
if (-not (Get-Command iverilog -ErrorAction SilentlyContinue)) {
    Write-Host "No se encuentra 'iverilog' en el PATH." -ForegroundColor Red
    Write-Host "Abra la terminal del oss-cad-suite (start.bat) o cargue su environment." -ForegroundColor Red
    exit 1
}

# --- Listas de archivos ----------------------------------------------------
# PowerShell no expande comodines para programas externos, asi que la lista
# de fuentes se arma aqui y se pasa archivo por archivo.
$disenio = Get-ChildItem "..\design\*.sv" | ForEach-Object { $_.FullName }
$modelos = @("..\sim\module_hamming74_estructural.sv",
             "..\sim\modelo_hamming_verificacion.sv",
             "..\sim\modelo_receptor_fisico.sv") |
           ForEach-Object { (Resolve-Path $_).Path }

$testbenches = @("tb_bin_a_7seg",
                 "tb_generador_error",
                 "tb_corrector",
                 "tb_hamming74_estructural",
                 "tb_modelo_hamming_verificacion",
                 "tb_sistema_completo")

# --- Correr uno por uno ----------------------------------------------------
$conProblema = @()

foreach ($tb in $testbenches) {
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host " $tb" -ForegroundColor Cyan
    Write-Host "==================================================================" -ForegroundColor Cyan

    $archivoTb = (Resolve-Path "..\sim\$tb.sv").Path

    & iverilog -g2005-sv -o "$tb.o" -s $tb $archivoTb @disenio @modelos
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR al compilar $tb" -ForegroundColor Red
        $conProblema += $tb
        continue
    }

    & vvp "$tb.o"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR al correr $tb" -ForegroundColor Red
        $conProblema += $tb
    }
}

# --- Resumen ---------------------------------------------------------------
Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
if ($conProblema.Count -eq 0) {
    Write-Host "Los $($testbenches.Count) testbenches corrieron sin errores de herramienta." -ForegroundColor Green
    Write-Host "Revise arriba que cada uno diga 'TODAS LAS PRUEBAS PASARON'." -ForegroundColor Green
} else {
    Write-Host "Hubo problemas en: $($conProblema -join ', ')" -ForegroundColor Red
    exit 1
}
