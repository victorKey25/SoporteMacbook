#!/bin/bash

# Archivo de reporte HTML
HTML_REPORT="$HOME/diagnostico_mac_report.html"

# Crear el archivo y encabezado HTML
cat > "$HTML_REPORT" << EOF
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8" />
<title>Diagnóstico Mac</title>
<style>
  body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
  h1, h2 { color: #333; }
  .card { background: white; padding: 15px; margin-bottom: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
  pre { white-space: pre-wrap; word-wrap: break-word; font-size: 14px; }
</style>
</head>
<body>
<h1>Reporte de diagnóstico Mac</h1>
EOF

# Versión de macOS
echo '<div class="card"><h2>🖥️ Versión macOS</h2>' >> "$HTML_REPORT"
sw_vers >> "$HTML_REPORT"
echo '</div>' >> "$HTML_REPORT"

# Últimos errores del sistema (últimas 100 líneas)
echo '<div class="card"><h2>⚠️ Últimos errores del sistema</h2><pre>' >> "$HTML_REPORT"
log show --style syslog --predicate 'eventType == logEvent' --last 1d | grep -i "error" | tail -n 100 >> "$HTML_REPORT"
echo '</pre></div>' >> "$HTML_REPORT"

# Kernel extensions no nativas Apple
echo '<div class="card"><h2>🔧 Extensiones del kernel no nativas Apple</h2><pre>' >> "$HTML_REPORT"
kmutil showloaded --list-only --variant=release | grep -v com.apple. || echo "No se encontraron extensiones no nativas."
echo '</pre></div>' >> "$HTML_REPORT"

# Verificación básica malware con Malwarebytes (si está instalado)
echo '<div class="card"><h2>🛡️ Verificación básica de malware</h2><pre>' >> "$HTML_REPORT"
if command -v mbar >/dev/null 2>&1; then
    mbar --scan >> "$HTML_REPORT" 2>&1
else
    echo "Malwarebytes no está instalado." >> "$HTML_REPORT"
fi
echo '</pre></div>' >> "$HTML_REPORT"

# Dispositivos Bluetooth conectados
echo '<div class="card"><h2>🔵 Dispositivos Bluetooth conectados</h2><pre>' >> "$HTML_REPORT"
system_profiler SPBluetoothDataType | grep "Connected: Yes" -B 5 >> "$HTML_REPORT"
echo '</pre></div>' >> "$HTML_REPORT"

# Dispositivos USB conectados
echo '<div class="card"><h2>🔌 Dispositivos USB conectados</h2><pre>' >> "$HTML_REPORT"
system_profiler SPUSBDataType >> "$HTML_REPORT"
echo '</pre></div>' >> "$HTML_REPORT"

# Aplicaciones instaladas (con versión y última vez usadas)
INSTALLED_APPS_FILE=$(mktemp)
mdfind "kMDItemKind == 'Application'" | while read -r app; do
    name=$(basename "$app")
    last_open=$(mdls -name kMDItemLastUsedDate "$app" 2>/dev/null | awk -F'= ' '{print $2}')
    version=$(defaults read "${app}/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "Desconocida")
    echo "$name - Versión: $version - Último uso: $last_open"
done > "$INSTALLED_APPS_FILE"

cat >> "$HTML_REPORT" << EOH
<div class="card">
  <h2>📦 Aplicaciones Instaladas</h2>
  <pre>
EOH

cat "$INSTALLED_APPS_FILE" >> "$HTML_REPORT"

cat >> "$HTML_REPORT" << EOH
  </pre>
</div>
EOH

rm "$INSTALLED_APPS_FILE"

# Cerrar el HTML
echo "</body></html>" >> "$HTML_REPORT"

# Abrir el reporte automáticamente
open "$HTML_REPORT"
