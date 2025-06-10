#!/bin/bash

VERSION="1.1.2"
REPORT_DIR="$HOME/Desktop/MacDiagnostic"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
HTML_REPORT="$REPORT_DIR/diagnostico_mac_$DATE_v$VERSION.html"

mkdir -p "$REPORT_DIR"

# Inicia el HTML
cat > "$HTML_REPORT" << EOH
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Diagnóstico MacBook - v$VERSION</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f9f9f9; }
        h1 { color: #4A90E2; }
        .section { margin-bottom: 30px; }
        .card { background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px; border-bottom: 1px solid #ddd; text-align: left; }
        th { background: #f0f0f0; }
    </style>
</head>
<body>
    <h1>🧠 Diagnóstico MacBook - v$VERSION</h1>
    <p>Fecha: $DATE</p>
EOH

# 🔧 Versión de macOS y Hardware
echo '<div class="card"><h2>🖥️ Información del sistema</h2><pre>' >> "$HTML_REPORT"
system_profiler SPSoftwareDataType SPHardwareDataType >> "$HTML_REPORT"
echo '</pre></div>' >> "$HTML_REPORT"

# 📧 Cuenta de Apple
APPLE_ID=$(defaults read MobileMeAccounts | grep AccountID | head -n 1 | cut -d '"' -f2)
echo '<div class="card"><h2>📧 Cuenta Apple registrada</h2>' >> "$HTML_REPORT"
if [ -n "$APPLE_ID" ]; then
    echo "<p>Cuenta: <strong>$APPLE_ID</strong></p>" >> "$HTML_REPORT"
else
    echo "<p>No se detectó cuenta Apple registrada en esta sesión.</p>" >> "$HTML_REPORT"
fi
echo '</div>' >> "$HTML_REPORT"

# 🧬 Extensiones no nativas
echo '<div class="card"><h2>🧩 Extensiones del sistema no nativas</h2><pre>' >> "$HTML_REPORT"
kextstat | grep -v com.apple >> "$HTML_REPORT"
echo '</pre></div>' >> "$HTML_REPORT"

# 🐞 Últimos errores del sistema
echo '<div class="card"><h2>⚠️ Últimos errores en el sistema (last 50)</h2><pre>' >> "$HTML_REPORT"
log show --predicate 'eventType == "fault"' --last 1d | tail -n 50 >> "$HTML_REPORT"
echo '</pre></div>' >> "$HTML_REPORT"

# 🔐 Verificación básica de malware
echo '<div class="card"><h2>🛡️ Verificación básica de malware (binarios en LaunchAgents/Daemons)</h2><pre>' >> "$HTML_REPORT"
find ~/Library/LaunchAgents /Library/LaunchAgents /Library/LaunchDaemons -name '*.plist' -exec grep -H Exec {} \; 2>/dev/null | grep -v com.apple >> "$HTML_REPORT"
echo '</pre></div>' >> "$HTML_REPORT"

# 🔗 Dispositivos USB y Bluetooth
echo '<div class="card"><h2>🔌 Dispositivos conectados (USB y Bluetooth)</h2><pre>' >> "$HTML_REPORT"
system_profiler SPUSBDataType SPBluetoothDataType >> "$HTML_REPORT"
echo '</pre></div>' >> "$HTML_REPORT"

# 💡 Recomendaciones
cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>💡 Recomendaciones</h2>
        <ul>
            <li>Actualiza siempre macOS a la última versión disponible.</li>
            <li>Haz copias de seguridad frecuentes con Time Machine o similar.</li>
            <li>Evita instalar software de fuentes no confiables.</li>
            <li>Monitorea el uso de la batería y reemplázala si el ciclo está alto o su estado es deficiente.</li>
            <li>Ejecuta análisis antivirus con herramientas confiables regularmente.</li>
            <li>Consulta soporte oficial si detectas procesos o extensiones sospechosas.</li>
        </ul>
    </div>
</body>
</html>
EOH

# Mostrar mensaje y abrir el reporte en navegador
echo "✅ Diagnóstico generado: $HTML_REPORT"
open "$HTML_REPORT"
