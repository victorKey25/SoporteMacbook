#!/bin/bash

# Script de Diagnóstico para Mac con HTML
# Autor: [Tu nombre]
# Fecha: [Fecha]
# Versión: 1.0

# Variables
OUTPUT_DIR=~/Desktop
OUTPUT_FILE="$OUTPUT_DIR/reporte_diagnostico_mac.html"
HOSTNAME=$(scutil --get ComputerName)
FECHA=$(date)

# Crear archivo HTML
echo "<!DOCTYPE html>
<html lang='es'>
<head>
  <meta charset='UTF-8'>
  <title>Reporte de Diagnóstico de $HOSTNAME</title>
  <style>
    body { font-family: Arial, sans-serif; background-color: #f4f4f4; color: #333; }
    h1 { background-color: #2c3e50; color: white; padding: 10px; }
    h2 { color: #2c3e50; }
    pre { background-color: #ecf0f1; padding: 10px; overflow-x: auto; }
    .keys-telecom { text-align: center; color: white; font-size: 18px; background-color: #2c3e50; padding: 8px; margin-top: 30px; }
  </style>
</head>
<body>
<h1>Reporte de Diagnóstico - $HOSTNAME</h1>
<p><strong>Fecha de generación:</strong> $FECHA</p>
" > "$OUTPUT_FILE"

# Función para agregar secciones al HTML
add_section() {
  SECTION_TITLE=$1
  COMMAND_OUTPUT=$2
  echo "<h2>$SECTION_TITLE</h2>
<pre>$COMMAND_OUTPUT</pre>" >> "$OUTPUT_FILE"
}

# 1. Información del sistema
add_section "Información del Sistema" "$(system_profiler SPHardwareDataType)"

# 2. Espacio en disco
add_section "Uso del Disco" "$(df -h /)"

# 3. Procesos que consumen más CPU
add_section "Procesos que más consumen CPU" "$(ps -Ao %cpu,command | sort -nr | head -n 10)"

# 4. Extensiones de kernel de terceros (no de Apple)
add_section "Extensiones del Kernel (3ros)" "$(kextstat | grep -v com.apple || echo 'No se encontraron extensiones de terceros.')"

# 5. Últimos errores del sistema
add_section "Últimos errores del sistema (system.log)" "$(log show --predicate 'eventMessage contains[c] "error"' --last 1h | tail -n 50)"

# 6. Dispositivos USB conectados
add_section "Dispositivos USB conectados" "$(system_profiler SPUSBDataType)"

# 7. Dispositivos Bluetooth emparejados
add_section "Dispositivos Bluetooth" "$(system_profiler SPBluetoothDataType | grep -E 'Connected:|Device Name:' || echo 'No hay dispositivos Bluetooth conectados.')"

# 8. Verificación básica de malware (archivos sospechosos en LaunchAgents o LaunchDaemons)
add_section "Posibles Agentes Maliciosos (LaunchAgents/Daemons)" "$(find /Library/LaunchAgents /Library/LaunchDaemons ~/Library/LaunchAgents -name '*.plist' 2>/dev/null | grep -v com.apple || echo 'No se detectaron agentes sospechosos.')"

# 9. Información de red
add_section "Configuración de Red" "$(ifconfig)"

# 10. Información del sistema operativo
add_section "Versión de macOS" "$(sw_vers)"

# Información de Keys Telecom (centrado y visible)
echo "<div class='keys-telecom'>
  <strong>Keys Telecom</strong><br>
  IT Admin: Hector J. Becerra<br>
  Email: keys_telecom@proton.me<br>
  Última actualización del script: Junio 2025
</div>" >> "$OUTPUT_FILE"

# Finalizar HTML
echo "</body></html>" >> "$OUTPUT_FILE"

# Abrir el archivo automáticamente si no hubo errores
if [ -f "$OUTPUT_FILE" ]; then
  open "$OUTPUT_FILE"
  echo "✅ Diagnóstico completado exitosamente. Archivo generado: $OUTPUT_FILE"
else
  echo "❌ Error al generar el archivo de diagnóstico."
  exit 1
fi
