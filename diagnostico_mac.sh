#!/bin/bash

# Variables para reporte
HTML_REPORT="$HOME/diagnostico_mac_report.html"

# Función para encabezado del reporte
print_header() {
  cat <<EOF > "$HTML_REPORT"
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Reporte de Diagnóstico Mac</title>
<style>
  body { font-family: Arial, sans-serif; }
  h1 { color: #2c3e50; }
  pre { background-color: #ecf0f1; padding: 10px; border-radius: 5px; }
</style>
</head>
<body>
<h1>Reporte de Diagnóstico Mac</h1>
EOF
}

# Función para pie de página
print_footer() {
  echo "</body></html>" >> "$HTML_REPORT"
}

# Función para imprimir sección con título
print_section() {
  local title="$1"
  local content="$2"
  echo "<h2>$title</h2>" >> "$HTML_REPORT"
  echo "<pre>$content</pre>" >> "$HTML_REPORT"
}

# Limpieza reporte previo
rm -f "$HTML_REPORT"

print_header

echo "Homebrew ya está instalado." | tee -a "$HTML_REPORT"

# Ejecutar kmutil para extensiones del kernel
kmutil_output=$( /usr/bin/kmutil showloaded 2>&1 )
print_section "Extensiones del kernel cargadas (kmutil showloaded)" "$kmutil_output"

# Estado de batería/energía
battery_output=$( pmset -g batt 2>&1 )
print_section "Estado de batería / energía" "$battery_output"

# Verificación de malware básico con malwaretool (macOS Monterey+)
if command -v malwaretool >/dev/null 2>&1; then
  malware_output=$(malwaretool --scan 2>&1)
else
  malware_output="Herramienta malwaretool no disponible."
fi
print_section "Verificación básica de malware" "$malware_output"

# Revisar errores recientes del sistema (últimas 50 líneas de log de sistema)
system_errors=$(log show --style syslog --last 1h --predicate 'eventType == logEvent and (senderImagePath contains "kernel" or senderImagePath contains "system")' 2>&1 | tail -50)
print_section "Errores recientes del sistema (última hora)" "$system_errors"

# Dispositivos Bluetooth conectados
bluetooth_output=$( system_profiler SPBluetoothDataType | grep "Connected: Yes" -A 10 )
print_section "Dispositivos Bluetooth conectados" "$bluetooth_output"

# Dispositivos USB conectados
usb_output=$( system_profiler SPUSBDataType )
print_section "Dispositivos USB conectados" "$usb_output"

# Información de la cuenta Apple
apple_account=$( defaults read MobileMeAccounts Accounts 2>/dev/null )
if [ -z "$apple_account" ]; then
  apple_account="No se encontró información de la cuenta Apple."
fi
print_section "Información de la cuenta Apple" "$apple_account"

# Recomendaciones simples (puedes ajustar según lo que quieras)
recomendaciones="\
- Verifica actualizaciones del sistema.\n\
- Asegúrate que las extensiones del kernel sean confiables.\n\
- Mantén activada la protección contra malware.\n\
- Revisa dispositivos externos conectados.\n\
- Si hay errores frecuentes, considera reiniciar o consultar soporte."

print_section "Recomendaciones" "$recomendaciones"

print_footer

# Abrir el reporte automáticamente
open "$HTML_REPORT"
