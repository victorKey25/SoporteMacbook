#!/bin/bash

# Script de diagnóstico de sistema para macOS
# Genera un informe HTML con información clave del sistema

# Variables
HTML_REPORT="$HOME/Escritorio/reporte_diagnostico_mac.html"
FECHA=$(date)
HOSTNAME=$(scutil --get ComputerName)
USUARIO=$(whoami)
SISTEMA=$(sw_vers -productVersion)
MODELO=$(sysctl -n hw.model)
PROCESADOR=$(sysctl -n machdep.cpu.brand_string)
RAM=$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024)) GB
DISCO_TOTAL=$(df -H / | tail -1 | awk '{print $2}')
DISCO_USADO=$(df -H / | tail -1 | awk '{print $3}')
DISCO_LIBRE=$(df -H / | tail -1 | awk '{print $4}')
UPTIME=$(uptime | awk -F'(up |, [0-9] users)' '{print $2}')
BLUETOOTH=$(system_profiler SPBluetoothDataType | grep "Bluetooth Power" | awk '{print $NF}')
USB=$(system_profiler SPUSBDataType | grep "Product ID" | wc -l)

# Generar el HTML
cat << EOF > "$HTML_REPORT"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Informe de Diagnóstico Mac</title>
    <style>
        body { font-family: sans-serif; margin: 20px; background: #f2f2f2; }
        h1 { color: #2c3e50; }
        h2 { color: #34495e; }
        .card {
            background: white;
            border-radius: 10px;
            padding: 15px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        table { width: 100%; border-collapse: collapse; }
        th, td { text-align: left; padding: 8px; border-bottom: 1px solid #ddd; }
    </style>
</head>
<body>
    <h1>🖥️ Informe de Diagnóstico de Mac</h1>
    <p><strong>Generado el:</strong> $FECHA</p>

    <div class="card">
        <h2>📊 Información General</h2>
        <table>
            <tr><th>Usuario:</th><td>$USUARIO</td></tr>
            <tr><th>Nombre del Equipo:</th><td>$HOSTNAME</td></tr>
            <tr><th>Modelo:</th><td>$MODELO</td></tr>
            <tr><th>macOS:</th><td>$SISTEMA</td></tr>
            <tr><th>Procesador:</th><td>$PROCESADOR</td></tr>
            <tr><th>RAM:</th><td>$RAM</td></tr>
        </table>
    </div>

    <div class="card">
        <h2>💾 Almacenamiento</h2>
        <table>
            <tr><th>Total:</th><td>$DISCO_TOTAL</td></tr>
            <tr><th>Usado:</th><td>$DISCO_USADO</td></tr>
            <tr><th>Libre:</th><td>$DISCO_LIBRE</td></tr>
        </table>
    </div>

    <div class="card">
        <h2>🔌 Periféricos</h2>
        <table>
            <tr><th>Bluetooth Activado:</th><td>$BLUETOOTH</td></tr>
            <tr><th>Dispositivos USB conectados:</th><td>$USB</td></tr>
        </table>
    </div>

    <div class="card">
        <h2>🔧 Uptime</h2>
        <p>El sistema ha estado activo durante: <strong>$UPTIME</strong></p>
    </div>
EOF

# Cuenta de Apple (iCloud)
APPLE_ID_INFO=$(defaults read MobileMeAccounts 2>/dev/null | grep AccountID | head -n 1 | awk -F'= ' '{print $2}' | tr -d '";')

cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>👤 Cuenta Apple</h2>
        <table>
            <tr><th>ID Apple:</th><td>${APPLE_ID_INFO:-No se encontró ninguna cuenta}</td></tr>
        </table>
    </div>
EOH

# Cierre del HTML
echo "</body></html>" >> "$HTML_REPORT"

# Mostrar ubicación del reporte
open "$HTML_REPORT"
echo "✅ Reporte generado exitosamente en: $HTML_REPORT"
