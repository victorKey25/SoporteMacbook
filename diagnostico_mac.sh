#!/bin/bash

# Versión 1.1
# Genera un diagnóstico básico de sistema en formato HTML para Mac
# Incluye: Hardware, Software, Aplicaciones, Extensiones, Dispositivos, Recomendaciones

REPORT_NAME="reporte_diagnostico_mac.html"
REPORT_PATH="$HOME/Desktop/$REPORT_NAME"

echo "<html><head><title>Diagnóstico Mac</title></head><body>" > "$REPORT_PATH"
echo "<h1>🧠 Diagnóstico de MacBook - Versión 1.1</h1>" >> "$REPORT_PATH"

echo "<h2>🖥️ Información del sistema</h2><pre>" >> "$REPORT_PATH"
system_profiler SPHardwareDataType SPSoftwareDataType >> "$REPORT_PATH"
echo "</pre>" >> "$REPORT_PATH"

echo "<h2>📦 Aplicaciones instaladas</h2><pre>" >> "$REPORT_PATH"
system_profiler SPApplicationsDataType | grep -E "Location:|Version:|^    " >> "$REPORT_PATH"
echo "</pre>" >> "$REPORT_PATH"

echo "<h2>🧩 Extensiones de kernel no nativas</h2><pre>" >> "$REPORT_PATH"
kextstat | grep -v com.apple >> "$REPORT_PATH"
echo "</pre>" >> "$REPORT_PATH"

echo "<h2>🔌 Dispositivos USB y Bluetooth</h2><pre>" >> "$REPORT_PATH"
system_profiler SPUSBDataType SPBluetoothDataType >> "$REPORT_PATH"
echo "</pre>" >> "$REPORT_PATH"

echo "<h2>💡 Recomendaciones</h2>" >> "$REPORT_PATH"
echo "<ul>" >> "$REPORT_PATH"
echo "<li>Verifica las extensiones de kernel no nativas.</li>" >> "$REPORT_PATH"
echo "<li>Desinstala aplicaciones innecesarias.</li>" >> "$REPORT_PATH"
echo "<li>Monitorea los dispositivos conectados frecuentemente.</li>" >> "$REPORT_PATH"
echo "</ul>" >> "$REPORT_PATH"

echo "</body></html>" >> "$REPORT_PATH"

echo "✅ Diagnóstico generado: $REPORT_PATH"
