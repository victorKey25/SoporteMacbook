#!/bin/bash

# =============================
# Script de Diagnóstico Mac v1.3
# Genera un informe HTML del sistema con:
# - Hardware
# - Sistema operativo
# - Últimos errores
# - Extensiones del kernel
# - Estado de Apple ID
# - Dispositivos Bluetooth y USB
# =============================

FECHA=$(date +"%Y-%m-%d_%H-%M-%S")
HTML_REPORT="$HOME/Desktop/diagnostico_mac_$FECHA.html"

echo "Generando informe en $HTML_REPORT..."

# Comienza el HTML
cat > "$HTML_REPORT" << EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Informe Diagnóstico del Sistema Mac</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f5f5f5; padding: 20px; color: #333; }
        h1 { color: #003366; }
        h2 { color: #004488; }
        pre { background: #eee; padding: 10px; border-radius: 8px; overflow-x: auto; }
        .card { background: white; border-radius: 12px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); padding: 20px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>📋 Informe Diagnóstico del Sistema Mac</h1>
    <p>📅 Fecha: $(date)</p>
EOF

# Información del sistema
cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>🖥️ Información General</h2>
        <pre>$(system_profiler SPHardwareDataType SPSoftwareDataType)</pre>
    </div>
EOH

# Extensiones del kernel no nativas
KEXTS=$(kextstat | grep -v com.apple | awk '{print $6}' | sort | uniq)
cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>🧩 Extensiones del Kernel No Nativas</h2>
        <pre>${KEXTS:-Ninguna extensión de terceros detectada}</pre>
    </div>
EOH

# Últimos errores del sistema
cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>🚨 Últimos Errores del Sistema</h2>
        <pre>$(log show --predicate 'eventMessage contains[c] "error"' --last 1h | tail -n 30)</pre>
    </div>
EOH

# Estado de Apple ID
APPLE_ID_INFO=$(defaults read MobileMeAccounts 2>/dev/null | grep AccountID || echo "No hay sesión iniciada.")
cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>🍎 Estado de Apple ID</h2>
        <pre>${APPLE_ID_INFO}</pre>
    </div>
EOH

# Dispositivos Bluetooth
BT_DEVICES=$(system_profiler SPBluetoothDataType | grep -A 20 "Dispositivos conectados" || echo "No se pudo obtener información.")
cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>🔵 Dispositivos Bluetooth</h2>
        <pre>${BT_DEVICES}</pre>
    </div>
EOH

# Dispositivos USB
USB_INFO=$(system_profiler SPUSBDataType || echo "No se pudo obtener información.")
cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>🔌 Dispositivos USB</h2>
        <pre>${USB_INFO}</pre>
    </div>
EOH

# 💡 Recomendaciones
cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>💡 Recomendaciones</h2>
        <ul>
            <li>Si tienes extensiones del kernel no nativas de Apple, revisa su origen y necesidad.</li>
            <li>Considera usar herramientas como Malwarebytes, KnockKnock o EtreCheck para análisis más profundo.</li>
            <li>Revisa los últimos errores del sistema para ver si hay procesos fallando regularmente.</li>
            <li>Verifica que tus dispositivos Bluetooth y USB estén correctamente identificados y funcionando.</li>
            <li>Si no hay sesión activa en Apple ID, puede afectar servicios como iCloud o Mensajes.</li>
        </ul>
    </div>
EOH

# Cierre del HTML
cat >> "$HTML_REPORT" << EOF
</body>
</html>
EOF

# Abrir el reporte
open "$HTML_REPORT"

echo "✅ Informe generado exitosamente: $HTML_REPORT"
